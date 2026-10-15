#!/bin/bash
# FastVM GPU session environment.
#
# Sourced by the desktop session (fastvm-setup.sh prepends a source line to
# /defaults/startwm.sh) so applications and the window manager can reach the GPU
# when one is mapped into the container. Safe to source with no GPU: it detects
# the DRM render node and does nothing when there is none.
#
# Real GPU rasterization for the desktop itself is provided by KasmVNC's DRI3
# support (the base image passes -hw3d when /dev/dri is present). This script
# only sets the per-session userspace variables that let apps use the GPU, and
# is opt-in via FASTVM_GPU_HW because DRI3 requires desktop compositing to be
# disabled. See docs/gpu.md.
#
#     source gpu-session-env.sh    # apply (used by startwm)
#     gpu-session-env.sh --print   # show what would be exported

# Resolve the DRM render node: honour KasmVNC's DRINODE, else the first node.
fastvm_gpu_render_node() {
    if [[ -n "${DRINODE:-}" && -e "${DRINODE}" ]]; then
        printf '%s\n' "${DRINODE}"
        return 0
    fi
    ls /dev/dri/renderD* 2>/dev/null | head -n1 || true
    return 0
}

# Vendor of a render node via sysfs (intel|amd|nvidia|unknown).
fastvm_gpu_vendor() {
    local node="$1" vf
    vf="/sys/class/drm/$(basename "$node")/device/vendor"
    if [[ ! -r "$vf" ]]; then
        echo unknown
        return 0
    fi
    case "$(cat "$vf" 2>/dev/null)" in
        0x8086) echo intel ;;
        0x1002) echo amd ;;
        0x10de) echo nvidia ;;
        *) echo unknown ;;
    esac
}

# True when the detected GPU is a compute-only accelerator (see gpu-detect.sh).
fastvm_gpu_compute_only() {
    local f="${FASTVM_DATA_ROOT:-/config}/.fastvm/gpu.json"
    [[ -r "$f" ]] || return 1
    command -v jq >/dev/null 2>&1 || return 1
    [[ "$(jq -r '.compute_only // false' "$f" 2>/dev/null)" == "true" ]]
}

fastvm_gpu_apply() {
    [[ "${FASTVM_GPU_HW:-false}" == "true" ]] || return 0
    local node vendor
    node="$(fastvm_gpu_render_node)"
    [[ -n "$node" ]] || return 0

    # Compute-only accelerators (e.g. AMD Instinct / CDNA) have no graphics
    # engine: there is no DRI3 to unlock and no VA-API to export. Leave the
    # desktop on llvmpipe and keep the compositor; ROCm compute still works.
    fastvm_gpu_compute_only && return 0

    vendor="$(fastvm_gpu_vendor "$node")"

    # Pick the GPU by render node (helps on multi-GPU hosts).
    export LIBVA_DRM_DEVICE="$node"

    if [[ "$vendor" == "nvidia" ]]; then
        # The closed-source NVIDIA driver has no DRI3. Reach the GPU through
        # Zink, which translates OpenGL to Vulkan.
        export MESA_LOADER_DRIVER_OVERRIDE=zink
        export GALLIUM_DRIVER=zink
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        # No DRI3 on NVIDIA, so compositing can stay on.
        return 0
    fi

    # Open-source driver: KasmVNC DRI3 can now rasterize the desktop. That only
    # helps if the window manager stops compositing (DRI3 cannot composite), so
    # disable the compositor for the desktops that support it.
    fastvm_gpu_disable_compositing
    return 0
}

# Turn off desktop compositing for desktops that allow it. Without this the WM
# keeps rendering through llvmpipe even when DRI3 is active. No-op when
# FASTVM_GPU_KEEP_COMPOSITING=true, and for desktops that cannot disable it.
fastvm_gpu_disable_compositing() {
    [[ "${FASTVM_GPU_KEEP_COMPOSITING:-false}" == "true" ]] && return 0
    local de="${FASTVM_DE:-}" home="${HOME:-/config}"
    de="${de^^}"
    case "$de" in
        XFCE*)
            if command -v xfconf-query >/dev/null 2>&1; then
                xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false >/dev/null 2>&1 || true
            fi
            ;;
        KDE*|PLASMA*)
            if command -v kwriteconfig6 >/dev/null 2>&1; then
                kwriteconfig6 --file kwinrc --group Compositing --key Enabled false >/dev/null 2>&1 || true
            elif command -v kwriteconfig5 >/dev/null 2>&1; then
                kwriteconfig5 --file kwinrc --group Compositing --key Enabled false >/dev/null 2>&1 || true
            fi
            ;;
        MATE*)
            if command -v gsettings >/dev/null 2>&1; then
                gsettings set org.mate.Marco.general compositing-manager false >/dev/null 2>&1 || true
            fi
            ;;
        *)
            # GNOME, Cinnamon, Budgie, Unity and others cannot disable
            # compositing; the desktop stays on llvmpipe by design.
            ;;
    esac
    return 0
}

# Apply the host performance profile (CPU/software-render tuning + compositor).
# No-op without perf-profile.sh; safe to source on any host.
fastvm_perf_apply() {
    local scripts="${FASTVM_SCRIPTS_DIR:-/fastvm-scripts}"
    [[ -x "${scripts}/perf-profile.sh" ]] || return 0
    FASTVM_DATA_ROOT="${FASTVM_DATA_ROOT:-/config}" "${scripts}/perf-profile.sh" apply >/dev/null 2>&1 || true
    local envf="${FASTVM_DATA_ROOT:-/config}/.fastvm/perf-env.sh"
    [[ -r "$envf" ]] && . "$envf"
    FASTVM_DATA_ROOT="${FASTVM_DATA_ROOT:-/config}" "${scripts}/perf-profile.sh" session >/dev/null 2>&1 || true
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Executed directly (not sourced).
    case "${1:-}" in
        --print)
            fastvm_gpu_apply
            fastvm_perf_apply
            env | grep -E '^(LIBVA_DRM_DEVICE|MESA_LOADER_DRIVER_OVERRIDE|GALLIUM_DRIVER|__GLX_VENDOR_LIBRARY_NAME|LIBGL_ALWAYS_SOFTWARE|LP_NUM_THREADS|FASTVM_PERF_ENCODE_THREADS|vblank_mode|__GL_SYNC_TO_VBLANK)=' | sort || true
            ;;
        *)
            fastvm_gpu_apply
            fastvm_perf_apply
            ;;
    esac
else
    # Sourced by startwm: apply immediately, no side effects on caller options.
    fastvm_gpu_apply
    fastvm_perf_apply
fi
