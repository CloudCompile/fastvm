//! Docker CLI wrapper.
//!
//! The parsing helpers are pure functions so they can be unit-tested without a
//! running Docker daemon. Only `version`/`ps`/`run`/`logs`/`stop`/`rm` shell
//! out, and they use `std::process::Command` with an argument vector (no shell),
//! so user input cannot be interpreted as shell syntax.

use std::process::Command;

/// A running (or stopped) FastVM container.
#[derive(Clone, Debug, serde::Serialize)]
pub struct Instance {
    pub id: String,
    pub name: String,
    pub image: String,
    pub state: String,
    pub status: String,
    pub desktop_port: Option<u16>,
    pub dashboard_port: Option<u16>,
}

/// Extract the published host port mapped to `container_port` from the
/// `docker ps` Ports text (e.g. `0.0.0.0:3000->3000/tcp`).
pub fn host_port_for(ports: &str, container_port: u16) -> Option<u16> {
    let needle = format!("->{container_port}/tcp");
    for chunk in ports.split(',') {
        let chunk = chunk.trim();
        if let Some(idx) = chunk.find(&needle) {
            let before = &chunk[..idx];
            if let Some(colon) = before.rfind(':') {
                if let Ok(p) = before[colon + 1..].parse::<u16>() {
                    return Some(p);
                }
            }
        }
    }
    None
}

/// Parse one line of `docker ps --format '{{json .}}'` output into an Instance.
/// Returns `None` for blank or non-JSON lines.
pub fn parse_ps_line(line: &str) -> Option<Instance> {
    let trimmed = line.trim();
    if trimmed.is_empty() || !trimmed.starts_with('{') {
        return None;
    }
    let v: serde_json::Value = serde_json::from_str(trimmed).ok()?;
    let get = |k: &str| v.get(k).and_then(|x| x.as_str()).unwrap_or("").to_string();
    let ports = get("Ports");
    let name = {
        let n = get("Names");
        if n.is_empty() { get("Name") } else { n }
    };
    let id = {
        let i = get("ID");
        if i.is_empty() { get("Id") } else { i }
    };
    Some(Instance {
        id,
        name,
        image: get("Image"),
        state: get("State"),
        status: get("Status"),
        desktop_port: host_port_for(&ports, 3000),
        dashboard_port: host_port_for(&ports, 8099),
    })
}

/// Parse a full `docker ps` listing.
pub fn parse_ps(output: &str) -> Vec<Instance> {
    output.lines().filter_map(parse_ps_line).collect()
}

/// First free host port at or above `start`, skipping `used`.
pub fn next_free_port(used: &[u16], start: u16) -> u16 {
    let mut p = start;
    while used.contains(&p) {
        p += 1;
    }
    p
}

/// A live resource sample for one container.
#[derive(Clone, Debug, serde::Serialize)]
pub struct Stats {
    pub id: String,
    /// e.g. `1.24%`.
    pub cpu: String,
    /// e.g. `256MiB / 8GiB`.
    pub mem: String,
}

/// Parse one `docker stats --no-stream --format '{{json .}}'` line.
pub fn parse_stats_line(line: &str) -> Option<Stats> {
    let trimmed = line.trim();
    if trimmed.is_empty() || !trimmed.starts_with('{') {
        return None;
    }
    let v: serde_json::Value = serde_json::from_str(trimmed).ok()?;
    let get = |k: &str| v.get(k).and_then(|x| x.as_str()).unwrap_or("").to_string();
    let id = {
        let i = get("ID");
        if i.is_empty() { get("Container") } else { i }
    };
    Some(Stats { id, cpu: get("CPUPerc"), mem: get("MemUsage") })
}

/// Parse a full `docker stats` listing.
pub fn parse_stats(output: &str) -> Vec<Stats> {
    output.lines().filter_map(parse_stats_line).collect()
}

/// Result of a Docker invocation.
pub struct Output {
    pub code: i32,
    pub stdout: String,
    pub stderr: String,
}

impl Output {
    pub fn ok(&self) -> bool {
        self.code == 0
    }
}

