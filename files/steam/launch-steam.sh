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

# Switchdeck:
SD_GAMEMODE="true"                      # Toggle switchdeck gamemode.
UPDATE_CHECK="true"                     # Toggle switchdeck update check on launch.
STEAMDECK_MODE="false"                  # Toggle steamdeck / big picture mode for steam.

# Proton:
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

# DXVK-Sarek:
export DXVK_ALL_CORES=1                 # Overwrite the way we assign cores to compile shaders. By default use roughly half the available CPU cores for background compilation.

# Box64:
export BOX64_PROFILE=default            # [safest safe default fast fastest] Predefined environment variables. Default performs better than fast/fastest on Switch due to more relaxed Memory configuration.
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

# Steam setup
export TEXTDOMAIN=steam
export TEXTDOMAINDIR=/usr/share/locale
export SYSTEM_PATH="$PATH"
export SYSTEM_LD_LIBRARY_PATH="${LD_LIBRARY_PATH-}"
export SYSTEM_ZENITY="$(which zenity 2>/dev/null)" # Prefer host zenity binary if available
MAGIC_RESTART_EXITCODE=42
if [ -z ${SYSTEM_ZENITY} ]; then
	export STEAM_ZENITY="zenity"
else
	export STEAM_ZENITY="${SYSTEM_ZENITY}"
fi

STEAMHOME="$HOME/.steam"
STEAMROOT="$HOME/.local/share/Steam"
SWITCHDECK_DIR="$STEAMROOT/Switchdeck"
CEF_PATH="$STEAMROOT/steamrtarm64/steamwebhelper.sh"
CEF_DUMMY="${CEF_PATH}.dummy"

# check for updates, spawn terminal
ONLINE=0
# Only check if online, every 60min and if steam is not running
if [ "$UPDATE_CHECK" = "true" ] && [ ! -t 0 ] && ! pidof steam >/dev/null 2>&1; then
    if [ ! -f "$SWITCHDECK_DIR/.update.lock" ] || [ -n "$(find "$SWITCHDECK_DIR/.update.lock" -mmin +60 2>/dev/null)" ]; then
        ping -q -c 1 -W 2 8.8.8.8 &>/dev/null && ONLINE=1
    fi
fi

if [ "$ONLINE" -eq 1 ]; then
    UPDATE_CMD="source '$STEAMROOT/update-switchdeck.sh'; sleep 1; [[ '$STEAMROOT/launch-steam.sh' -nt '$0' || '$STEAMROOT/update-switchdeck.sh' -nt '$0' ]] && exit 0"
    if command -v konsole >/dev/null 2>&1; then
        konsole -e bash -c "$UPDATE_CMD"
    elif command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal --wait -- bash -c "$UPDATE_CMD"
    elif command -v xterm >/dev/null 2>&1; then
        xterm -e bash -c "$UPDATE_CMD"
    fi
    touch "$SWITCHDECK_DIR/.update.lock"
fi

if [[ "$STEAMROOT/launch-steam.sh" -nt "$0" ]] || [[ "$STEAMROOT/update-switchdeck.sh" -nt "$0" ]]; then
    exec "$0" "$@"
fi

# symlink folder '0' to /dev/null to stop proton initialization on every launch
C0="$STEAMROOT/steamapps/compatdata/0"
[[ -d "$C0" && ! -L "$C0" ]] && rm -rf "$C0"
[[ ! -e "$C0" ]] && ln -s /dev/null "$C0"

