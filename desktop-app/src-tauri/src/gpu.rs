//! Host GPU detection and acceleration modes for the marketplace.
//!
//! Linux exposes DRM devices under `/sys/class/drm` and device nodes under
//! `/dev/dri`. We read each card's PCI vendor id to decide whether a GPU is
//! present and what it is, so the UI can offer passthrough only when it would
//! actually do something. We also detect the compute device (`/dev/kfd`) and the
//! NVIDIA container toolkit so we can pick the right `docker run` flags.
//!
//! Detection is best-effort: on Windows/macOS, or when nothing is present, we
//! report `none` / `GpuMode::Off`.

use std::fs;
use std::path::Path;

/// How a container should receive the host GPU.
///
/// The variants map to the flags a container runtime understands; keeping them
/// as data means `catalog::build_run_args` stays pure and unit-testable.
#[derive(Clone, Copy, Debug, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum GpuMode {
    /// No passthrough.
    Off,
    /// Generic Linux DRM passthrough: `--device /dev/dri`.
    Drm,
    /// AMD compute: DRM plus `/dev/kfd` and `--group-add keep-groups`.
    Rocm,
    /// NVIDIA: `--gpus all` (requires the NVIDIA container toolkit).
    Nvidia,
}

impl Default for GpuMode {
    fn default() -> Self {
        GpuMode::Off
    }
}

impl GpuMode {
    /// The flags this mode contributes to `docker run` (after `run -d`).
    pub fn run_flags(self) -> Vec<&'static str> {
        match self {
            GpuMode::Off => vec![],
            GpuMode::Drm => vec!["--device", "/dev/dri"],
            GpuMode::Rocm => {
                vec!["--device", "/dev/dri", "--device", "/dev/kfd", "--group-add", "keep-groups"]
            }
            GpuMode::Nvidia => vec!["--gpus", "all"],
        }
    }

    /// Environment variables the mode should set so the *container* uses the
    /// device. These mirror the session helper in `docs/gpu.md`: `Rocm` disables
    /// DRI3 (no graphics engine on CDNA parts) and pins the encoder to software,
    /// while `Drm` opts into hardware rendering and the VA-API encoder.
    pub fn env(self) -> Vec<(&'static str, &'static str)> {
        match self {
            GpuMode::Off => vec![],
            GpuMode::Drm => vec![
                ("FASTVM_GPU_HW", "true"),
                ("FASTVM_RECORDING_ENCODER", "vaapi"),
            ],
            GpuMode::Rocm => vec![
                ("DISABLE_DRI", "1"),
                ("FASTVM_GPU_HW", "false"),
                ("FASTVM_RECORDING_ENCODER", "software"),
            ],
            GpuMode::Nvidia => vec![
                ("NVIDIA_DRIVER_CAPABILITIES", "compute,video,utility"),
                ("FASTVM_RECORDING_ENCODER", "nvenc"),
            ],
        }
    }

    /// Whether the mode needs the NVIDIA container toolkit on the host.
    pub fn needs_toolkit(self) -> bool {
        self == GpuMode::Nvidia
    }
}

/// The shell commands a user can run *inside a deployed container* to confirm a
/// given mode is actually delivering the GPU. Pure, so the UI can show them
/// without touching the host.
pub fn verification_steps(mode: GpuMode) -> Vec<&'static str> {
    match mode {
        GpuMode::Off => vec!["glxinfo -B | grep -i renderer   # expect: llvmpipe (software)"],
        GpuMode::Drm => vec![
            "vainfo                                     # expect: VA-API entrypoints",
            "glxinfo -B | grep -i renderer              # expect: your Intel/AMD GPU, not llvmpipe",
        ],
        GpuMode::Rocm => vec![
            "rocm-smi                                   # expect: your AMD accelerator",
            "glxinfo -B | grep -i renderer              # expect: llvmpipe (compute-only part)",
        ],
        GpuMode::Nvidia => vec![
            "nvidia-smi                                 # expect: driver + GPU table",
            "ffmpeg -hide_banner -encoders | grep nvenc # expect: h264_nvenc",
        ],
    }
}

/// One detected DRM device.
#[derive(Clone, Debug, serde::Serialize)]
pub struct GpuDevice {
    /// Card node name, e.g. `card0`.
    pub node: String,
    /// Vendor name: `amd`, `intel`, `nvidia`, `virtio`, or `unknown`.
    pub vendor: String,
}

