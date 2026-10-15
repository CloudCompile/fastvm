//! Tauri commands - the only surface the frontend can call.

use serde::Serialize;
use tauri::command;

use crate::catalog::{self, App, RunSpec};
use crate::docker::{self, Instance};
use crate::gpu::{self, GpuInfo};

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
}

/// The exact `docker run` invocation a deploy would use, as a single string.
///
/// The frontend renders this verbatim so the preview can never drift from what
/// `deploy` actually runs - both go through `catalog::build_run_args`.
#[command]
pub fn preview_run_args(req: PreviewRequest) -> Result<String, String> {
    let image = if req.tag.contains(':') { req.tag.clone() } else { catalog::image_ref(&req.tag) };
    let spec = RunSpec {
        image,
        host_port: req.host_port.unwrap_or(0),
        dashboard_port: req.dashboard_port.unwrap_or(0),
        name: req.name.filter(|s| !s.is_empty()),
        shm_size: req.shm_size.filter(|s| !s.is_empty()),
        gpu: req.gpu.unwrap_or(false),
        ..Default::default()
    };
    let args = catalog::build_run_args(&spec)?;
    Ok(format!("docker {}", args.join(" ")))
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

    let image = catalog::image_ref(&req.tag);
    let spec = RunSpec {
        image: image.clone(),
        host_port,
        dashboard_port,
        name: req.name.clone().filter(|s| !s.is_empty()),
        shm_size: req.shm_size.clone(),
        memory: req.memory.clone(),
        cpus: req.cpus.clone(),
        gpu: req.gpu.unwrap_or(false),
        env: vec![],
        volumes: vec![],
    };
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
