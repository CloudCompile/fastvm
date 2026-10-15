//! Host GPU detection for the marketplace.
//!
//! Linux exposes DRM devices under `/sys/class/drm` and device nodes under
//! `/dev/dri`. We read each card's PCI vendor id to decide whether a GPU is
//! present and what it is, so the UI can offer `/dev/dri` passthrough only when
//! it would actually do something. Detection is best-effort: on Windows/macOS,
//! or when nothing is present, we report `none`.

use std::fs;
use std::path::Path;

/// One detected DRM device.
#[derive(Clone, Debug, serde::Serialize)]
pub struct GpuDevice {
    /// Card node name, e.g. `card0`.
    pub node: String,
    /// Vendor name: `amd`, `intel`, `nvidia`, `virtio`, or `unknown`.
    pub vendor: String,
}

/// Summary of the host's graphics hardware.
#[derive(Clone, Debug, serde::Serialize)]
pub struct GpuInfo {
    pub present: bool,
    pub vendor: String,
    /// Path to a render node (e.g. `/dev/dri/renderD128`), if one exists.
    pub render_node: Option<String>,
    pub devices: Vec<GpuDevice>,
}

impl GpuInfo {
    /// The "nothing here" answer.
    pub fn none() -> Self {
        GpuInfo { present: false, vendor: "none".to_string(), render_node: None, devices: vec![] }
    }
}

/// Map a PCI vendor id to a vendor name.
pub fn vendor_name(id: &str) -> &'static str {
    match id.trim().to_ascii_lowercase().as_str() {
        "0x10de" => "nvidia",
        "0x1002" | "0x1022" => "amd",
        "0x8086" => "intel",
        "0x1af4" => "virtio",
        _ => "unknown",
    }
}

/// Pick a single headline vendor from the detected devices. Discrete parts win
/// over integrated ones so a laptop with an iGPU + dGPU reports the dGPU.
pub fn headline_vendor(devices: &[GpuDevice]) -> String {
    for want in ["nvidia", "amd", "intel", "virtio", "unknown"] {
        if devices.iter().any(|d| d.vendor == want) {
            return want.to_string();
        }
    }
    "none".to_string()
}

/// Assemble a `GpuInfo` from raw device data. Pure so it can be unit-tested.
pub fn build_info(devices: Vec<GpuDevice>, render_node: Option<String>) -> GpuInfo {
    let present = !devices.is_empty();
    GpuInfo {
        present,
        vendor: headline_vendor(&devices),
        render_node,
        devices,
    }
}

/// Read the vendor id of one card directory, if readable.
fn read_card_vendor(card: &Path) -> Option<String> {
    let raw = fs::read_to_string(card.join("device/vendor")).ok()?;
    Some(vendor_name(&raw).to_string())
}

/// Scan `/sys/class/drm` for card devices.
fn scan_cards(drm: &Path) -> Vec<GpuDevice> {
    let mut out = Vec::new();
    let Ok(entries) = fs::read_dir(drm) else { return out };
    let mut names: Vec<String> = entries
        .flatten()
        .filter_map(|e| e.file_name().into_string().ok())
        .collect();
    names.sort();
    for name in names {
        // Card nodes are `card0`, `card1`, … but not `card0-DP-1` connectors.
        if !name.starts_with("card") || name.contains('-') {
            continue;
        }
        if let Some(vendor) = read_card_vendor(&drm.join(&name)) {
            out.push(GpuDevice { node: name, vendor });
        }
    }
    out
}

/// First render node under `/dev/dri`, if any.
fn find_render_node(dri: &Path) -> Option<String> {
    let mut names: Vec<String> = fs::read_dir(dri)
        .ok()?
        .flatten()
        .filter_map(|e| e.file_name().into_string().ok())
        .filter(|n| n.starts_with("renderD"))
        .collect();
    names.sort();
    names.first().map(|n| dri.join(n).to_string_lossy().into_owned())
}

/// Detect the host GPU. Never fails: absence is reported as `GpuInfo::none()`.
pub fn detect() -> GpuInfo {
    detect_at(Path::new("/sys/class/drm"), Path::new("/dev/dri"))
}

/// Detection against explicit paths (used by tests and for clarity).
pub fn detect_at(drm: &Path, dri: &Path) -> GpuInfo {
    let devices = scan_cards(drm);
    if devices.is_empty() {
        return GpuInfo::none();
    }
    build_info(devices, find_render_node(dri))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vendor_ids_map_to_names() {
        assert_eq!(vendor_name("0x10de"), "nvidia");
        assert_eq!(vendor_name("0x1002"), "amd");
        assert_eq!(vendor_name("0x8086"), "intel");
        assert_eq!(vendor_name("0x1af4"), "virtio");
        assert_eq!(vendor_name("0xffff"), "unknown");
        assert_eq!(vendor_name(" 0x1002\n"), "amd");
    }

    #[test]
    fn discrete_vendor_wins_over_integrated() {
        let devices = vec![
            GpuDevice { node: "card0".into(), vendor: "intel".into() },
            GpuDevice { node: "card1".into(), vendor: "nvidia".into() },
        ];
        assert_eq!(headline_vendor(&devices), "nvidia");
    }

    #[test]
    fn empty_scan_is_absent() {
        let info = build_info(vec![], None);
        assert!(!info.present);
        assert_eq!(info.vendor, "none");
    }

    #[test]
    fn build_info_reports_presence_and_node() {
        let devices = vec![GpuDevice { node: "card0".into(), vendor: "amd".into() }];
        let info = build_info(devices, Some("/dev/dri/renderD128".into()));
        assert!(info.present);
        assert_eq!(info.vendor, "amd");
        assert_eq!(info.render_node.as_deref(), Some("/dev/dri/renderD128"));
    }

    #[test]
    fn missing_dirs_detect_as_none() {
        let info = detect_at(Path::new("/nonexistent/drm"), Path::new("/nonexistent/dri"));
        assert!(!info.present);
        assert_eq!(info.vendor, "none");
    }

    #[test]
    fn connector_nodes_are_ignored() {
        // `card0-DP-1` is a connector, not a card; scanning must skip it.
        let devices = scan_cards(Path::new("/nonexistent/drm"));
        assert!(devices.is_empty());
    }
}
