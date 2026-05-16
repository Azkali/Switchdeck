#!/usr/bin/env bash

# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3

set -euo pipefail

exit_on_error() {
    echo "ERROR: $1" >&2
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

# Check if either Steam directory exists
if [ -d "$STEAMROOT" ] || [ -d "$STEAMHOME" ]; then
    echo "Steam directories already exist."
    read -p "A clean installation is recommended. Would you like to delete them now? (y/N): " choice
    case "$choice" in 
        [yY][eE][sS]|[yY]) 
            echo "Deleting $STEAMROOT and $STEAMHOME..."
            rm -rf "$STEAMROOT"
            rm -rf "$STEAMHOME"
			# Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
            ;;
        *)
            echo "Continuing with dirty installation"
            shopt -s extglob dotglob
            eval "rm -rf "$STEAMROOT"/!(compatibilitytools.d|depotcache|steamapps|userdata)"
            rm -rf "$STEAMHOME"
            # Make steam folders
			mkdir -p "$STEAMROOT"
			mkdir -p "$STEAMHOME"
            ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	        ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
            ;;
    esac
fi

if [ ! -x "$RTARM64ROOT" ]; then
	echo "Downloading steam bootstrap.."
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
	echo "Downloading steam-runtime.."
	mkdir -p "$RTARM64ROOT/pv-runtime"
	wget -q --show-progress -c -t 5 -O "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" "https://repo.steampowered.com/steamrt3c/images/latest-public-beta/steam-runtime-steamrt-arm64.tar.xz" || exit_on_error "steam runtime download failed (check your internet connection)"
	tar -xf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz" --directory "$RTARM64ROOT/pv-runtime" --checkpoint=200 --checkpoint-action=dot
	rm -rf "$RTARM64ROOT/pv-runtime/steam-runtime-steamrt-arm64.tar.xz"
fi

if [ ! -d "$STEAMROOT/Switchdeck/DXVK" ]; then
    echo "Downloading DXVK-Sarek.."
    mkdir -p "$STEAMROOT/Switchdeck/DXVK"

    LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
    DXVK_URL=$(echo "$LATEST_JSON" | sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' | head -1)
    DXVK_TAG=$(echo "$LATEST_JSON" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)
    
    # protection fallback
    [ -z "$DXVK_URL" ] && { echo "Error: GitHub API URL empty. Aborting installation."; exit 1; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" "$DXVK_URL"
    tar -xzf "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz" --directory "$STEAMROOT/Switchdeck/DXVK" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/DXVK/dxvk-sarek.tar.gz"
    
    # Save version tag so the update script knows what's installed
    echo "$DXVK_TAG" > "$STEAMROOT/Switchdeck/dxvk-sarek_version.txt"
    echo "DXVK-Sarek installed successfully in Switchdeck/DXVK."
fi

if [ ! -d "$STEAMROOT/Switchdeck/VKD3D" ]; then
    echo "Downloading VKD3D-Proton 2.3.1.."
    mkdir -p "$STEAMROOT/Switchdeck/VKD3D"

    VK_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.3.1/vkd3d-proton-2.3.1.tar.zst"

    # Check if zstd is missing
    command -v zstd >/dev/null || { echo "zstd is missing. Installing dependency.. (Requires sudo)"; [ -f /etc/fedora-release ] && sudo dnf install zstd -y || sudo apt-get install zstd -y; }

    wget -q --show-progress -c -t 5 -O "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" "$VK_URL"
    tar -xf "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst" --directory "$STEAMROOT/Switchdeck/VKD3D" --strip-components=1
    rm -f "$STEAMROOT/Switchdeck/VKD3D/vkd3d.tar.zst"
    
    echo "VKD3D installed successfully in Switchdeck/VKD3D."
fi

# Fix controller permissions
if [ ! -w /dev/uinput ]; then
    echo "Configuring controller permissions..(Requires sudo)"
    sudo sh -c "mkdir -p /etc/udev/rules.d && echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"' > /etc/udev/rules.d/70-uinput.rules"
    sudo modprobe uinput || true
    
    # Apply changes immediately
    sudo udevadm control --reload-rules
    sudo udevadm trigger --sysname-match=uinput
    echo "Controller permissions applied successfully."
fi

if [ -x "$RTARM64ROOT/steam" ]; then
    echo "Starting Steam (Initial Update phase)..."
    export LD_LIBRARY_PATH="$RTARM64ROOT:${LD_LIBRARY_PATH-}"
    "$RTARM64ROOT/steam" "$@" || true
    
    echo "Steam exited. Downloading files to downgrade steam.."

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

    echo "Launching Steam"
    exec "$STEAMROOT/launch-steam.sh" "$@"
fi