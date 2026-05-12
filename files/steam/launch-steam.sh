#!/usr/bin/env bash

# verbose
# export PS4='${LINENO}: '
# set -x

########################################################################################################################################
# Switchdeck by SildurFX | https://github.com/SildurFX/Switchdeck
# License: GPLv3
#
# Documentation:
# Steam:  https://gist.github.com/davispuh/6600880
#         https://developer.valvesoftware.com/wiki/Command_line_options_(Steam)
# Proton: https://github.com/valvesoftware/proton
#         https://github.com/CachyOS/proton-cachyos
# DXVK:	  https://github.com/pythonlover02/DXVK-Sarek/blob/main/dxvk.conf
# Box64:  https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md
#
# Steam games can be launched with: SWITCHDECK_GAMEMODE=1 or 2 %command% to free up 1GB+ of RAM.
# Mode 1: Unloads steamwebhelper on game launch and restores it on game exit.
# Mode 2 (Aggressive): Also stops KDE Plasma & background services, including internet.
########################################################################################################################################

STEAMDECK_MODE="false"                  # Toggle steamdeck / big picture mode for steam.

# Proton-CachyOS:
export PROTON_USE_WOW64=1               # Use wow64 mode
export PROTON_DXVK_SAREK=1              # Use the dxvk-sarek fork as DXVK replacement for older GPUs that don't support Vulkan 1.3 (supports Vulkan 1.1+)

# Wine:
export WINEESYNC=0                      # Supported but crashes dxvk and only works with wined3d
export PROTON_NO_ESYNC=1                # set WINEESYNC=1 and PROTON_NO_ESYNC=0 to enable esync
export PROTON_NO_FSYNC=1                # requires Kernel 5.x+
export PROTON_NO_NTSYNC=1               # requires Kernel 6.12+
export STAGING_WRITECOPY=1              # Uses copy-on-write for shared memory to improve stability and prevent corruption
export STAGING_SHARED_MEMORY=1          # Enables shared memory segments to reduce overhead and improve startup times
export __GL_THREADED_OPTIMIZATIONS=1    # Enable driver-side multi-threading to reduce CPU bottlenecks in OpenGL games

# DXVK:
export DXVK_ALL_CORES=1                 # Overwrite the way we assign cores to compile shaders. By default use roughly half the available CPU cores for background compilation.

# Box64:
export BOX64_PROFILE=fast               # [safest safe default fast fastest] Predefined environment variables with compatibility or performance in mind
export BOX64_X87_NO80BITS=1             # [0=default 1] Behaviour of x87 80bits long double.
export BOX64_DYNAREC_CALLRET=1          # [0=default 1 2] Optimize CALL/RET opcodes.
export BOX64_DYNAREC_BIGBLOCK=3         # [0 1 2=default 3] Enable building bigger DynaRec code blocks for better performance
# unstable
# export BOX64_DYNAREC_WAIT=0           # [0 1=default] Wait or not for the building of a DynaRec code block to be ready
# export BOX64_DYNAREC_DIRTY=2          # [0=default 1 2] Allow continue running a block that is unprotected and potentially dirty.

# Disable logging:
export BOX64_LOG=0                      # [0 1 2 3] Enable or disable Box64 logs, default value is 0 if stdout is not terminal, 1 otherwise
export WINEDEBUG=-all                   # https://gitlab.winehq.org/wine/wine/-/wikis/Debug-Channels
export DXVK_LOG_LEVEL=none              # [none error warn info debug] Controls message logging

