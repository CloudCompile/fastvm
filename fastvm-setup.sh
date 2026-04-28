#!/bin/bash
# FastVM Desktop Environment Setup Script
# Optimized with proper error handling and consolidated operations

set -euo pipefail

# =============================================================================
# Logging Functions
# =============================================================================
log_info() { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }
log_warn() { echo "[WARN] $*"; }

# =============================================================================
# Error Handler
# =============================================================================
trap 'log_error "Script failed at line $LINENO"' ERR

# =============================================================================
# Configuration
# =============================================================================
JSON_FILE="/options.json"
DE_SELECTION="${FASTVM_DE:-XFCE4}"

# =============================================================================
# Helper Functions
# =============================================================================

# Check if jq query returns true (optimized - no grep needed)
jq_check() {
    local query="$1"
    local file="$2"
    jq -e "$query" "$file" >/dev/null 2>&1
}

# Install packages with error handling
install_packages() {
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y "$@" || {
        log_error "Failed to install packages: $*"
        return 1
    }
}

# =============================================================================
# Desktop Environment Installation
# =============================================================================

log_info "Setting up Desktop Environment: $DE_SELECTION"

# Update package list once
echo "**** Updating package list ****"
apt-get update

case "$DE_SELECTION" in
    "KDE"|"KDE Plasma"|"KDE Plasma (Heavy)")
        log_info "Installing KDE Plasma..."
        install_packages \
            dolphin \
            gwenview \
            kde-config-gtk-style \
            kdialog \
            kfind \
            khotkeys \
            kio-extras \
            knewstuff-dialog \
            konsole \
            ksystemstats \
            kwin-addons \
            kwin-x11 \
            kwrite \
            plasma-desktop \
            plasma-workspace \
            qml-module-qt-labs-platform \
            systemsettings
        
        # Configure KDE
        sed -i 's/applications:org.kde.discover.desktop,/applications:org.kde.konsole.desktop,/g' \
            /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml || true
        
        cp /startwm-kde.sh /defaults/startwm.sh
        ;;
        
    "XFCE4"|"XFCE4 (Lightweight)")
        log_info "Installing XFCE4..."
        install_packages \
            mousepad \
            xfce4-terminal \
            xfce4 \
            xubuntu-default-settings \
            xubuntu-icon-theme
        
        # Remove screensaver
        rm -f /etc/xdg/autostart/xscreensaver.desktop
        
        cp /startwm-xfce.sh /defaults/startwm.sh
        ;;
        
    "I3"|"I3 (Very Lightweight)")
        log_info "Installing i3..."
        install_packages \
            i3 \
            i3-wm \
            stterm
        
        update-alternatives --set x-terminal-emulator /usr/bin/st || true
        
        cp /startwm-i3.sh /defaults/startwm.sh
        ;;
        
    "GNOME"|"GNOME 42"|"GNOME 42 (Very Heavy)")
        log_info "Installing GNOME..."
        install_packages \
            gnome-shell \
            gnome-shell-* \
            dbus-x11 \
            gnome-terminal \
            gnome-accessibility-themes \
            gnome-calculator \
            gnome-control-center* \
            gnome-desktop3-data \
            gnome-initial-setup \
            gnome-menus \
            gnome-text-editor \
            gnome-themes-extra* \
            gnome-user-docs \
            gnome-video-effects \
            gnome-tweaks \
            gnome-software \
            language-pack-en-base \
            mesa-utils \
            xterm \
            yaru-*
        
        # Load dconf settings
        if [[ -f /jammy.dconf.conf ]]; then
            export $(dbus-launch)
            dconf load / < /jammy.dconf.conf || log_warn "dconf load failed"
        else
            log_warn "dconf file not found"
        fi
        
        # Disable login1
        for file in $(find /usr -type f -iname "*login1*" 2>/dev/null); do
            mv -v "$file" "$file.back" || true
        done
        
        # Configure bashrc
        echo "sudo chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper" >> ~/.bashrc
        echo "sudo chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper" >> /config/.bashrc
        echo "export XDG_CURRENT_DESKTOP=GNOME" >> ~/.bashrc
        echo "export XDG_CURRENT_DESKTOP=GNOME" >> /config/.bashrc
        
        # Move sound panel
        mv -v /usr/share/applications/gnome-sound-panel.desktop \
            /usr/share/applications/gnome-sound-panel.desktop.back 2>/dev/null || true
        
        # Remove unnecessary packages
        apt-get remove -y \
            gnome-power-manager \
            gnome-bluetooth \
            gnome-software \
            gpaste \
            hijra-applet \
            gnome-shell-extension-hijra \
            mailnag \
            gnome-shell-mailnag \
            gnome-shell-pomodoro \
            gnome-shell-pomodoro-data 2>/dev/null || true
        
        cp /startwm-gnome.sh /defaults/startwm.sh
        ;;
        
    "Cinnamon")
        log_info "Installing Cinnamon..."
        install_packages cinnamon
        cp /startwm-cinnamon.sh /defaults/startwm.sh
        ;;
        
    "LXQT")
        log_info "Installing LXQT..."
        install_packages lxqt
        cp /startwm-lxqt.sh /defaults/startwm.sh
        ;;

    "Budgie"|"Budgie Desktop")
        log_info "Installing Budgie Desktop..."
        install_packages \
            ubuntu-budgie-desktop \
            budgie-desktop \
            budgie-indicator-applet
        cp /startwm-budgie.sh /defaults/startwm.sh
        ;;

    *)
        log_error "Unknown desktop environment: $DE_SELECTION"
        log_info "Falling back to XFCE4"
        install_packages \
            mousepad \
            xfce4-terminal \
            xfce4 \
            xubuntu-default-settings \
            xubuntu-icon-theme
        rm -f /etc/xdg/autostart/xscreensaver.desktop
        cp /startwm-xfce.sh /defaults/startwm.sh
        ;;
esac

# =============================================================================
# Finalize
# =============================================================================

chmod +x /defaults/startwm.sh

# Clean up start scripts
rm -f /startwm-kde.sh /startwm-i3.sh /startwm-xfce.sh /startwm-gnome.sh /startwm-cinnamon.sh /startwm-lxqt.sh /startwm-budgie.sh 2>/dev/null || true

log_info "Desktop Environment setup complete!"