/// Summary of the host's graphics hardware and available acceleration modes.
#[derive(Clone, Debug, serde::Serialize)]
pub struct GpuInfo {
    pub present: bool,
    pub vendor: String,
    /// Path to a render node (e.g. `/dev/dri/renderD128`), if one exists.
    pub render_node: Option<String>,
    pub devices: Vec<GpuDevice>,
    /// `/dev/kfd` is present (AMD ROCm compute device).
    pub kfd: bool,
    /// The NVIDIA container toolkit appears to be installed.
    pub toolkit: bool,
    /// A render node exists but no KMS card node: a compute-only accelerator
    /// (e.g. AMD Instinct MI300X) with no graphics engine, per `docs/gpu.md`.
    pub compute_only: bool,
    /// Acceleration modes this host can actually offer, best first.
    pub modes: Vec<GpuMode>,
    /// The mode to preselect in the UI.
    pub recommended: GpuMode,
    /// A human-readable warning about the recommended mode, if any (e.g. the
    /// NVIDIA container toolkit is missing).
    pub warning: Option<String>,
}

impl GpuInfo {
    /// The "nothing here" answer.
    pub fn none() -> Self {
        GpuInfo {
            present: false,
            vendor: "none".to_string(),
            render_node: None,
            devices: vec![],
            kfd: false,
            toolkit: false,
            compute_only: false,
            modes: vec![GpuMode::Off],
            recommended: GpuMode::Off,
            warning: None,
        }
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

/// The acceleration modes a set of devices can offer, best first.
///
/// `Nvidia` is offered whenever an NVIDIA device is present (the toolkit flag is
/// surfaced separately so the UI can warn if it is missing). `Rocm` requires
/// `/dev/kfd` plus an AMD device (or a compute-only AMD accelerator). `Drm` is
/// the generic fallback, offered whenever any card or render node exists.
pub fn available_modes(devices: &[GpuDevice], kfd: bool, compute_only: bool) -> Vec<GpuMode> {
    let has = |v: &str| devices.iter().any(|d| d.vendor == v);
    let mut modes = Vec::new();
    if has("nvidia") {
        modes.push(GpuMode::Nvidia);
    }
    if kfd && (has("amd") || compute_only) {
        modes.push(GpuMode::Rocm);
    }
    if !devices.is_empty() || compute_only {
        modes.push(GpuMode::Drm);
    }
    modes.push(GpuMode::Off);
    modes
}

/// Assemble a `GpuInfo` from raw device data. Pure so it can be unit-tested.
pub fn build_info(
    devices: Vec<GpuDevice>,
    render_node: Option<String>,
    kfd: bool,
    toolkit: bool,
) -> GpuInfo {
    let compute_only = devices.is_empty() && render_node.is_some();
    let present = !devices.is_empty() || compute_only;
    let modes = available_modes(&devices, kfd, compute_only);
    let recommended = modes.first().copied().unwrap_or(GpuMode::Off);
    // With no card node we cannot read a PCI vendor; `/dev/kfd` implies AMD.
    let vendor = if devices.is_empty() && kfd {
        "amd".to_string()
    } else {
        headline_vendor(&devices)
    };
    let warning = if recommended.needs_toolkit() && !toolkit {
        Some(
            "NVIDIA container toolkit not detected — install it and run \
             `nvidia-ctk runtime configure --runtime=docker` before using --gpus"
                .to_string(),
        )
    } else if compute_only {
        Some(
            "Compute-only accelerator (no graphics engine): the desktop renders on the CPU, \
             but GPU compute is available"
                .to_string(),
        )
    } else {
        None
    };
    GpuInfo {
        present,
        vendor,
        render_node,
        devices,
        kfd,
        toolkit,
        compute_only,
        modes,
        recommended,
        warning,
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

/// Whether the NVIDIA container toolkit looks installed.
fn toolkit_present() -> bool {
    ["/usr/bin/nvidia-ctk", "/usr/bin/nvidia-container-runtime", "/usr/bin/nvidia-container-toolkit"]
        .iter()
        .any(|p| Path::new(p).exists())
}

/// Detect the host GPU. Never fails: absence is reported as `GpuInfo::none()`.
pub fn detect() -> GpuInfo {
    detect_at(Path::new("/sys/class/drm"), Path::new("/dev/dri"), Path::new("/dev/kfd"))
}

/// Detection against explicit paths (used by tests and for clarity).
pub fn detect_at(drm: &Path, dri: &Path, kfd: &Path) -> GpuInfo {
    let devices = scan_cards(drm);
    let render_node = find_render_node(dri);
    // A render node with no card node is a compute-only accelerator; it still
    // warrants passthrough, so do not short-circuit to `none()` here.
    if devices.is_empty() && render_node.is_none() {
        return GpuInfo::none();
    }
    build_info(devices, render_node, kfd.exists(), toolkit_present())
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
        let info = build_info(vec![], None, false, false);
        assert!(!info.present);
        assert_eq!(info.vendor, "none");
        assert_eq!(info.modes, vec![GpuMode::Off]);
        assert_eq!(info.recommended, GpuMode::Off);
        assert!(!info.compute_only);
    }

    #[test]
    fn compute_only_accelerator_is_detected() {
        // A render node but no card node: AMD Instinct / CDNA (see docs/gpu.md).
        let info = build_info(vec![], Some("/dev/dri/renderD128".into()), true, false);
        assert!(info.present, "compute-only accelerators still count as present");
        assert!(info.compute_only);
        assert_eq!(info.vendor, "amd");
        // With /dev/kfd present, ROCm is the best mode for compute.
        assert_eq!(info.recommended, GpuMode::Rocm);
        assert_eq!(info.modes, vec![GpuMode::Rocm, GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn build_info_reports_presence_and_node() {
        let devices = vec![GpuDevice { node: "card0".into(), vendor: "amd".into() }];
        let info = build_info(devices, Some("/dev/dri/renderD128".into()), false, false);
        assert!(info.present);
        assert_eq!(info.vendor, "amd");
        assert_eq!(info.render_node.as_deref(), Some("/dev/dri/renderD128"));
        assert_eq!(info.recommended, GpuMode::Drm);
    }

    #[test]
    fn nvidia_is_recommended_over_drm() {
        let devices = vec![GpuDevice { node: "card0".into(), vendor: "nvidia".into() }];
        let info = build_info(devices, None, false, true);
        assert_eq!(info.recommended, GpuMode::Nvidia);
        assert_eq!(info.modes, vec![GpuMode::Nvidia, GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn rocm_requires_amd_and_kfd() {
        let amd = vec![GpuDevice { node: "card0".into(), vendor: "amd".into() }];
        assert_eq!(available_modes(&amd, true, false), vec![GpuMode::Rocm, GpuMode::Drm, GpuMode::Off]);
        assert_eq!(available_modes(&amd, false, false), vec![GpuMode::Drm, GpuMode::Off]);
        let intel = vec![GpuDevice { node: "card0".into(), vendor: "intel".into() }];
        assert_eq!(available_modes(&intel, true, false), vec![GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn compute_only_offers_rocm_and_drm() {
        assert_eq!(available_modes(&[], true, true), vec![GpuMode::Rocm, GpuMode::Drm, GpuMode::Off]);
        assert_eq!(available_modes(&[], false, true), vec![GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn run_flags_match_the_runtime() {
        assert_eq!(GpuMode::Off.run_flags(), Vec::<&str>::new());
        assert_eq!(GpuMode::Drm.run_flags(), vec!["--device", "/dev/dri"]);
        assert_eq!(GpuMode::Nvidia.run_flags(), vec!["--gpus", "all"]);
        assert_eq!(
            GpuMode::Rocm.run_flags(),
            vec!["--device", "/dev/dri", "--device", "/dev/kfd", "--group-add", "keep-groups"]
        );
    }

    #[test]
    fn mode_env_matches_the_gpu_doc() {
        assert_eq!(GpuMode::Off.env(), Vec::<(&str, &str)>::new());
        assert!(GpuMode::Drm.env().contains(&("FASTVM_RECORDING_ENCODER", "vaapi")));
        assert!(GpuMode::Rocm.env().contains(&("DISABLE_DRI", "1")));
        assert!(GpuMode::Rocm.env().contains(&("FASTVM_RECORDING_ENCODER", "software")));
        assert!(GpuMode::Nvidia.env().contains(&("FASTVM_RECORDING_ENCODER", "nvenc")));
    }

    #[test]
    fn only_nvidia_needs_the_toolkit() {
        assert!(GpuMode::Nvidia.needs_toolkit());
        assert!(!GpuMode::Drm.needs_toolkit());
        assert!(!GpuMode::Rocm.needs_toolkit());
        assert!(!GpuMode::Off.needs_toolkit());
    }

    #[test]
    fn verification_steps_are_mode_specific() {
        assert!(verification_steps(GpuMode::Nvidia).iter().any(|s| s.contains("nvidia-smi")));
        assert!(verification_steps(GpuMode::Rocm).iter().any(|s| s.contains("rocm-smi")));
        assert!(verification_steps(GpuMode::Drm).iter().any(|s| s.contains("vainfo")));
        assert_eq!(verification_steps(GpuMode::Off).len(), 1);
    }

    #[test]
    fn missing_dirs_detect_as_none() {
        let info = detect_at(
            Path::new("/nonexistent/drm"),
            Path::new("/nonexistent/dri"),
            Path::new("/nonexistent/kfd"),
        );
        assert!(!info.present);
        assert_eq!(info.vendor, "none");
    }
}