# Steam launch flags:
STEAM_FLAGS=""
STEAM_FLAGS+=" -vrskip"                 # Skip VR initialization entirely no matter who asks for it
STEAM_FLAGS+=" -fasthtml"               # Enable fast child html for any platform
STEAM_FLAGS+=" -vrdisable"             	# Disable VR - never even try to load OpenVR DLLs
STEAM_FLAGS+=" -noverifyfiles"         	# Prevents from the client from checking files integrity, especially useful when testing localization.
STEAM_FLAGS+=" -nocrashmonitor"        	# Disables the Steam crash monitor
STEAM_FLAGS+=" -no-cef-sandbox"         # Disables sandboxing in CEF
STEAM_FLAGS+=" -cef-disable-sandbox"    # Disables sandboxing in CEF
STEAM_FLAGS+=" -cef-single-process"     # Runs CEF processes in single process
STEAM_FLAGS+=" -cef-in-process-gpu"     # Runs CEF GPU processing as thread of browser process
STEAM_FLAGS+=" -cef-disable-breakpad"  	# Disables breakpad in crash dumps
STEAM_FLAGS+=" -cef-disable-js-logging" # Disables console and log file logging of JS console events
STEAM_FLAGS+=" -cef-disable-seccomp-sandbox" # Disables CEF seccomp-bpf sandbox on Linux
# STEAM_FLAGS+=" -dev"

if [ "$STEAMDECK_MODE" = "true" ]; then
STEAM_FLAGS+=" -720p"                   # Run tenfoot (big picture) in 720p rather than 1080p
STEAM_FLAGS+=" -steampal"               # internal codename for the Steam Deck hardware. Enables Steam Deck hardware-specific menu options.
STEAM_FLAGS+=" -gamepadui"              # Start in gamepadui mode (same as tenfoot)
STEAM_FLAGS+=" -steamdeck"              # Pretend to be a steamdeck.
# STEAM_FLAGS+=" -steamos3"             # Emulates the SteamOS 3 environment.
# STEAM_FLAGS+=" -enablealloobesteps    # Steamdeck Out of Box Experience
fi

########################################################################################################################################

set -o pipefail
shopt -s failglob
set -u

log () {
	echo "launch-steam.sh[$$]: $*" >&2 || :
}

# Overwrites defaults and enables tracing if launched from a terminal (Konsole)
if [ -t 1 ]; then
    echo "Debug Mode Active (Terminal Detected)"
    set -x
    export BOX64_LOG=1
    export WINEDEBUG=""
    export DXVK_LOG_LEVEL=info
else
    exec > /dev/null 2>&1
fi

export TEXTDOMAIN=steam
export TEXTDOMAINDIR=/usr/share/locale

MAGIC_RESTART_EXITCODE=42
STEAMROOT="$HOME/.local/share/Steam"
STEAMHOME="$HOME/.steam"
SWITCHDECK_DIR="$STEAMROOT/Switchdeck"
CEF_PATH="$STEAMROOT/steamrtarm64/steamwebhelper.sh"

# symlink folder '0' to /dev/null to stop proton initialization on every launch
C0="$STEAMROOT/steamapps/compatdata/0"
[[ -d "$C0" && ! -L "$C0" ]] && rm -rf "$C0"
[[ ! -e "$C0" ]] && ln -s /dev/null "$C0"

# Patch both Native and GE-Proton with DXVK-Sarek and VKD3D v2.3.1
DX_SRC="$SWITCHDECK_DIR/DXVK"
VK_SRC="$SWITCHDECK_DIR/VKD3D"

