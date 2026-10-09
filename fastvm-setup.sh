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
DE_SELECTION="${FASTVM_DE:-XFCE4}"
# Normalise to uppercase so CI lowercase values (xfce4, kde …) match correctly.
DE_UPPER="${DE_SELECTION^^}"

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

apt-get update -qq

case "$DE_UPPER" in
    "KDE"|"KDE PLASMA"|"KDE PLASMA (HEAVY)")
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
            systemsettings \
            firefox
         
        # Configure KDE
        sed -i 's/applications:org.kde.discover.desktop,/applications:org.kde.konsole.desktop,/g' \
            /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml || true
         
        cp /startwm-kde.sh /defaults/startwm.sh
        ;;
        
    "XFCE4"|"XFCE4 (LIGHTWEIGHT)")
        log_info "Installing XFCE4..."
        install_packages \
            mousepad \
            xfce4-terminal \
            xfce4 \
            xubuntu-default-settings \
            xubuntu-icon-theme \
            firefox
         
        # Remove screensaver
        rm -f /etc/xdg/autostart/xscreensaver.desktop
         
        cp /startwm-xfce.sh /defaults/startwm.sh
        ;;
        
    "I3"|"I3 (VERY LIGHTWEIGHT)")
        log_info "Installing i3..."
        install_packages \
            i3 \
            i3-wm \
            stterm
        
        update-alternatives --set x-terminal-emulator /usr/bin/st || true
        
        cp /startwm-i3.sh /defaults/startwm.sh
        ;;
        
    "GNOME"|"GNOME 42"|"GNOME 42 (VERY HEAVY)")
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
            yaru-* \
            firefox
        
        # Load dconf settings
        if [[ -f /jammy.dconf.conf ]]; then
            eval "$(dbus-launch)"
            dconf load / < /jammy.dconf.conf || log_warn "dconf load failed"
        else
            log_warn "dconf file not found"
        fi
        
        # Disable login1
        find /usr -type f -iname "*login1*" -exec mv {} {}.back \; 2>/dev/null
        
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
        
    "CINNAMON")
        log_info "Installing Cinnamon..."
        install_packages cinnamon firefox
        cp /startwm-cinnamon.sh /defaults/startwm.sh
        ;;
         
    "LXQT")
        log_info "Installing LXQT..."
        install_packages lxqt firefox
        cp /startwm-lxqt.sh /defaults/startwm.sh
        ;;

    "BUDGIE"|"BUDGIE DESKTOP")
        log_info "Installing Budgie Desktop..."
        install_packages \
            ubuntu-budgie-desktop \
            budgie-desktop \
            budgie-indicator-applet \
            firefox
        cp /startwm-budgie.sh /defaults/startwm.sh
        ;;

    "MATE"|"MATE DESKTOP")
        log_info "Installing MATE Desktop..."
        install_packages \
            mate-desktop-environment \
            mate-desktop-environment-extras \
            mate-terminal \
            mate-tweak \
            firefox
        # MATE ships an xscreensaver autostart that fights the browser session.
        rm -f /etc/xdg/autostart/xscreensaver.desktop
        cp /startwm-mate.sh /defaults/startwm.sh
        ;;

    "LXDE"|"LXDE (LIGHTWEIGHT)")
        log_info "Installing LXDE..."
        install_packages \
            lxde-core \
            lxterminal \
            firefox
        # LXDE is the classic ultra-light GTK2 desktop.
        rm -f /etc/xdg/autostart/xscreensaver.desktop
        cp /startwm-lxde.sh /defaults/startwm.sh
        ;;

    "FLUXBOX"|"FLUXBOX (VERY LIGHTWEIGHT)")
        log_info "Installing Fluxbox..."
        install_packages \
            fluxbox \
            xterm \
            firefox
        cp /startwm-fluxbox.sh /defaults/startwm.sh
        ;;

    "UNITY")
        log_info "Installing Unity..."
        install_packages \
            ubuntu-unity-desktop \
            firefox
        # Unity pulls in LightDM, but KasmVNC owns session startup.
        cp /startwm-unity.sh /defaults/startwm.sh
        ;;

    "UBUNTU STUDIO"|"UBUNTUSTUDIO"|"UBUNTU-STUDIO")
        log_info "Installing Ubuntu Studio desktop flavor (KDE Plasma based)..."
        install_packages \
            ubuntustudio-desktop \
            firefox
        # Ubuntu Studio is a KDE Plasma flavor; reuse the KDE session launcher.
        cp /startwm-kde.sh /defaults/startwm.sh
        ;;

    "ENLIGHTENMENT"|"ENLIGHTENMENT (EYE CANDY)")
        log_info "Installing Enlightenment..."
        install_packages \
            enlightenment \
            terminology \
            firefox
        # Enlightenment is a lightweight compositing desktop; dbus-launch is
        # used by the session launcher so make sure it is present.
        install_packages dbus-x11
        cp /startwm-enlightenment.sh /defaults/startwm.sh
        ;;

    "ICEWM"|"ICEWM (VERY LIGHTWEIGHT)")
        log_info "Installing IceWM..."
        install_packages \
            icewm \
            xterm \
            firefox
        cp /startwm-icewm.sh /defaults/startwm.sh
        ;;

    "AWESOME"|"AWESOME (TILING)")
        log_info "Installing awesome WM..."
        install_packages \
            awesome \
            awesome-extra \
            rxvt-unicode \
            firefox
        # Register urxvt as the terminal for menus/app launchers that expect one.
        update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/urxvt 40 || true
        update-alternatives --set x-terminal-emulator /usr/bin/urxvt || true
        cp /startwm-awesome.sh /defaults/startwm.sh
        ;;

    "BSPWM"|"BSPWM (TILING)")
        log_info "Installing bspwm tiling window manager..."
        install_packages \
            bspwm \
            sxhkd \
            dmenu \
            xterm \
            firefox
        # Seed the default bspwm/sxhkd configs so the first session is usable.
        cp /etc/xdg/bspwm/bspwmrc /defaults/bspwmrc 2>/dev/null || true
        cp /etc/xdg/sxhkd/sxhkdrc /defaults/sxhkdrc 2>/dev/null || true
        cp /startwm-bspwm.sh /defaults/startwm.sh
        ;;

    "GNOME-FLASHBACK"|"GNOME FLASHBACK"|"FLASHBACK"|"GNOME FLASHBACK (CLASSIC)")
        log_info "Installing GNOME Flashback (classic panel) desktop..."
        install_packages \
            gnome-session-flashback \
            gnome-flashback \
            gnome-panel \
            gnome-terminal \
            metacity \
            dbus-x11 \
            firefox
        # Flashback is a GNOME session and reads dconf/gsettings.
        cp /startwm-gnome-flashback.sh /defaults/startwm.sh
        ;;

    "WMAKER"|"WINDOW MAKER"|"WINDOWMAKER"|"WINDOW MAKER (MINIMAL)")
        log_info "Installing Window Maker..."
        install_packages \
            wmaker \
            xterm \
            firefox
        cp /startwm-wmaker.sh /defaults/startwm.sh
        ;;

    "UKUI"|"UKUI DESKTOP")
        log_info "Installing UKUI Desktop (Ubuntu Kylin desktop)..."
        # ukui-settings-daemon's postinst launches a Qt GUI helper (save-param)
        # whenever DISPLAY is set, which aborts in the headless build. Blank
        # DISPLAY for the install so dpkg can configure the package, then
        # restore it so later layers are unaffected.
        export DISPLAY=""
        install_packages \
            ukui-desktop-environment \
            ukui-session-manager \
            ukui-panel \
            ukui-menu \
            peony \
            dbus-x11 \
            firefox
        unset DISPLAY
        cp /startwm-ukui.sh /defaults/startwm.sh
        ;;

    "SINGLEAPP")
        # Single-app mode: minimal openbox, no full desktop environment
        # The specific app is installed later via installapps-parallel.sh
        log_info "Single-app mode — installing openbox..."
        install_packages openbox
        cp /startwm-singleapp.sh /defaults/startwm.sh
        ;;

    "FASTVM-OS"|"FASTVM OS")
        # FastVM OS uses its own lightweight shell instead of XFCE.
        log_info "Installing the FastVM OS desktop shell..."
        install_packages \
            openbox \
            tint2 \
            rofi \
            xterm \
            firefox
        cp /startwm-fastvm-os.sh /defaults/startwm.sh
        ;;
    "PEAROS"|"PEAR OS"|"PEAR")
        log_info "Installing Pear OS desktop environment..."
        install_packages \
            pear-desktop \
            pear-artwork \
            xterm \
            firefox
    # Copy the appropriate session launcher
        cp /startwm-pearos.sh /defaults/startwm.sh
        ;;

    *)
        log_error "Unknown desktop environment: $DE_SELECTION (normalised: $DE_UPPER)"
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
rm -f /startwm-kde.sh /startwm-i3.sh /startwm-xfce.sh /startwm-gnome.sh \
      /startwm-cinnamon.sh /startwm-lxqt.sh /startwm-budgie.sh /startwm-singleapp.sh \
      /startwm-mate.sh /startwm-lxde.sh /startwm-fluxbox.sh /startwm-unity.sh \
      /startwm-enlightenment.sh /startwm-icewm.sh /startwm-awesome.sh /startwm-ukui.sh \
      /startwm-bspwm.sh /startwm-gnome-flashback.sh /startwm-wmaker.sh \
      /startwm-pearos.sh \
      2>/dev/null || true

log_info "Desktop Environment setup complete!"
