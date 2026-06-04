#!/usr/bin/env bash

# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3

set -euo pipefail

exit_on_error() {
    printf "\nERROR: %s\n" "$1" >&2
    exit 1
}

# Check for terminal
if [ ! -t 0 ]; then
    if command -v konsole >/dev/null 2>&1; then
        exec konsole -e "$0" "$@"
    elif command -v gnome-terminal >/dev/null 2>&1; then
        exec gnome-terminal -- "$0" "$@"
    elif command -v xterm >/dev/null 2>&1; then
        exec xterm -e "$0" "$@"
    fi
fi

# Setup
STEAMROOT="$HOME/.local/share/Steam"
STEAMHOME="$HOME/.steam"
RTARM64ROOT="$STEAMROOT/steamrtarm64"
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")

# Uninstall conflicting native packages
printf "\nChecking for conflicting system packages..\n"
if command -v apt-get &>/dev/null; then
    dpkg -l | grep -q "^ii  steam-launcher " && {
        printf "Found conflicting system steam package. Uninstalling..\n"
        sudo apt-get remove -y steam-launcher
    } || true
elif command -v dnf &>/dev/null; then
    (rpm -q steam || rpm -q steam-launcher) &>/dev/null && {
        printf "Found conflicting system steam package. Uninstalling..\n"
        sudo dnf remove -y steam steam-launcher
    } || true
elif command -v pacman &>/dev/null; then
    pacman -Qq steam &>/dev/null && {
        printf "Found conflicting system steam package. Uninstalling..\n"
        sudo pacman -Rns --noconfirm steam
    } || true
fi

