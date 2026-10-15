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
    /// while `Drm` opts into hardware rendering and a hardware encoder.
    ///
    /// `encoder` overrides the mode's default encoder (e.g. `qsv` on Intel).
    pub fn env(self, encoder: Option<&str>) -> Vec<(&'static str, String)> {
        let enc = encoder
            .filter(|e| !e.is_empty())
            .or_else(|| self.default_encoder())
            .unwrap_or("software")
            .to_string();
        match self {
            GpuMode::Off => vec![],
            GpuMode::Drm => vec![
                ("FASTVM_GPU_HW", "true".to_string()),
                ("FASTVM_RECORDING_ENCODER", enc),
            ],
            GpuMode::Rocm => vec![
                ("DISABLE_DRI", "1".to_string()),
                ("FASTVM_GPU_HW", "false".to_string()),
                // No VA-API on CDNA parts; the desktop encodes in software.
                ("FASTVM_RECORDING_ENCODER", "software".to_string()),
            ],
            GpuMode::Nvidia => vec![
                ("NVIDIA_DRIVER_CAPABILITIES", "compute,video,utility".to_string()),
                ("FASTVM_RECORDING_ENCODER", enc),
            ],
        }
    }

    /// The encoder the mode prefers when the user does not pick one.
    pub fn default_encoder(self) -> Option<&'static str> {
        match self {
            GpuMode::Off => None,
            GpuMode::Drm => Some("vaapi"),
            GpuMode::Rocm => Some("software"),
            GpuMode::Nvidia => Some("nvenc"),
        }
    }

    /// Whether the mode needs the NVIDIA container toolkit on the host.
    pub fn needs_toolkit(self) -> bool {
        self == GpuMode::Nvidia
    }
}

/// Encoders a set of devices can plausibly use, best first, always ending in
/// `software`. Mirrors the table in `docs/gpu.md` §2: NVIDIA → `nvenc`,
/// Intel → `qsv` then `vaapi`, AMD → `vaapi`.
pub fn available_encoders(devices: &[GpuDevice], compute_only: bool) -> Vec<String> {
    let has = |v: &str| devices.iter().any(|d| d.vendor == v);
    let mut out = Vec::new();
    if has("nvidia") {
        out.push("nvenc".to_string());
    }
    if has("intel") {
        out.push("qsv".to_string());
        out.push("vaapi".to_string());
    }
    if has("amd") && !compute_only {
        out.push("vaapi".to_string());
    }
    out.push("software".to_string());
    out
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
    /// Kernel driver from the device `uevent` (e.g. `amdgpu`, `i915`, `nvidia`),
    /// when readable. A more precise signal than the PCI vendor id.
    pub driver: Option<String>,
    /// Total VRAM in bytes (AMD `mem_info_vram_total`), when readable.
    pub vram_bytes: Option<u64>,
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
    /// Encoders this host can plausibly use, best first (always ends `software`).
    pub encoders: Vec<String>,
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
            encoders: vec!["software".to_string()],
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
    let encoders = available_encoders(&devices, compute_only);
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
        encoders,
        recommended,
        warning,
    }
}

/// Read the kernel driver for one card from its device `uevent`.
fn read_card_driver(card: &Path) -> Option<String> {
    let raw = fs::read_to_string(card.join("device/uevent")).ok()?;
    raw.lines()
        .find_map(|l| l.strip_prefix("DRIVER="))
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

/// Read total VRAM in bytes (AMD exposes `mem_info_vram_total`), if present.
fn read_card_vram(card: &Path) -> Option<u64> {
    fs::read_to_string(card.join("device/mem_info_vram_total"))
        .ok()?
        .trim()
        .parse::<u64>()
        .ok()
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
        let card = drm.join(&name);
        if let Some(vendor) = read_card_vendor(&card) {
            out.push(GpuDevice {
                node: name,
                vendor,
                driver: read_card_driver(&card),
                vram_bytes: read_card_vram(&card),
            });
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

    /// A minimal device with no driver/VRAM data, for tests that don't care.
    fn dev(node: &str, vendor: &str) -> GpuDevice {
        GpuDevice { node: node.into(), vendor: vendor.into(), driver: None, vram_bytes: None }
    }

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
        let devices = vec![dev("card0", "intel"), dev("card1", "nvidia")];
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
        let devices = vec![dev("card0", "amd")];
        let info = build_info(devices, Some("/dev/dri/renderD128".into()), false, false);
        assert!(info.present);
        assert_eq!(info.vendor, "amd");
        assert_eq!(info.render_node.as_deref(), Some("/dev/dri/renderD128"));
        assert_eq!(info.recommended, GpuMode::Drm);
    }

    #[test]
    fn nvidia_is_recommended_over_drm() {
        let devices = vec![dev("card0", "nvidia")];
        let info = build_info(devices, None, false, true);
        assert_eq!(info.recommended, GpuMode::Nvidia);
        assert_eq!(info.modes, vec![GpuMode::Nvidia, GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn rocm_requires_amd_and_kfd() {
        let amd = vec![dev("card0", "amd")];
        assert_eq!(available_modes(&amd, true, false), vec![GpuMode::Rocm, GpuMode::Drm, GpuMode::Off]);
        assert_eq!(available_modes(&amd, false, false), vec![GpuMode::Drm, GpuMode::Off]);
        let intel = vec![dev("card0", "intel")];
        assert_eq!(available_modes(&intel, true, false), vec![GpuMode::Drm, GpuMode::Off]);
    }

    #[test]
    fn encoders_follow_the_vendor() {
        assert_eq!(available_encoders(&[dev("card0", "nvidia")], false), vec!["nvenc", "software"]);
        assert_eq!(available_encoders(&[dev("card0", "intel")], false), vec!["qsv", "vaapi", "software"]);
        assert_eq!(available_encoders(&[dev("card0", "amd")], false), vec!["vaapi", "software"]);
        // No VA-API on compute-only CDNA parts.
        assert_eq!(available_encoders(&[dev("card0", "amd")], true), vec!["software"]);
        assert_eq!(available_encoders(&[], false), vec!["software"]);
    }

    #[test]
    fn intel_drm_prefers_qsv_when_asked() {
        assert!(GpuMode::Drm
            .env(Some("qsv"))
            .contains(&("FASTVM_RECORDING_ENCODER", "qsv".to_string())));
        // Default stays vaapi when no encoder is given.
        assert!(GpuMode::Drm
            .env(None)
            .contains(&("FASTVM_RECORDING_ENCODER", "vaapi".to_string())));
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
        assert_eq!(GpuMode::Off.env(None), Vec::<(&str, String)>::new());
        assert!(GpuMode::Drm.env(None).contains(&("FASTVM_RECORDING_ENCODER", "vaapi".to_string())));
        assert!(GpuMode::Rocm.env(None).contains(&("DISABLE_DRI", "1".to_string())));
        assert!(GpuMode::Rocm.env(None).contains(&("FASTVM_RECORDING_ENCODER", "software".to_string())));
        assert!(GpuMode::Nvidia.env(None).contains(&("FASTVM_RECORDING_ENCODER", "nvenc".to_string())));
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