# Proton 11 (ARM64) ships its native arm64 Wine PE stack + bundled FEX built for
# ARMv8.1-A (inline LSE atomics), which raise SIGILL on ARMv8.0-A CPUs that lack
# LSE -- e.g. the Tegra X1 Cortex-A57 (Nintendo Switch). On such hosts, overlay an
# ARMv8.0 rebuild so wine/dxvk/vkd3d/FEX run. No-op on ARMv8.1+ (LSE) devices.
# Runs before the DXVK-Sarek and win32u patches below so they re-apply on top of
# the overlaid files in the same launch.
# https://github.com/Azkali/proton-arm64-a57
if ! grep -qw atomics /proc/cpuinfo; then
    P11_OVL_TAG="11.0-1-beta5-v80"
    P11_OVL_URL="https://github.com/Azkali/proton-arm64-a57/releases/download/${P11_OVL_TAG}/proton11-arm64-v80-a57.tar.zst"
    P11_VDF="$STEAMROOT/steamapps/libraryfolders.vdf"
    # every Steam library (default root + libraryfolders.vdf entries)
    { echo "$STEAMROOT"; [ -f "$P11_VDF" ] && grep -oE '"/[^"]+"' "$P11_VDF" | tr -d '"' | sort -u; } | while read -r lib; do
        p_dir="$lib/steamapps/common/Proton 11.0 (ARM64)"
        p="$p_dir/files"
        [ -d "$p/lib/wine/aarch64-windows" ] || continue
        P11_VER="$(cat "$p_dir/version" 2>/dev/null || echo unknown)"
        [ "$(cat "$p_dir/.switchdeck-a57-overlay" 2>/dev/null)" = "${P11_OVL_TAG}:${P11_VER}" ] && continue
        # GNU tar fails with EINVAL on current Fedora + the 4.9 kernel; prefer bsdtar
        if command -v bsdtar >/dev/null; then
            P11_TAR="bsdtar"
        elif command -v zstd >/dev/null; then
            P11_TAR="tar"
        else
            log "Proton 11 (ARM64) A57 overlay needs bsdtar or zstd; skipping"
            break
        fi
        log "Applying ARMv8.0 (Cortex-A57) overlay to Proton 11.0 (ARM64)"
        P11_TMP="$p_dir/.a57-overlay.tar.zst"
        if wget -q -t 3 -O "$P11_TMP" "$P11_OVL_URL"; then
            [ -f "$p_dir/.proton11-stock.tar" ] || $P11_TAR -cf "$p_dir/.proton11-stock.tar" -C "$p" bin-arm64 lib 2>/dev/null || true
            if { [ "$P11_TAR" = "bsdtar" ] && bsdtar -xf "$P11_TMP" -C "$p"; } ||
               { [ "$P11_TAR" = "tar" ] && zstd -dc "$P11_TMP" | tar -C "$p" -xf -; }; then
                echo "${P11_OVL_TAG}:${P11_VER}" > "$p_dir/.switchdeck-a57-overlay"
                log "Proton 11 (ARM64) overlay applied (A57-safe)"
            else
                log "WARN: Proton 11 (ARM64) overlay extraction failed"
            fi
        else
            log "WARN: could not download Proton 11 (ARM64) A57 overlay"
        fi
        rm -f "$P11_TMP"
    done
fi

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

# Patch out extension VK_EXT_external_memory_host in Proton 10 to fix vertex explosions in 32-bit games:
find "$STEAMROOT/steamapps/common" "$STEAMROOT/compatibilitytools.d" -maxdepth 1 \( -name "Proton 10*" -o -name "GE-Proton10*" \) 2>/dev/null | while read -r p_dir; do
    p="$p_dir/files"
    [ -d "$p" ] || continue
    LIB32="$p/lib/wine/i386-unix/winevulkan.so"
    LIB64="$p/lib/wine/x86_64-unix/winevulkan.so"
    PATCHED_ANY=false
    if [ -f "$LIB32" ]; then
        if strings "$LIB32" | grep -a "VK_EXT_external_memory_host" >/dev/null; then
            sed -i 's/VK_EXT_external_memory_host/VK_EXT_external_memory_Xost/g' "$LIB32"
            PATCHED_ANY=true
        fi
    fi
    if [ -f "$LIB64" ]; then
        if strings "$LIB64" | grep -a "VK_EXT_external_memory_host" >/dev/null; then
            sed -i 's/VK_EXT_external_memory_host/VK_EXT_external_memory_Xost/g' "$LIB64"
            PATCHED_ANY=true
        fi
    fi
    if [ "$PATCHED_ANY" = true ]; then
        log "Applied 32-bit patch to: $(basename "$p_dir")"
    fi
done

# Patch out extension VK_EXT_external_memory_host in Proton 11 / GE-Proton11 / Experimental / Hotfix to fix vertex explosions in 32-bit games:
find "$STEAMROOT/steamapps/common" "$STEAMROOT/compatibilitytools.d" -maxdepth 1 \( -name "Proton 11*" -o -name "GE-Proton11*" -o -name "Proton - Experimental" -o -name "Proton Hotfix" \) 2>/dev/null | while read -r p_dir; do
    p="$p_dir/files"
    [ -d "$p" ] || continue
    LIB32="$p/lib/wine/i386-unix/win32u.so"
    LIB64="$p/lib/wine/x86_64-unix/win32u.so"
    PATCHED_ANY=false
    if [ -f "$LIB32" ]; then
         if strings "$LIB32" | grep -a "VK_EXT_external_memory_host" >/dev/null; then
            sed -i 's/VK_EXT_external_memory_host/VK_EXT_external_memory_Xost/g' "$LIB32"
            PATCHED_ANY=true
         fi
    fi
    if [ -f "$LIB64" ]; then
         if strings "$LIB64" | grep -a "VK_EXT_external_memory_host" >/dev/null; then
            sed -i 's/VK_EXT_external_memory_host/VK_EXT_external_memory_Xost/g' "$LIB64"
            PATCHED_ANY=true
         fi
    fi
    if [ "$PATCHED_ANY" = true ]; then
        log "Applied winevulkan patch to: $(basename "$p_dir")"
    fi
done