# Cleanup pre-existing/orphaned steam desktop files
printf "Cleaning up old desktop shortcuts..\n"
for file in "$HOME/.local/share/applications/Steam.desktop" \
            "$HOME/.local/share/applications/steam.desktop" \
            "/usr/local/share/applications/Steam.desktop" \
            "/usr/local/share/applications/steam.desktop" \
            "/usr/share/applications/Steam.desktop" \
            "/usr/share/applications/steam.desktop" \
            "$DESKTOP_DIR/Steam.desktop" \
            "$DESKTOP_DIR/steam.desktop"; do
    if [ -f "$file" ]; then
        if [[ "$file" == /usr/* ]]; then
            sudo rm -f "$file"
        else
            rm -f "$file"
        fi
    fi
done

command -v update-desktop-database &>/dev/null && update-desktop-database "$HOME/.local/share/applications" &>/dev/null || true

# Check if either Steam directory exists
if [ -d "$STEAMROOT" ] || [ -d "$STEAMHOME" ]; then
    printf "\nSteam directories already exist.\n"
    read -p "A clean installation is recommended. Would you like to delete them now? (y/N): " choice
    case "$choice" in 
        [yY][eE][sS]|[yY]) 
            printf "\nDeleting %s and %s...\n" "$STEAMROOT" "$STEAMHOME"
            rm -rf "$STEAMROOT"
            rm -rf "$STEAMHOME"
			# Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
            ;;
        *)
            printf "\nContinuing with dirty installation..\n"
            shopt -s extglob dotglob
            eval "rm -rf \"$STEAMROOT\"/!(compatibilitytools.d|depotcache|steamapps|userdata)"
            rm -rf "$STEAMHOME"
            # Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
            ;;
    esac
else
    # Fresh installation
    printf "\nNo existing Steam installation found. Performing fresh setup..\n"
    mkdir -p "$STEAMROOT"
    mkdir -p "$STEAMHOME"
    ln -fsn "$STEAMROOT" "$STEAMHOME/root"
    ln -fsn "$STEAMROOT" "$STEAMHOME/steam"
fi

if [ ! -x "$RTARM64ROOT" ]; then
    printf "\nDownloading steam bootstrap..\n"
    mkdir -p "$STEAMROOT/package"
    rm -f "$STEAMROOT/package/beta"
    echo "publicbeta" > "$STEAMROOT/package/beta"
    chmod 444 "$STEAMROOT/package/beta"
	wget -q --show-progress -c -t 5 -O "$STEAMROOT/linuxarm64.zip" "https://client-update.steamstatic.com/bins_linuxarm64_linuxarm64.zip.f523fa87fc6b9b5435a5e7370cb0d664ef53b50b" || exit_on_error "steam bootstrap download failed (check your internet connection)"
    unzip -d "$STEAMROOT" "$STEAMROOT/linuxarm64.zip" "steamrtarm64/steam"
    chmod +x "$RTARM64ROOT/steam"
    rm -rf "$STEAMROOT/linuxarm64.zip"
fi

if [ ! -x "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64" ]; then
	printf "\nDownloading steam-runtime..\n"
	mkdir -p "$RTARM64ROOT/pv-runtime"
	wget -q --show-progress -c -t 5 -O "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" "https://repo.steampowered.com/steamrt3c/images/latest-public-beta/steam-runtime-steamrt-arm64.tar.xz" || exit_on_error "steam runtime download failed (check your internet connection)"
	tar -xf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" --directory "$RTARM64ROOT/pv-runtime" --checkpoint=200 --checkpoint-action=dot
	rm -rf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz"
fi

if [ ! -d "$STEAMROOT/Switchdeck/DXVK" ]; then
    printf "\nDownloading DXVK-Sarek..\n"
    mkdir -p "$STEAMROOT/Switchdeck/DXVK"

    LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
    DXVK_URL=$(echo "$LATEST_JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' | head -1)
    DXVK_TAG=$(echo "$LATEST_JSON" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)
    
    # protection fallback
    [ -z "$DXVK_URL" ] && { printf "\nError: GitHub API URL empty. Aborting installation.\n"; exit 1; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" "$DXVK_URL"
    tar -xzf "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" --directory "$STEAMROOT/Switchdeck/DXVK" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz"
    
    # Save version tag so the update script knows what's installed
    echo "$DXVK_TAG" > "$STEAMROOT/Switchdeck/dxvk-sarek_version.txt"
    printf "\nDXVK-Sarek installed successfully in Switchdeck/DXVK.\n"
fi

if [ ! -d "$STEAMROOT/Switchdeck/VKD3D" ]; then
    printf "\nDownloading VKD3D-Proton 2.3.1..\n"
    mkdir -p "$STEAMROOT/Switchdeck/VKD3D"

    VK_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.3.1/vkd3d-proton-2.3.1.tar.zst"

    # Check if zstd is missing
    command -v zstd >/dev/null || { printf "\nzstd is missing. Installing dependency.. (Requires sudo)\n"; [ -f /etc/fedora-release ] && sudo dnf install zstd -y || sudo apt install zstd -y; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" "$VK_URL"
    tar -xf "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" --directory "$STEAMROOT/Switchdeck/VKD3D" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst"
    
    printf "\nVKD3D installed successfully in Switchdeck/VKD3D.\n"
fi

# Fix controller permissions
CONTROLLER_RELOAD=0
if command -v apt-get &>/dev/null; then
    dpkg -s steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo apt-get update && sudo apt-get install -y steam-devices && CONTROLLER_RELOAD=1
    }
elif command -v dnf &>/dev/null; then
    rpm -q steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo dnf install -y steam-devices && CONTROLLER_RELOAD=1
    }
elif command -v pacman &>/dev/null; then
    pacman -Qi steam-devices &>/dev/null || { 
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        sudo pacman -S --noconfirm steam-devices && CONTROLLER_RELOAD=1
    }
else
    if [ ! -f /etc/udev/rules.d/70-uinput.rules ]; then
        printf "\nConfiguring controller permissions.. (Requires sudo)\n"
        printf "No supported package manager found. Configuring manually..\n"
        sudo sh -c "mkdir -p /etc/udev/rules.d && echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"' > /etc/udev/rules.d/70-uinput.rules"
        sudo modprobe uinput || true
        CONTROLLER_RELOAD=1
    fi
fi

if [ "$CONTROLLER_RELOAD" -eq 1 ]; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger --sysname-match=uinput 2>/dev/null || sudo udevadm trigger
    printf "\nController permissions applied successfully.\n"
fi

if [ -x "$RTARM64ROOT/steam" ]; then
    printf "\nStarting Steam (Initial Update phase)..\n"
    export LD_LIBRARY_PATH="$RTARM64ROOT:${LD_LIBRARY_PATH-}"
    "$RTARM64ROOT/steam" "$@" || true
    
    printf "\nSteam exited. Downloading files to downgrade steam..\n"

    # temp dir for extraction
    TEMP_SD="$STEAMROOT/temp_sd"
    mkdir -p "$TEMP_SD"

	wget -q -t 5 -O- "https://github.com/SildurFX/Switchdeck/archive/refs/heads/main.tar.gz" | tar xz -C "$TEMP_SD" --strip-components=1 || exit_on_error "Failed to download/extract downgrade files"

    if [ -f "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" ]; then
        mkdir -p "$STEAMROOT/linuxarm64"
        tar -xzf "$TEMP_SD/files/downgrade/linuxarm64.tar.gz" -C "$STEAMROOT/linuxarm64"
    fi

    # Reassemble and extract steamrtarm64
    if [ -f "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.partaa" ]; then
        mkdir -p "$STEAMROOT/steamrtarm64"
        cat "$TEMP_SD/files/downgrade/steamrtarm64.tar.gz.part"* > "$TEMP_SD/steamrtarm64.tar.gz"
        tar -xzf "$TEMP_SD/steamrtarm64.tar.gz" -C "$STEAMROOT/steamrtarm64"
        rm -f "$TEMP_SD/steamrtarm64.tar.gz"
    fi

    # move files and scripts
    cp -f  "$TEMP_SD/files/downgrade/steam.cfg" "$STEAMROOT/steam.cfg"
    cp -f  "$TEMP_SD/files/steam/launch-steam.sh" "$STEAMROOT/"
    cp -f  "$TEMP_SD/files/steam/update-switchdeck.sh" "$STEAMROOT/"

    # Cleanup
    rm -rf "$TEMP_SD"

    # Overkill but make sure everything is executable
	chmod -R +x "$STEAMROOT"

    # Run the launcher for 2 seconds to generate the shortcuts
    timeout 2s bash "$STEAMROOT/launch-steam.sh" 2>/dev/null || true
    pkill -x "steam|steamwebhelper" >/dev/null 2>&1 || true

    printf "\nInstallation complete!\n"
    printf "To launch Steam, use the provided desktop shortcuts\n"
    printf "or run launch-steam.sh in your Steam folder.\n\n"
    sleep 3
fi