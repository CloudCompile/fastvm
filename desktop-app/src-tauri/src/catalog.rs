//! Image catalog and marketplace model.
//!
//! Pure data and pure functions only - no I/O, no Docker. This keeps the
//! marketplace listing and the `docker run` argument builder unit-testable.
//!
//! Keep the desktop/preset/flavor lists in sync with the build matrix in
//! `.github/workflows/build-images.yml`. `scripts/verify-catalog.js` checks it.

use serde::Serialize;

/// Registry prefix for every published image.
pub const REGISTRY: &str = "ghcr.io/cloudcompile/fastvm";

/// Port the streamed desktop listens on inside the container.
pub const DESKTOP_PORT: u16 = 3000;
/// Port the management dashboard listens on inside the container.
pub const DASHBOARD_PORT: u16 = 8099;

/// Every published desktop environment.
pub const DESKTOPS: &[&str] = &[
    "xfce4", "kde", "gnome", "cinnamon", "lxqt", "i3", "budgie", "mate", "lxde",
    "fluxbox", "unity", "enlightenment", "icewm", "awesome", "ukui", "bspwm",
    "gnome-flashback", "wmaker", "herbstluftwm", "jwm", "fvwm", "xmonad", "sugar",
    "dwm", "ratpoison", "blackbox", "pop-os", "pekwm", "spectrwm", "sawfish",
    "openbox", "afterstep", "ctwm", "twm", "nixos", "pearos",
];

/// Every published preset overlay.
pub const PRESETS: &[&str] = &[
    "none", "minimal", "gaming", "development", "office", "content-creation",
];

/// Ultra-minimal single-application images.
pub const SINGLE_APPS: &[&str] = &["browser", "discord", "vscode", "terminal"];

/// Distro-flavor images (each publishes a single `<flavor>-latest` tag).
pub const FLAVORS: &[&str] = &[
    "fastvm-os", "ubuntu-studio", "ubuntu-kylin", "ubuntu-budgie",
    "ubuntu-edubuntu", "xubuntu", "lubuntu", "kubuntu", "ubuntu-mate",
    "ubuntu-unity", "pop-os", "linuxmint", "kali", "parrot", "nixos", "pearos",
];

/// `<desktop>-<preset>-latest`.
pub fn desktop_tag(desktop: &str, preset: &str) -> Result<String, String> {
    if !DESKTOPS.contains(&desktop) {
        return Err(format!("unknown desktop: {desktop}"));
    }
    if !PRESETS.contains(&preset) {
        return Err(format!("unknown preset: {preset}"));
    }
    Ok(format!("{desktop}-{preset}-latest"))
}

/// `<flavor>-latest`.
pub fn flavor_tag(flavor: &str) -> Result<String, String> {
    if !FLAVORS.contains(&flavor) {
        return Err(format!("unknown flavor: {flavor}"));
    }
    Ok(format!("{flavor}-latest"))
}

/// `<name>-latest`.
pub fn single_app_tag(name: &str) -> Result<String, String> {
    if !SINGLE_APPS.contains(&name) {
        return Err(format!("unknown single-app image: {name}"));
    }
    Ok(format!("{name}-latest"))
}

/// Human label for a desktop token (`xfce4` -> `XFCE4`).
pub fn desktop_label(desktop: &str) -> String {
    match desktop {
        "xfce4" => "XFCE4",
        "kde" => "KDE Plasma",
        "gnome" => "GNOME",
        "cinnamon" => "Cinnamon",
        "lxqt" => "LXQt",
        "i3" => "i3",
        "budgie" => "Budgie",
        "mate" => "MATE",
        "lxde" => "LXDE",
        "fluxbox" => "Fluxbox",
        "unity" => "Unity",
        "enlightenment" => "Enlightenment",
        "icewm" => "IceWM",
        "awesome" => "Awesome",
        "ukui" => "UKUI",
        "bspwm" => "bspwm",
        "gnome-flashback" => "GNOME Flashback",
        "wmaker" => "Window Maker",
        "herbstluftwm" => "herbstluftwm",
        "jwm" => "JWM",
        "fvwm" => "FVWM",
        "xmonad" => "xmonad",
        "sugar" => "Sugar",
        "dwm" => "dwm",
        "ratpoison" => "Ratpoison",
        "blackbox" => "Blackbox",
        "pop-os" => "Pop!_OS",
        "pekwm" => "PekWM",
        "spectrwm" => "spectrwm",
        "sawfish" => "Sawfish",
        "openbox" => "Openbox",
        "afterstep" => "AfterStep",
        "ctwm" => "CTWM",
        "twm" => "twm",
        "nixos" => "NixOS",
        "pearos" => "pearOS",
        other => other,
    }
    .to_string()
}