if [ -d "$DX_SRC" ] && [ -d "$VK_SRC" ]; then
    find "$STEAMROOT/steamapps/common" "$STEAMROOT/compatibilitytools.d" -maxdepth 1 \( -name "Proton*" -o -name "GE-Proton*" \) 2>/dev/null | while read -r p_dir; do
        p="$p_dir/files"
        [ -d "$p" ] || continue
        DX_CHECK="$p/lib/wine/dxvk/x86_64-windows/d3d11.dll"
        VK_CHECK="$p/lib/wine/vkd3d-proton/x86_64-windows/d3d12.dll"

        if [ ! -L "$DX_CHECK" ] || [ ! -L "$VK_CHECK" ]; then
            log "Patching: $(basename "$p_dir")"
            
            # DXVK
            DX64="$p/lib/wine/dxvk/x86_64-windows"
            DX32="$p/lib/wine/dxvk/i386-windows"
            mkdir -p "$DX64" "$DX32"
            for f in "$DX_SRC/x64"/*.dll; do [ -e "$f" ] && ln -sf "$f" "$DX64/${f##*/}"; done
            for f in "$DX_SRC/x32"/*.dll; do [ -e "$f" ] && ln -sf "$f" "$DX32/${f##*/}"; done
            
            # VKD3D
            VK64="$p/lib/wine/vkd3d-proton/x86_64-windows"
            VK32="$p/lib/wine/vkd3d-proton/i386-windows"
            mkdir -p "$VK64" "$VK32"    
            [ -f "$VK_SRC/x64/d3d12.dll" ] && { ln -sf "$VK_SRC/x64/d3d12.dll" "$VK64/d3d12.dll"; ln -sf "$VK_SRC/x64/d3d12.dll" "$VK64/d3d12core.dll"; }
            [ -f "$VK_SRC/x86/d3d12.dll" ] && { ln -sf "$VK_SRC/x86/d3d12.dll" "$VK32/d3d12.dll"; ln -sf "$VK_SRC/x86/d3d12.dll" "$VK32/d3d12core.dll"; }
            log "Done!"
        fi
    done
else
    log "Source folders missing. Run update-switchdeck.sh"
fi

# Switchdeck gamemode
if [ -f "${CEF_PATH}.bak" ]; then
    if grep -q "sleep infinity" "$CEF_PATH" 2>/dev/null; then
        mv -f "${CEF_PATH}.bak" "$CEF_PATH"
        chmod +x "$CEF_PATH"
    fi
fi

(
    renice -n 19 -p $BASHPID >/dev/null 2>&1
    LOCK_FILE="/tmp/switchdeck_gamemode.pid"
    if [ -f "$LOCK_FILE" ]; then
        EXISTING_PID=$(cat "$LOCK_FILE")
        if kill -0 "$EXISTING_PID" 2>/dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCK_FILE"

    while true; do
        until pgrep -u $USER -x steam > /dev/null; do sleep 60; done

        RAW_MATCH=$(pgrep -af "SWITCHDECK_GAMEMODE=" | grep -vE "grep|$$" | head -n1)
        
        # only swap if a game is running and the current file is not the dummy
        if [[ -n "$RAW_MATCH" ]] && ! grep -q "sleep infinity" "$CEF_PATH" 2>/dev/null; then
            sleep 3 
            RAW_MATCH=$(pgrep -af "SWITCHDECK_GAMEMODE=" | grep -vE "grep|$$" | head -n1)
            [ -z "$RAW_MATCH" ] && continue
            case "$RAW_MATCH" in *"=2"*) FLAG=2 ;; *) FLAG=1 ;; esac

            # backup and swap
            cp -p "$CEF_PATH" "${CEF_PATH}.bak"
            echo -e "#!/bin/bash\n# Gamemode Dummy\nsleep infinity" > "${CEF_PATH}.tmp"
            chmod +x "${CEF_PATH}.tmp"
            mv -f "${CEF_PATH}.tmp" "$CEF_PATH"

            killall -9 steamwebhelper 2>/dev/null
            pkill -9 -f steamwebhelper.sh 2>/dev/null
            
            if [ "$FLAG" -eq 2 ]; then
                systemctl --user stop plasma-plasmashell.service 2>/dev/null
                killall -9 krunner kded5 kdeconnectd DiscoverNotifie onboard 2>/dev/null
            fi

            while pgrep -f "SWITCHDECK_GAMEMODE=" | grep -vE "grep|$$" > /dev/null; do 
                sleep 10
            done
            sleep 2

            # Restore
            if [ -f "${CEF_PATH}.bak" ]; then
                # Only restore if the backup is NOT the dummy
                if ! grep -q "sleep infinity" "${CEF_PATH}.bak" 2>/dev/null; then
                    mv -f "${CEF_PATH}.bak" "$CEF_PATH"
                    chmod +x "$CEF_PATH"
                    sync
                else
                    # If the backup is the dummy, it's useless. Delete it so the loop can try again later.
                    rm -f "${CEF_PATH}.bak"
                fi
            fi
            
            pkill -9 -f steamwebhelper.sh 2>/dev/null
            killall -9 steamwebhelper 2>/dev/null

            if [ "$FLAG" -eq 2 ]; then
                systemctl --user reset-failed plasma-plasmashell.service
                kstart5 kded5 >/dev/null 2>&1
                sleep 3
                systemctl --user start plasma-plasmashell.service
                { kstart5 krunner & } >/dev/null 2>&1
            fi
        fi
        sleep 15
    done
) &

