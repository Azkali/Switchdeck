#!/usr/bin/env bash

# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3

set -o pipefail
shopt -s failglob
set -u

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

STEAMROOT="$HOME/.local/share/Steam"

# Check for old folder name and update to new structure
if [ -d "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt" ]; then
    echo "Old runtime structure detected. Migrating to -arm64 suffix.."
    mv -f "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt" "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt-arm64"
fi

echo "Checking for script updates.."
wget -t 5 -N -P "$STEAMROOT" "https://raw.githubusercontent.com/SildurFX/Switchdeck/refs/heads/main/files/steam/launch-steam.sh"
wget -t 5 -N -P "$STEAMROOT" "https://raw.githubusercontent.com/SildurFX/Switchdeck/refs/heads/main/files/steam/update-switchdeck.sh"
chmod +x "$STEAMROOT/launch-steam.sh" "$STEAMROOT/update-switchdeck.sh"

# Restart if update-switchdeck.sh was updated
if [[ "$STEAMROOT/update-switchdeck.sh" -nt "$0" ]]; then
    echo "New version detected. Restarting script..."
    exec "$STEAMROOT/update-switchdeck.sh" "$@"
fi

# Verify controller permissions
if [ ! -w /dev/uinput ]; then
    echo "Controller permissions not found. Fixing.. (Requires sudo)"
    sudo sh -c "mkdir -p /etc/udev/rules.d && echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", TAG+=\"uaccess\", OPTIONS+=\"static_node=uinput\"' > /etc/udev/rules.d/70-uinput.rules"
    sudo modprobe uinput 2>/dev/null || true
    sudo udevadm control --reload-rules && sudo udevadm trigger --sysname-match=uinput
    echo "Done!"
fi

# Check for DXVK-Sarek update
SWITCHDECK_DIR="$HOME/.steam/steam/Switchdeck"
DX_DIR="$SWITCHDECK_DIR/DXVK"
VERSION_FILE="$SWITCHDECK_DIR/dxvk-sarek_version.txt"
LATEST_JSON=$(wget -qO- "https://api.github.com/repos/pythonlover02/DXVK-Sarek/releases/latest")
LATEST_TAG=$(echo "$LATEST_JSON" | grep -Po '"tag_name": "\K.*?(?=")')

if [ "$LATEST_TAG" != "$(cat "$VERSION_FILE" 2>/dev/null)" ] || [ ! -d "$DX_DIR" ]; then
    echo "Updating DXVK-Sarek to $LATEST_TAG.."
    URL=$(echo "$LATEST_JSON" | grep -Po '"browser_download_url": "\K.*?(?=")' | head -1)
    # Clean up old folders if they exist from previous versions
    rm -rf "$SWITCHDECK_DIR/x64" "$SWITCHDECK_DIR/x32"
    # Clean and recreate the specific DXVK subfolder
    rm -rf "$DX_DIR" && mkdir -p "$DX_DIR"

    wget -q --show-progress "$URL" -O- | tar -xzf - -C "$DX_DIR" --strip-components=1
    echo "$LATEST_TAG" > "$VERSION_FILE"
    echo "DXVK-Sarek updated successfully."
fi

# Check if VKD3D is installed
VK_DIR="$SWITCHDECK_DIR/VKD3D"
VK_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.3.1/vkd3d-proton-2.3.1.tar.zst"

if [ ! -d "$VK_DIR" ]; then
    echo "Missing VKD3D folder. Downloading.."
    mkdir -p "$VK_DIR"
    wget -q --show-progress -O- "$VK_URL" | tar --use-compress-program=zstd -xf - -C "$VK_DIR" --strip-components=1
    echo "VKD3D added successfully."
fi

read -p "Update Steam? (y/N): " choice
[[ "$choice" =~ ^[yY] ]] || { echo "Skipping"; exit; }
echo "Updating Steam.."
mv -f "$STEAMROOT/steam.cfg" "$STEAMROOT/steam.cfg.bak"
mv -f "$STEAMROOT/linuxarm64" "$STEAMROOT/linuxarm64.bak"
mv -f "$STEAMROOT/steamrtarm64" "$STEAMROOT/steamrtarm64.bak"

# Point LD_LIBRARY_PATH to the .bak location
_rtarm=$(ls -d "$STEAMROOT/steamrtarm64.bak/pv-runtime/steam-runtime-steamrt-arm64"/steamrt3c_platform_*/files 2>/dev/null | head -1)
export LD_LIBRARY_PATH="$STEAMROOT/steamrtarm64.bak${_rtarm:+:$_rtarm/lib/aarch64-linux-gnu:$_rtarm/lib}:${LD_LIBRARY_PATH-}"

# Run updater from the .bak folder
"$STEAMROOT/steamrtarm64.bak/steam" -forcesteamupdate -forcepackagedownload -exitsteam & wait $!

echo "Merging binaries.."
mv -f "$STEAMROOT/steam.cfg.bak" "$STEAMROOT/steam.cfg"
rm -rf "$STEAMROOT/linuxarm64" && mv -f "$STEAMROOT/linuxarm64.bak" "$STEAMROOT/linuxarm64"

# Selective Merge, keep new runtime, restore ARM64 binaries
if [ -d "$STEAMROOT/steamrtarm64/pv-runtime" ]; then
    mv "$STEAMROOT/steamrtarm64/pv-runtime" "$STEAMROOT/tmp_rt"
    rm -rf "$STEAMROOT/steamrtarm64" && mv "$STEAMROOT/steamrtarm64.bak" "$STEAMROOT/steamrtarm64"
    rm -rf "$STEAMROOT/steamrtarm64/pv-runtime" && mv "$STEAMROOT/tmp_rt" "$STEAMROOT/steamrtarm64/pv-runtime"
else
    rm -rf "$STEAMROOT/steamrtarm64" && mv "$STEAMROOT/steamrtarm64.bak" "$STEAMROOT/steamrtarm64"
fi

chmod -R +x "$STEAMROOT/linuxarm64" "$STEAMROOT/steamrtarm64"
echo "Update complete!"