/// Human label for a preset token (`content-creation` -> `Content Creation`).
pub fn preset_label(preset: &str) -> String {
    match preset {
        "none" => "",
        "minimal" => "Minimal",
        "gaming" => "Gaming",
        "development" => "Development",
        "office" => "Office",
        "content-creation" => "Content Creation",
        other => other,
    }
    .to_string()
}

/// Human label for a distro flavor token (`ubuntu-studio` -> `Ubuntu Studio`).
pub fn flavor_label(flavor: &str) -> String {
    match flavor {
        "fastvm-os" => "FastVM OS",
        "ubuntu-studio" => "Ubuntu Studio",
        "ubuntu-kylin" => "Ubuntu Kylin",
        "ubuntu-budgie" => "Ubuntu Budgie",
        "ubuntu-edubuntu" => "Ubuntu Edubuntu",
        "xubuntu" => "Xubuntu",
        "lubuntu" => "Lubuntu",
        "kubuntu" => "Kubuntu",
        "ubuntu-mate" => "Ubuntu MATE",
        "ubuntu-unity" => "Ubuntu Unity",
        "pop-os" => "Pop!_OS",
        "linuxmint" => "Linux Mint",
        "kali" => "Kali Linux",
        "parrot" => "Parrot Security OS",
        "nixos" => "NixOS",
        "pearos" => "pearOS",
        other => other,
    }
    .to_string()
}

/// Human label for a single-app token (`vscode` -> `VSCodium only`).
pub fn single_app_label(name: &str) -> String {
    match name {
        "browser" => "Browser only",
        "discord" => "Discord only",
        "vscode" => "VSCodium only",
        "terminal" => "Terminal only",
        other => other,
    }
    .to_string()
}

/// Marketplace category for a preset overlay.
pub fn preset_category(preset: &str) -> &'static str {
    match preset {
        "gaming" => "Gaming",
        "development" => "Development",
        "office" => "Office",
        "content-creation" => "Content Creation",
        "minimal" => "Minimal",
        _ => "Desktops",
    }
}

/// Suggested RAM for a preset overlay.
pub fn preset_ram(preset: &str) -> &'static str {
    match preset {
        "gaming" => "4 GB",
        "content-creation" => "3 GB",
        "development" | "office" => "2 GB",
        "minimal" => "512 MB",
        _ => "1 GB",
    }
}

/// Tags highlighted in the marketplace (the curated subset).
pub const FEATURED_TAGS: &[&str] = &[
    "xfce4-minimal-latest",
    "kde-gaming-latest",
    "xfce4-development-latest",
    "kde-content-creation-latest",
    "kali-latest",
    "pearos-latest",
];


/// Fully-qualified image reference.
pub fn image_ref(tag: &str) -> String {
    format!("{REGISTRY}:{tag}")
}

/// Total published variants (desktop x preset + single-app + flavor).
pub fn variant_count() -> usize {
    DESKTOPS.len() * PRESETS.len() + SINGLE_APPS.len() + FLAVORS.len()
}

/// Build a listing for a `desktop` x `preset` image.
pub fn desktop_app(desktop: &str, preset: &str) -> App {
    let tag = desktop_tag(desktop, preset).unwrap_or_default();
    let d = desktop_label(desktop);
    let p = preset_label(preset);
    let name = if p.is_empty() { d.clone() } else { format!("{d} · {p}") };
    let gpu = preset == "gaming";
    let tagline = match preset {
        "gaming" => format!("{d} tuned for gaming — Steam, Wine, and DXVK"),
        "development" => format!("{d} with common developer toolchains preinstalled"),
        "office" => format!("{d} with document and productivity apps"),
        "content-creation" => format!("{d} with creative tooling"),
        "minimal" => format!("{d}, trimmed to the essentials"),
        _ => format!("{d}, stock configuration"),
    };
    App {
        id: tag.clone(),
        name,
        tagline,
        category: preset_category(preset).to_string(),
        kind: if preset == "none" { "desktop" } else { "preset" }.to_string(),
        desktop: Some(desktop.to_string()),
        preset: Some(preset.to_string()),
        flavor: None,
        ram: preset_ram(preset).to_string(),
        gpu,
        featured: FEATURED_TAGS.contains(&tag.as_str()),
        image: image_ref(&tag),
    }
}