# Switchdeck Gamemode
if [ "$SD_GAMEMODE" = "true" ]; then
    # Preparation & Crash Recovery
    [ ! -f "$CEF_DUMMY" ] && printf "#!/bin/bash\n# Gamemode Dummy\nsleep infinity\n" > "$CEF_DUMMY" && chmod +x "$CEF_DUMMY"
    [ -f "${CEF_PATH}.bak" ] && { [ $(stat -c%s "$CEF_PATH" 2>/dev/null || echo 0) -lt 100 ] || [ -f "/tmp/cef_swapped.lock" ]; } && mv -f "${CEF_PATH}.bak" "$CEF_PATH" && chmod +x "$CEF_PATH" && rm -f "/tmp/cef_swapped.lock"
    # Capture the main script's PID to track its lifecycle
    PARENT_PID=$$
    (
        # silence logs / terminal
        exec 2>/dev/null

        # low prio loop and prevent multiple loops
        renice -n 19 -p $BASHPID >/dev/null 2>&1
        LOCK_FILE="/tmp/switchdeck_gamemode.pid"
        if [ -f "$LOCK_FILE" ] && kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then exit 0; fi
        echo $$ > "$LOCK_FILE"

        # Scan /proc to find active gamemode PID
        find_gamemode_pid() {
            for p in /proc/[0-9]*; do
                [ -r "$p/environ" ] && grep -zq "^SWITCHDECK_GAMEMODE=" "$p/environ" 2>/dev/null && echo "${p##*/}" && return 0
            done
            return 1
        }
        # Verify if Steam is active
        is_steam_running() {
            for p in /proc/[0-9]*; do
                [ -r "$p/comm" ] && read -r c < "$p/comm" 2>/dev/null && [ "$c" = "steam" ] && return 0
            done
            return 1
        }
        # Main monitoring loop
        while true; do
            # break the loop and exit cleanly
            if ! kill -0 "$PARENT_PID" 2>/dev/null; then
                rm -f "$LOCK_FILE"
                exit 0
            fi
            # Check for steam existence without trapping execution indefinitely
            if ! is_steam_running; then
                sleep 15
                continue
            fi
            GAME_PID=$(find_gamemode_pid)
            if [[ -n "$GAME_PID" ]] && [ ! -f "/tmp/cef_swapped.lock" ]; then
                sleep 3
                GAME_PID=$(find_gamemode_pid)
                [ -z "$GAME_PID" ] && { sleep 15; continue; }
                
                # Detect mode 1 or 2 from application context
                grep -zq "^SWITCHDECK_GAMEMODE=2" "/proc/$GAME_PID/environ" 2>/dev/null && FLAG=2 || FLAG=1

                # Replace with placeholder dummy
                if [ $(stat -c%s "$CEF_PATH" 2>/dev/null || echo 0) -gt 100 ]; then
                    mv -f "$CEF_PATH" "${CEF_PATH}.bak" && cp -p "$CEF_DUMMY" "$CEF_PATH" && touch "/tmp/cef_swapped.lock"
                fi
                killall -9 steamwebhelper drkonqi 2>/dev/null; pkill -9 -f steamwebhelper.sh 2>/dev/null
                
                # Mode 2: Cleanly stop components to prevent crash window popups
                if [ "$FLAG" -eq 2 ]; then
                    systemctl --user stop plasma-plasmashell.service 2>/dev/null
                    killall -9 krunner kded5 kded6 kdeconnectd DiscoverNotifier drkonqi 2>/dev/null
                fi

                # Wait directly for target process to close
                while [ -d "/proc/$GAME_PID" ]; do sleep 5; done
                sleep 2

                # Revert
                if [ -f "/tmp/cef_swapped.lock" ] && [ -f "${CEF_PATH}.bak" ] && [ $(stat -c%s "${CEF_PATH}.bak" 2>/dev/null || echo 0) -gt 100 ]; then
                    rm -f "$CEF_PATH" && mv -f "${CEF_PATH}.bak" "$CEF_PATH" && chmod +x "$CEF_PATH" && rm -f "/tmp/cef_swapped.lock"
                fi
                pkill -9 -f steamwebhelper.sh 2>/dev/null; killall -9 steamwebhelper 2>/dev/null

                # Restore
                if [ "$FLAG" -eq 2 ]; then
                    systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null
                    V="5"; command -v kstart6 >/dev/null && V="6"
                    kstart$V kded$V >/dev/null 2>&1 && sleep 2
                    systemctl --user start plasma-plasmashell.service 2>/dev/null
                    { kstart$V krunner & } >/dev/null 2>&1
                    unset V
                fi
            fi
            sleep 15
        done
    ) &
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

    # Restore paths before restarting if we need to.
    export PATH="$SYSTEM_PATH"
    export LD_LIBRARY_PATH="$SYSTEM_LD_LIBRARY_PATH"

    # If steam requested to restart, then restart
    if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ] ; then
        log "Restarting Steam by request"
        exec "$0" "$@"
    fi
    exit $STATUS
fi