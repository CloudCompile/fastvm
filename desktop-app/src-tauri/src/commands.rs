//! Tauri commands - the only surface the frontend can call.

use serde::Serialize;
use tauri::command;

use crate::catalog::{self, App, RunSpec};
use crate::docker::{self, Instance};
use crate::gpu::{self, GpuInfo, GpuMode};

/// Parse a GPU mode coming from the frontend.
fn parse_gpu_mode(s: Option<&str>) -> GpuMode {
    match s.unwrap_or("off").to_ascii_lowercase().as_str() {
        "drm" => GpuMode::Drm,
        "rocm" => GpuMode::Rocm,
        "nvidia" => GpuMode::Nvidia,
        _ => GpuMode::Off,
    }
}

/// The full marketplace listing plus Docker availability and host GPU state.
#[derive(Serialize)]
pub struct Marketplace {
    pub apps: Vec<App>,
    pub variant_count: usize,
    pub docker_available: bool,
    pub docker_version: Option<String>,
    pub gpu: GpuInfo,
}

#[command]
pub fn marketplace() -> Marketplace {
    let version = docker::version().ok();
    Marketplace {
        apps: catalog::marketplace(),
        variant_count: catalog::variant_count(),
        docker_available: version.is_some(),
        docker_version: version,
        gpu: gpu::detect(),
    }
}

/// Host GPU detection, for the UI to gate the passthrough toggle.
#[command]
pub fn detect_gpu() -> GpuInfo {
    gpu::detect()
}

#[command]
pub fn docker_version() -> Result<String, String> {
    docker::version()
}

/// Fields the frontend sends when building a command preview.
#[derive(serde::Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct PreviewRequest {
    pub tag: String,
    pub host_port: Option<u16>,
    pub dashboard_port: Option<u16>,
    pub name: Option<String>,
    pub shm_size: Option<String>,
    pub gpu: Option<bool>,
    /// One of `off`, `drm`, `rocm`, `nvidia`; wins over `gpu` when set.
    pub gpu_mode: Option<String>,
    /// Encoder to request (`vaapi`, `qsv`, `nvenc`, `software`); defaults per mode.
    pub encoder: Option<String>,
    pub memory: Option<String>,
    pub cpus: Option<String>,
    pub env: Option<Vec<String>>,
    pub volumes: Option<Vec<String>>,
}

/// Turn a preview request into a validated run spec.
fn spec_from_preview(req: &PreviewRequest) -> RunSpec {
    let image = if req.tag.contains(':') { req.tag.clone() } else { catalog::image_ref(&req.tag) };
    RunSpec {
        image,
        host_port: req.host_port.unwrap_or(0),
        dashboard_port: req.dashboard_port.unwrap_or(0),
        name: req.name.clone().filter(|s| !s.is_empty()),
        shm_size: req.shm_size.clone().filter(|s| !s.is_empty()),
        memory: req.memory.clone().filter(|s| !s.is_empty()),
        cpus: req.cpus.clone().filter(|s| !s.is_empty()),
        gpu: req.gpu.unwrap_or(false),
        gpu_mode: parse_gpu_mode(req.gpu_mode.as_deref()),
        encoder: req.encoder.clone().filter(|s| !s.is_empty()),
        env: req.env.clone().unwrap_or_default(),
        volumes: req.volumes.clone().unwrap_or_default(),
    }
}

/// The exact `docker run` invocation a deploy would use, as a single string.
///
/// The frontend renders this verbatim so the preview can never drift from what
/// `deploy` actually runs - both go through `catalog::build_run_args`.
#[command]
pub fn preview_run_args(req: PreviewRequest) -> Result<String, String> {
    let args = catalog::build_run_args(&spec_from_preview(&req))?;
    Ok(format!("docker {}", args.join(" ")))
}

/// The same deploy, rendered as a `docker-compose.yml` service.
#[command]
pub fn preview_compose(req: PreviewRequest) -> Result<String, String> {
    catalog::build_compose(&spec_from_preview(&req))
}

/// Commands to run inside a deployed container to confirm the chosen GPU mode
/// is really delivering the device.
#[command]
pub fn gpu_verify(mode: String) -> Vec<String> {
    gpu::verification_steps(parse_gpu_mode(Some(&mode)))
        .into_iter()
        .map(String::from)
        .collect()
}

/// List FastVM containers, newest first.
#[command]
pub fn list_instances() -> Result<Vec<Instance>, String> {
    let mut all = docker::list()?;
    all.retain(|c| c.image.contains("fastvm") || c.name.starts_with("FastVM"));
    Ok(all)
}