if [ ! -f "$STEAMROOT/.switchdeck-initial-launch" ]; then
	log "creating initial symlinks"
	ln -fsn "$STEAMROOT" "$STEAMHOME/root"
	ln -fsn "$STEAMROOT" "$STEAMHOME/steam"	
	ln -fsn "$STEAMROOT/linux32" "$STEAMHOME/sdk32"
	ln -fsn "$STEAMROOT/linux64" "$STEAMHOME/sdk64"
	ln -fsn "$STEAMROOT/linuxarm64" "$STEAMHOME/sdkarm64"
	ln -fsn "$STEAMROOT/ubuntu12_32" "$STEAMHOME/bin32"
	ln -fsn "$STEAMROOT/ubuntu12_64" "$STEAMHOME/bin64"	
	ln -fsn "$STEAMHOME/bin32" "$STEAMHOME/bin"
	ln -fsn "$STEAMROOT/steamrtarm64" "$STEAMROOT/steamrtarm32"	

	# Add steam to path
	mkdir -p "$HOME/.local/bin"
	ln -fsn "$STEAMROOT/launch-steam.sh" "$HOME/.local/bin/steam"

    # Setup desktop path and icon
    MENU_DIR="$HOME/.local/share/applications"
    mkdir -p "$MENU_DIR"

    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
    mkdir -p "$DESKTOP_DIR"

    DESKTOP_FILE="$MENU_DIR/Steam.desktop"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Steam
Comment=Launch Steam
Exec=$HOME/.local/bin/steam %U
Icon=$STEAMROOT/public/steam_tray_48.tga
Terminal=false
Type=Application
Categories=Game;
MimeType=x-scheme-handler/steam;
EOF
    chmod +x "$DESKTOP_FILE"
    ln -fs "$DESKTOP_FILE" "$DESKTOP_DIR/Steam.desktop"
    update-desktop-database "$MENU_DIR" 2>/dev/null

	touch "$STEAMROOT/.switchdeck-initial-launch"
fi

if [ -x "$STEAMROOT/steamrtarm64/steam" ]; then
    log "Starting Steam"
	# Flat ARM64 -> Nested ARM64 -> Flat x64 -> Nested x64
	_rtarm=$(ls -d "$STEAMROOT/steamrtarm64/pv-runtime/steam-runtime-steamrt-arm64"/steamrt3c_platform_*/files 2>/dev/null | head -1)
	_rtx64=$(ls -d "$STEAMROOT/steamrt64/pv-runtime/steam-runtime-steamrt"/steamrt3c_platform_*/files 2>/dev/null | head -1)
	export LD_LIBRARY_PATH="$STEAMROOT/steamrtarm64${_rtarm:+:$_rtarm/lib/aarch64-linux-gnu:$_rtarm/lib}:$STEAMROOT/steamrt64${_rtx64:+:$_rtx64/lib/x86_64-linux-gnu:$_rtx64/lib}:${LD_LIBRARY_PATH-}"

	"$STEAMROOT/steamrtarm64/steam" "$@" $STEAM_FLAGS
	#strace -osteam.s.log -ff -e trace=file -e trace=execve -s 1000 --no-abbrev "$STEAMROOT/steamrtarm64/steam" "$@"

    STATUS=$?

    # If steam requested to restart, then restart
    if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ] ; then
        log "Restarting Steam by request"
        exec "$0" "$@"
    fi
    exit $STATUS
fi