/// Run the Docker CLI with an explicit argument vector.
pub fn docker(args: &[String]) -> Output {
    match Command::new("docker").args(args).output() {
        Ok(out) => Output {
            code: out.status.code().unwrap_or(1),
            stdout: String::from_utf8_lossy(&out.stdout).into_owned(),
            stderr: String::from_utf8_lossy(&out.stderr).into_owned(),
        },
        Err(err) => Output { code: 1, stdout: String::new(), stderr: err.to_string() },
    }
}

/// Server version string, or an error message.
pub fn version() -> Result<String, String> {
    let out = docker(&[
        "version".into(),
        "--format".into(),
        "{{.Server.Version}}".into(),
    ]);
    if out.ok() && !out.stdout.trim().is_empty() {
        Ok(out.stdout.trim().to_string())
    } else {
        Err(if out.stderr.trim().is_empty() { "docker not available".into() } else { out.stderr.trim().to_string() })
    }
}

/// All containers (running and stopped), parsed.
pub fn list() -> Result<Vec<Instance>, String> {
    let out = docker(&[
        "ps".into(),
        "-a".into(),
        "--no-trunc".into(),
        "--format".into(),
        "{{json .}}".into(),
    ]);
    if !out.ok() {
        return Err(out.stderr.trim().to_string());
    }
    Ok(parse_ps(&out.stdout))
}

/// One-shot resource sample for the given container ids.
pub fn stats(ids: &[String]) -> Result<Vec<Stats>, String> {
    if ids.is_empty() {
        return Ok(vec![]);
    }
    let mut args: Vec<String> = vec![
        "stats".into(),
        "--no-stream".into(),
        "--format".into(),
        "{{json .}}".into(),
    ];
    args.extend(ids.iter().cloned());
    let out = docker(&args);
    if !out.ok() {
        return Err(out.stderr.trim().to_string());
    }
    Ok(parse_stats(&out.stdout))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_host_port() {
        let ports = "0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp, 0.0.0.0:3001->8099/tcp";
        assert_eq!(host_port_for(ports, 3000), Some(3000));
        assert_eq!(host_port_for(ports, 8099), Some(3001));
        assert_eq!(host_port_for(ports, 9999), None);
    }

    #[test]
    fn parses_ps_line() {
        let line = r#"{"ID":"abc123","Names":"FastVM","Image":"ghcr.io/cloudcompile/fastvm:pearos-latest","State":"running","Status":"Up 3 minutes","Ports":"0.0.0.0:3000->3000/tcp, 0.0.0.0:3001->8099/tcp"}"#;
        let inst = parse_ps_line(line).unwrap();
        assert_eq!(inst.id, "abc123");
        assert_eq!(inst.name, "FastVM");
        assert_eq!(inst.state, "running");
        assert_eq!(inst.desktop_port, Some(3000));
        assert_eq!(inst.dashboard_port, Some(3001));
    }

    #[test]
    fn ignores_non_json_lines() {
        assert!(parse_ps_line("not json").is_none());
        assert!(parse_ps_line("").is_none());
        assert_eq!(parse_ps("\nnot json\n").len(), 0);
    }

    #[test]
    fn next_free_port_skips_used() {
        assert_eq!(next_free_port(&[3000, 3001], 3000), 3002);
        assert_eq!(next_free_port(&[], 3000), 3000);
    }

    #[test]
    fn parses_stats_line() {
        let line = r#"{"ID":"abc123","CPUPerc":"1.24%","MemUsage":"256MiB / 8GiB"}"#;
        let s = parse_stats_line(line).unwrap();
        assert_eq!(s.id, "abc123");
        assert_eq!(s.cpu, "1.24%");
        assert_eq!(s.mem, "256MiB / 8GiB");
    }

    #[test]
    fn stats_ignore_non_json_lines() {
        assert!(parse_stats_line("").is_none());
        assert!(parse_stats_line("not json").is_none());
        assert_eq!(parse_stats("nope\n").len(), 0);
    }
}