/// Arguments coming from the frontend for a one-click deploy.
#[derive(serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeployRequest {
    /// Image tag, e.g. `pearos-latest`.
    pub tag: String,
    /// Optional explicit host port; when absent a free port is chosen.
    pub host_port: Option<u16>,
    pub dashboard_port: Option<u16>,
    pub name: Option<String>,
    pub shm_size: Option<String>,
    pub memory: Option<String>,
    pub cpus: Option<String>,
    pub gpu: Option<bool>,
    /// One of `off`, `drm`, `rocm`, `nvidia`; wins over `gpu` when set.
    pub gpu_mode: Option<String>,
    /// Encoder to request (`vaapi`, `qsv`, `nvenc`, `software`); defaults per mode.
    pub encoder: Option<String>,
    pub env: Option<Vec<String>>,
    pub volumes: Option<Vec<String>>,
}

#[derive(Serialize)]
pub struct DeployResult {
    pub ok: bool,
    pub container_id: String,
    pub image: String,
    pub host_port: u16,
    pub dashboard_port: u16,
    pub args: Vec<String>,
    pub error: Option<String>,
}

/// One-click deploy: build the run args, start the container, return the URLs.
#[command]
pub fn deploy(req: DeployRequest) -> Result<DeployResult, String> {
    // Reject unknown tags early instead of starting a doomed pull.
    if !is_known_tag(&req.tag) {
        return Err(format!("unknown image tag: {}", req.tag));
    }

    let used: Vec<u16> = docker::list()
        .unwrap_or_default()
        .iter()
        .flat_map(|c| [c.desktop_port, c.dashboard_port])
        .flatten()
        .collect();

    let host_port = req.host_port.unwrap_or_else(|| docker::next_free_port(&used, 3000));
    let dashboard_port = req
        .dashboard_port
        .unwrap_or_else(|| docker::next_free_port(&used, 3001));

    let preview = PreviewRequest {
        tag: req.tag.clone(),
        host_port: Some(host_port),
        dashboard_port: Some(dashboard_port),
        name: req.name.clone(),
        shm_size: req.shm_size.clone(),
        gpu: req.gpu,
        gpu_mode: req.gpu_mode.clone(),
        encoder: req.encoder.clone(),
        memory: req.memory.clone(),
        cpus: req.cpus.clone(),
        env: req.env.clone(),
        volumes: req.volumes.clone(),
    };
    let spec = spec_from_preview(&preview);
    let image = spec.image.clone();
    let args = catalog::build_run_args(&spec)?;
    let out = docker::docker(&args);
    Ok(DeployResult {
        ok: out.ok(),
        container_id: out.stdout.trim().to_string(),
        image,
        host_port,
        dashboard_port,
        args,
        error: if out.ok() { None } else { Some(out.stderr.trim().to_string()) },
    })
}

#[command]
pub fn stop_instance(id: String) -> Result<(), String> {
    let out = docker::docker(&["stop".into(), id]);
    if out.ok() { Ok(()) } else { Err(out.stderr.trim().to_string()) }
}

#[command]
pub fn remove_instance(id: String) -> Result<(), String> {
    let out = docker::docker(&["rm".into(), "-f".into(), id]);
    if out.ok() { Ok(()) } else { Err(out.stderr.trim().to_string()) }
}

#[command]
pub fn instance_logs(id: String) -> Result<String, String> {
    let out = docker::docker(&["logs".into(), "--tail".into(), "300".into(), id]);
    Ok(format!("{}{}", out.stdout, out.stderr))
}

/// One-shot CPU/memory sample for the given container ids.
#[command]
pub fn container_stats(ids: Vec<String>) -> Result<Vec<docker::Stats>, String> {
    docker::stats(&ids)
}

/// Stop every running FastVM container. Returns how many were stopped.
#[command]
pub fn stop_all_instances() -> Result<usize, String> {
    let running: Vec<Instance> = docker::list()?
        .into_iter()
        .filter(|c| c.image.contains("fastvm") || c.name.starts_with("FastVM"))
        .filter(|c| c.state.eq_ignore_ascii_case("running"))
        .collect();
    let mut stopped = 0;
    for c in &running {
        let out = docker::docker(&["stop".into(), c.id.clone()]);
        if out.ok() {
            stopped += 1;
        }
    }
    Ok(stopped)
}

