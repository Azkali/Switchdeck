# Switchdeck: Steam ARM64 for Switch (L4T)

<img src="https://i.imgur.com/h0VFbgW.png" width="100%" alt="Steam Deck UI">

<div align="center">
  <img src="https://i.imgur.com/zaBCMSh.png" width="49%" alt="In-Game">
  <img src="https://i.imgur.com/b5L16Dc.png" width="49%" alt="Settings">
</div>

---

## Installation
1. Download and run `install-steam.sh` in your **terminal**.
2. In Steam go to **Settings** -> **Library** and turn on: Low Bandwidth, Low Performance and Disable Community Content.
3. Go to **Settings** -> **Compatibility** and select either Proton 10, 11 or Experimental. You can also download them manually in your library.
4. Restart Steam to apply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) patch to your Proton version. It's applied on launch.
5. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

**Note:** If Steam updates your Proton version you have to relaunch it to reapply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) patch.
Use Proton 10 or [Proton-10-GE](https://github.com/gloriouseggroll/proton-ge-custom) for 32-bit games. Both are patched on launch with a workaround for a broken vulkan extension, **fixing vertex explosions.**

---

## Requirements
* [Linux for Switch](https://wiki.switchroot.org/wiki/linux) (Fedora 42 or Ubuntu Noble)
* [Box64](https://github.com/ptitseb/box64) to run games. Shipped with Fedora 42 by default, install from this [repo](https://github.com/Pi-Apps-Coders/box64-debs) for Ubuntu.

---

## Information
* **Games** can be launched with: `SWITCHDECK_GAMEMODE=1 or 2 %command%`. This is a unique Switchdeck feature that **frees up 1GB+ of RAM** while keeping Steam Input and Multiplayer functional.
* In **Mode 1** it unloads steamwebhelper on launch and restores it on exit. In **Mode 2** it also stops KDE Plasma & background services. It will take a few seconds to restore Steam or KDE after the game exits.
* [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases) and [Proton-GE](https://github.com/gloriouseggroll/proton-ge-custom) can be used instead of Valve-Proton. Some games may only work with [Proton-10-GE](https://github.com/gloriouseggroll/proton-ge-custom).
* [Proton-GE](https://github.com/gloriouseggroll/proton-ge-custom) gets patched on launch with [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) just like Valve-Proton. [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases) supports [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) natively.
* `update-switch.sh` can be used to update all switchdeck scripts and parts of the steam client.
* `launch-steam.sh` contains several launch commands. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* `wineesync` is force-disabled in `launch-steam.sh` because it causes crashes with dxvk / vulkan.
* If a game crashes on launch try OpenGL instead: `PROTON_USE_WINED3D=1 %command%`.
* For older games, you may need to force Proton 10+ in the settings, as Steam often defaults to unsupported older versions.

---

## Explanation
This script downloads and installs the latest Steam ARM64 version.
Builds newer than April 15th, 2026, do not work on the Nintendo Switch, so this script will automatically downgrade parts of the client to that version to prevent "illegal instruction" crashes.
The L4T kernel (4.9) is too old to support FEX-Emu. Instead, this script sets up an x86_64 environment powered by Box64 to run x86_64 Proton builds.

*Credits to Ivy for the original steam-arm64 download script*

---

## Community & Support

* **[My Discord](https://discord.gg/EbsAecrVXg)** – My Discord for all my mods and projects.
* **[Twitter](https://x.com/SildurFX)** – Updates, clips, and general progress.
* **[Switchroot Discord](https://discord.gg/53mtKYt)** – For general L4T Linux help.
* **[Patreon](https://www.patreon.com/Sildur)** / **[PayPal](https://www.paypal.com/donate?token=_2027BoQI-5DqpHvI-Du7HX8MHdXJ5_vQ05_Owto9XiM8x3j76yxS1nevrBbpn5UV2yJfymQNmTsMPw6&locale.x=US)** – If you'd like to support my work!

---

### Legal Notice
The bash scripts (`launch-steam.sh`, etc.) in this repository are provided under the **GNU General Public License v3.0 (GPL-3.0)**.
The Steam binaries, libraries, and resources located in `/files/downgrade/` are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.