/// Build a listing for a distro-flavor image.
pub fn flavor_app(flavor: &str) -> App {
    let tag = flavor_tag(flavor).unwrap_or_default();
    App {
        id: tag.clone(),
        name: flavor_label(flavor),
        tagline: format!("{} distro experience", flavor_label(flavor)),
        category: "Distros".to_string(),
        kind: "flavor".to_string(),
        desktop: None,
        preset: None,
        flavor: Some(flavor.to_string()),
        ram: "1.5 GB".to_string(),
        gpu: false,
        featured: FEATURED_TAGS.contains(&tag.as_str()),
        image: image_ref(&tag),
    }
}

/// Build a listing for a single-application image.
pub fn single_app(name: &str) -> App {
    let tag = single_app_tag(name).unwrap_or_default();
    App {
        id: tag.clone(),
        name: single_app_label(name),
        tagline: "A single app, no desktop environment".to_string(),
        category: "Minimal".to_string(),
        kind: "single".to_string(),
        desktop: None,
        preset: None,
        flavor: None,
        ram: "256 MB".to_string(),
        gpu: false,
        featured: FEATURED_TAGS.contains(&tag.as_str()),
        image: image_ref(&tag),
    }
}

/// Every published variant (236): desktop x preset + flavors + single apps.
pub fn all_variants() -> Vec<App> {
    let mut out = Vec::with_capacity(variant_count());
    for d in DESKTOPS {
        for p in PRESETS {
            out.push(desktop_app(d, p));
        }
    }
    for f in FLAVORS {
        out.push(flavor_app(f));
    }
    for s in SINGLE_APPS {
        out.push(single_app(s));
    }
    out
}

/// Look up one variant by image tag.
#[cfg(test)]
pub fn find_app(tag: &str) -> Option<App> {
    all_variants().into_iter().find(|a| a.id == tag)
}

/// A marketplace listing.
#[derive(Clone, Debug, Serialize)]
pub struct App {
    /// Image tag, e.g. `pearos-none-latest`.
    pub id: String,
    pub name: String,
    pub tagline: String,
    pub category: String,
    /// `desktop`, `preset`, `flavor`, or `single`.
    pub kind: String,
    pub desktop: Option<String>,
    pub preset: Option<String>,
    pub flavor: Option<String>,
    pub ram: String,
    pub gpu: bool,
    pub featured: bool,
    pub image: String,
}

/// Arguments for a one-click deploy.
#[derive(Clone, Debug, Default)]
pub struct RunSpec {
    pub image: String,
    pub host_port: u16,
    pub dashboard_port: u16,
    pub name: Option<String>,
    pub shm_size: Option<String>,
    pub memory: Option<String>,
    pub cpus: Option<String>,
    pub gpu: bool,
    pub env: Vec<String>,
    pub volumes: Vec<String>,
}

/// Build the `docker run` argument vector (without the leading `docker`).
pub fn build_run_args(spec: &RunSpec) -> Result<Vec<String>, String> {
    if spec.image.is_empty() {
        return Err("image is required".to_string());
    }
    let host_port = if spec.host_port == 0 { DESKTOP_PORT } else { spec.host_port };
    let mut args = vec!["run".to_string(), "-d".to_string()];
    if let Some(name) = &spec.name {
        args.push("--name".into());
        args.push(name.clone());
    }
    args.push("-p".into());
    args.push(format!("{host_port}:{DESKTOP_PORT}"));
    if spec.dashboard_port != 0 {
        args.push("-p".into());
        args.push(format!("{}:{DASHBOARD_PORT}", spec.dashboard_port));
    }
    if let Some(shm) = &spec.shm_size {
        args.push("--shm-size".into());
        args.push(shm.clone());
    }
    if let Some(mem) = &spec.memory {
        args.push("--memory".into());
        args.push(mem.clone());
    }
    if let Some(cpus) = &spec.cpus {
        args.push("--cpus".into());
        args.push(cpus.clone());
    }
    if spec.gpu {
        args.push("--device".into());
        args.push("/dev/dri".into());
    }
    for e in &spec.env {
        args.push("-e".into());
        args.push(e.clone());
    }
    for v in &spec.volumes {
        args.push("-v".into());
        args.push(v.clone());
    }
    args.push(spec.image.clone());
    Ok(args)
}