/// Whether a tag corresponds to a published image in the catalog.
fn is_known_tag(tag: &str) -> bool {
    let Some(stem) = tag.strip_suffix("-latest") else {
        return false;
    };
    if catalog::flavor_tag(stem).is_ok() || catalog::single_app_tag(stem).is_ok() {
        return true;
    }
    // Desktop/preset tags: `<desktop>-<preset>-latest`.
    match stem.rsplit_once('-') {
        Some((desktop, preset)) => catalog::desktop_tag(desktop, preset).is_ok(),
        None => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn preview(tag: &str) -> String {
        preview_run_args(PreviewRequest { tag: tag.into(), ..Default::default() }).unwrap()
    }

    #[test]
    fn preview_uses_default_ports() {
        assert_eq!(
            preview("xfce4-none-latest"),
            "docker run -d -p 3000:3000 ghcr.io/cloudcompile/fastvm:xfce4-none-latest"
        );
    }

    #[test]
    fn preview_matches_the_deploy_arg_builder() {
        // The whole point of the command: preview == what deploy runs.
        let spec = RunSpec {
            image: catalog::image_ref("kde-gaming-latest"),
            host_port: 3000,
            dashboard_port: 3001,
            name: Some("FastVM-gaming".into()),
            shm_size: Some("4gb".into()),
            gpu: true,
            ..Default::default()
        };
        let expected = format!("docker {}", catalog::build_run_args(&spec).unwrap().join(" "));
        let got = preview_run_args(PreviewRequest {
            tag: "kde-gaming-latest".into(),
            host_port: Some(3000),
            dashboard_port: Some(3001),
            name: Some("FastVM-gaming".into()),
            shm_size: Some("4gb".into()),
            gpu: Some(true),
            ..Default::default()
        })
        .unwrap();
        assert_eq!(got, expected);
    }

    #[test]
    fn preview_accepts_a_fully_qualified_image() {
        let got = preview_run_args(PreviewRequest {
            tag: "ghcr.io/cloudcompile/fastvm:pearos-latest".into(),
            ..Default::default()
        })
        .unwrap();
        assert!(got.ends_with("ghcr.io/cloudcompile/fastvm:pearos-latest"));
    }

    #[test]
    fn preview_omits_blank_fields() {
        let got = preview_run_args(PreviewRequest {
            tag: "terminal-latest".into(),
            name: Some(String::new()),
            shm_size: Some(String::new()),
            ..Default::default()
        })
        .unwrap();
        assert!(!got.contains("--name"));
        assert!(!got.contains("--shm-size"));
    }

    #[test]
    fn preview_renders_gpu_modes() {
        let nvidia = preview_run_args(PreviewRequest {
            tag: "kde-gaming-latest".into(),
            gpu_mode: Some("nvidia".into()),
            ..Default::default()
        })
        .unwrap();
        assert!(nvidia.contains("--gpus all"), "{nvidia}");

        let rocm = preview_run_args(PreviewRequest {
            tag: "kde-gaming-latest".into(),
            gpu_mode: Some("rocm".into()),
            ..Default::default()
        })
        .unwrap();
        assert!(rocm.contains("--device /dev/kfd"), "{rocm}");
    }

    #[test]
    fn preview_renders_env_volumes_and_limits() {
        let got = preview_run_args(PreviewRequest {
            tag: "xfce4-none-latest".into(),
            memory: Some("4g".into()),
            cpus: Some("2".into()),
            env: Some(vec!["TZ=Etc/UTC".into()]),
            volumes: Some(vec!["/tmp/work:/work".into()]),
            ..Default::default()
        })
        .unwrap();
        assert!(got.contains("--memory 4g"));
        assert!(got.contains("--cpus 2"));
        assert!(got.contains("-e TZ=Etc/UTC"));
        assert!(got.contains("-v /tmp/work:/work"));
    }

    #[test]
    fn gpu_mode_strings_parse() {
        assert_eq!(parse_gpu_mode(Some("nvidia")), GpuMode::Nvidia);
        assert_eq!(parse_gpu_mode(Some("ROCM")), GpuMode::Rocm);
        assert_eq!(parse_gpu_mode(Some("drm")), GpuMode::Drm);
        assert_eq!(parse_gpu_mode(Some("bogus")), GpuMode::Off);
        assert_eq!(parse_gpu_mode(None), GpuMode::Off);
    }

    #[test]
    fn accepts_real_tags() {
        assert!(is_known_tag("pearos-latest"));
        assert!(is_known_tag("xfce4-none-latest"));
        assert!(is_known_tag("kde-gaming-latest"));
        assert!(is_known_tag("browser-latest"));
    }

    #[test]
    fn rejects_bogus_tags() {
        assert!(!is_known_tag("evil-latest"));
        assert!(!is_known_tag("xfce4-nope-latest"));
        assert!(!is_known_tag("nope-none-latest"));
        assert!(!is_known_tag("pearos"));
    }
}
