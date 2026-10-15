//! FastVM desktop marketplace.
//!
//! The Rust side owns the image catalog, the Docker CLI calls, and the
//! one-click deploy flow. The frontend (a plain HTML/CSS/JS page) talks to it
//! through the commands registered below.

mod catalog;
mod commands;
mod docker;
mod gpu;

/// Build and run the Tauri application.
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            commands::marketplace,
            commands::detect_gpu,
            commands::docker_host,
            commands::preview_run_args,
            commands::preview_compose,
            commands::gpu_verify,
            commands::docker_version,
            commands::list_instances,
            commands::container_stats,
            commands::deploy,
            commands::stop_instance,
            commands::stop_all_instances,
            commands::remove_instance,
            commands::instance_logs,
        ])
        .run(tauri::generate_context!())
        .expect("error while running the FastVM desktop app");
}