/// Curated, hand-written listings. These override the generated name/tagline
/// for the highlighted apps so the marketplace reads well.
pub fn curated() -> Vec<App> {
    fn app(
        id: &str,
        name: &str,
        tagline: &str,
        category: &str,
        kind: &str,
        ram: &str,
        gpu: bool,
        featured: bool,
    ) -> App {
        App {
            id: id.to_string(),
            name: name.to_string(),
            tagline: tagline.to_string(),
            category: category.to_string(),
            kind: kind.to_string(),
            desktop: None,
            preset: None,
            flavor: None,
            ram: ram.to_string(),
            gpu,
            featured,
            image: image_ref(id),
        }
    }
    fn desktop(mut a: App, d: &str) -> App {
        a.desktop = Some(d.to_string());
        a
    }
    fn preset(mut a: App, p: &str) -> App {
        a.preset = Some(p.to_string());
        a
    }
    fn flavor(mut a: App, f: &str) -> App {
        a.flavor = Some(f.to_string());
        a
    }

    vec![
        preset(desktop(app("xfce4-minimal-latest", "XFCE4 Minimal", "Fast, familiar, and light on RAM", "Desktops", "desktop", "512 MB", false, true), "xfce4"), "minimal"),
        preset(desktop(app("kde-none-latest", "KDE Plasma", "A modern, highly configurable Qt desktop", "Desktops", "desktop", "1.5 GB", false, false), "kde"), "none"),
        preset(desktop(app("gnome-none-latest", "GNOME", "The sleek, opinionated desktop", "Desktops", "desktop", "2 GB", false, false), "gnome"), "none"),
        preset(desktop(app("cinnamon-minimal-latest", "Cinnamon", "Familiar Windows-like layout", "Desktops", "desktop", "1 GB", false, false), "cinnamon"), "minimal"),
        preset(desktop(app("i3-minimal-latest", "i3 (tiling)", "Keyboard-driven tiling window manager", "Desktops", "desktop", "128 MB", false, false), "i3"), "minimal"),
        preset(desktop(app("lxqt-minimal-latest", "LXQt", "Barely-there Qt desktop", "Desktops", "desktop", "256 MB", false, false), "lxqt"), "minimal"),

        preset(desktop(app("kde-gaming-latest", "Gaming Rig", "KDE + Steam + Wine, CPU-rendered", "Gaming", "preset", "4 GB", true, true), "kde"), "gaming"),
        preset(desktop(app("xfce4-development-latest", "Developer Workstation", "XFCE4 with common toolchains preinstalled", "Development", "preset", "2 GB", false, true), "xfce4"), "development"),
        preset(desktop(app("kde-content-creation-latest", "Creator Studio", "KDE with creative tooling", "Content Creation", "preset", "3 GB", false, true), "kde"), "content-creation"),
        preset(desktop(app("xfce4-office-latest", "Office Suite", "XFCE4 with document and productivity apps", "Office", "preset", "2 GB", false, false), "xfce4"), "office"),

        flavor(app("kali-latest", "Kali Linux", "Security tooling on an XFCE4 base", "Security", "flavor", "2 GB", false, true), "kali"),
        flavor(app("parrot-latest", "Parrot Security OS", "Security and privacy toolkit, MATE", "Security", "flavor", "2 GB", false, false), "parrot"),

        flavor(app("pearos-latest", "pearOS", "A macOS-inspired KDE Plasma desktop", "Distros", "flavor", "1.5 GB", false, true), "pearos"),
        flavor(app("pop-os-latest", "Pop!_OS", "System76's GNOME experience", "Distros", "flavor", "2 GB", false, false), "pop-os"),
        flavor(app("nixos-latest", "NixOS", "Openbox shell with the Nix package manager", "Distros", "flavor", "256 MB", false, false), "nixos"),
        flavor(app("linuxmint-latest", "Linux Mint", "Cinnamon with the Mint feel", "Distros", "flavor", "1 GB", false, false), "linuxmint"),
        flavor(app("ubuntu-studio-latest", "Ubuntu Studio", "KDE with creative tooling", "Content Creation", "flavor", "3 GB", false, false), "ubuntu-studio"),
        flavor(app("kubuntu-latest", "Kubuntu", "Ubuntu with KDE Plasma", "Distros", "flavor", "1.5 GB", false, false), "kubuntu"),
        flavor(app("xubuntu-latest", "Xubuntu", "Ubuntu with XFCE4", "Distros", "flavor", "512 MB", false, false), "xubuntu"),
        flavor(app("lubuntu-latest", "Lubuntu", "Ubuntu with the light LXQt desktop", "Distros", "flavor", "256 MB", false, false), "lubuntu"),
        flavor(app("ubuntu-mate-latest", "Ubuntu MATE", "Ubuntu with the MATE desktop", "Distros", "flavor", "512 MB", false, false), "ubuntu-mate"),
        flavor(app("ubuntu-budgie-latest", "Ubuntu Budgie", "Ubuntu with the Budgie desktop", "Distros", "flavor", "1 GB", false, false), "ubuntu-budgie"),
        flavor(app("ubuntu-kylin-latest", "Ubuntu Kylin", "Ubuntu with the UKUI desktop", "Distros", "flavor", "1 GB", false, false), "ubuntu-kylin"),
        flavor(app("ubuntu-unity-latest", "Ubuntu Unity", "The classic Unity shell", "Distros", "flavor", "1 GB", false, false), "ubuntu-unity"),
        flavor(app("ubuntu-edubuntu-latest", "Ubuntu Edubuntu", "GNOME tuned for education", "Distros", "flavor", "2 GB", false, false), "ubuntu-edubuntu"),
        flavor(app("fastvm-os-latest", "FastVM OS", "The FastVM appliance shell", "Distros", "flavor", "1 GB", false, false), "fastvm-os"),

        app("browser-latest", "Browser only", "Just a browser, no desktop", "Minimal", "single", "256 MB", false, false),
        app("discord-latest", "Discord only", "Just Discord, no desktop", "Minimal", "single", "256 MB", false, false),
        app("vscode-latest", "VSCodium only", "Just the editor, no desktop", "Minimal", "single", "256 MB", false, false),
        app("terminal-latest", "Terminal only", "A bare terminal, no desktop", "Minimal", "single", "128 MB", false, false),
    ]
}

/// The marketplace listing: every published variant, with the curated entries'
/// hand-written names and taglines preferred where they overlap.
pub fn marketplace() -> Vec<App> {
    let curated = curated();
    let mut out = all_variants();
    for app in out.iter_mut() {
        if let Some(over) = curated.iter().find(|c| c.id == app.id) {
            app.name = over.name.clone();
            app.tagline = over.tagline.clone();
            app.category = over.category.clone();
            app.ram = over.ram.clone();
            app.gpu = over.gpu;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_sizes() {
        assert_eq!(DESKTOPS.len(), 36);
        assert_eq!(PRESETS.len(), 6);
        assert_eq!(FLAVORS.len(), 16);
        assert_eq!(SINGLE_APPS.len(), 4);
    }

    #[test]
    fn variant_count_matches_readme() {
        assert_eq!(variant_count(), 236);
    }

    #[test]
    fn tags_build_and_validate() {
        assert_eq!(desktop_tag("pearos", "gaming").unwrap(), "pearos-gaming-latest");
        assert_eq!(flavor_tag("kali").unwrap(), "kali-latest");
        assert_eq!(single_app_tag("browser").unwrap(), "browser-latest");
        assert!(desktop_tag("nope", "none").is_err());
        assert!(desktop_tag("xfce4", "nope").is_err());
        assert!(flavor_tag("nope").is_err());
    }

    #[test]
    fn default_run_args() {
        let spec = RunSpec { image: image_ref("xfce4-none-latest"), ..Default::default() };
        assert_eq!(
            build_run_args(&spec).unwrap(),
            vec!["run", "-d", "-p", "3000:3000", "ghcr.io/cloudcompile/fastvm:xfce4-none-latest"]
        );
    }

    #[test]
    fn full_run_args() {
        let spec = RunSpec {
            image: "x:pearos-latest".into(),
            host_port: 3000,
            dashboard_port: 3001,
            name: Some("FastVM-pearOS".into()),
            shm_size: Some("4gb".into()),
            gpu: true,
            env: vec!["TZ=Etc/UTC".into()],
            ..Default::default()
        };
        assert_eq!(
            build_run_args(&spec).unwrap(),
            vec![
                "run", "-d", "--name", "FastVM-pearOS", "-p", "3000:3000", "-p", "3001:8099",
                "--shm-size", "4gb", "--device", "/dev/dri", "-e", "TZ=Etc/UTC", "x:pearos-latest"
            ]
        );
    }

    #[test]
    fn run_args_require_image() {
        assert!(build_run_args(&RunSpec::default()).is_err());
    }

    #[test]
    fn marketplace_is_populated_and_consistent() {
        let apps = marketplace();
        assert!(apps.len() >= 25, "marketplace should list at least 25 apps");
        assert!(apps.iter().any(|a| a.id == "pearos-latest"));
        assert!(apps.iter().any(|a| a.featured));
        // Every listed image must be a real, validated tag.
        for a in &apps {
            assert!(a.image.starts_with(REGISTRY));
            match a.kind.as_str() {
                "desktop" => {
                    desktop_tag(a.desktop.as_deref().unwrap(), a.preset.as_deref().unwrap()).unwrap();
                }
                "preset" => {
                    desktop_tag(a.desktop.as_deref().unwrap(), a.preset.as_deref().unwrap()).unwrap();
                }
                "flavor" => {
                    flavor_tag(a.flavor.as_deref().unwrap()).unwrap();
                }
                "single" => {
                    let name = a.id.strip_suffix("-latest").unwrap();
                    single_app_tag(name).unwrap();
                }
                other => panic!("unexpected kind: {other}"),
            }
        }
    }

    #[test]
    fn marketplace_lists_every_variant_exactly_once() {
        let apps = marketplace();
        assert_eq!(apps.len(), variant_count());
        let mut ids: Vec<&str> = apps.iter().map(|a| a.id.as_str()).collect();
        ids.sort_unstable();
        let before = ids.len();
        ids.dedup();
        assert_eq!(before, ids.len(), "image tags must be unique");
    }

    #[test]
    fn curated_names_win_over_generated_ones() {
        let apps = marketplace();
        let gaming = apps.iter().find(|a| a.id == "kde-gaming-latest").unwrap();
        assert_eq!(gaming.name, "Gaming Rig");
        assert!(gaming.gpu);
        let pear = apps.iter().find(|a| a.id == "pearos-latest").unwrap();
        assert_eq!(pear.name, "pearOS");
        // A generated variant keeps its composed name.
        let plain = apps.iter().find(|a| a.id == "spectrwm-none-latest").unwrap();
        assert_eq!(plain.name, "spectrwm");
        let min = apps.iter().find(|a| a.id == "spectrwm-minimal-latest").unwrap();
        assert_eq!(min.name, "spectrwm · Minimal");
    }

    #[test]
    fn find_app_resolves_generated_and_flavor_tags() {
        assert!(find_app("spectrwm-office-latest").is_some());
        assert!(find_app("kali-latest").is_some());
        assert!(find_app("nope-latest").is_none());
    }

    #[test]
    fn labels_read_well() {
        assert_eq!(desktop_label("pearos"), "pearOS");
        assert_eq!(desktop_label("gnome-flashback"), "GNOME Flashback");
        assert_eq!(preset_label("content-creation"), "Content Creation");
        assert_eq!(preset_label("none"), "");
        assert_eq!(flavor_label("ubuntu-studio"), "Ubuntu Studio");
        assert_eq!(single_app_label("vscode"), "VSCodium only");
    }
}
