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
4. Restart Steam to apply the [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek), [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) and Vertex Explosion patch to your Proton version. It's applied on launch.
5. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

**Note:** If Steam updates your Proton version you have to relaunch it to reapply the [DXVK-Sarek,](https://github.com/pythonlover02/DXVK-Sarek) [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) and Vertex Explosion patch. Use Proton 10 or [GE-Proton10](https://github.com/gloriouseggroll/proton-ge-custom) for 32-bit games, the Vertex Explosion patch is applied to both. 

---

## Requirements
* [Linux for Switch](https://wiki.switchroot.org/wiki/linux) (Fedora 42 or Ubuntu Noble)
* [Box64](https://github.com/ptitseb/box64) to run games. Shipped with Fedora 42 by default, install from this [repo](https://github.com/Pi-Apps-Coders/box64-debs) for Ubuntu.
* Vulkan 1.2 Support: Required by Steam and most games. On Ubuntu Noble, you must manually [update your GPU driver](https://pastebin.com/ScMRK37p). Fedora ships with the latest driver out of the box.
* **Recommended:** [RAM OC](https://wiki.switchroot.org/wiki/linux/linux-features#ram_oc0), the Switch shares 4GB between CPU and GPU so overclocking RAM helps a lot.

---

## Features
* `SWITCHDECK_GAMEMODE=1 or 2 %command%`. Launching Steam games with this command **frees up over 1GB of RAM**. In **Mode 1** it unloads steamwebhelper on game launch and restores it on exit, online multiplayer is still supported in this mode. In **Mode 2** it also stops KDE Plasma & background services. Restoring Steam or KDE after game exit is gonna take a few seconds.
* [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* [VKD3D v2.3.1](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) Patch for Steam Proton and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* Wine Vulkan extension patch for Proton 10 and [GE-Proton10](https://github.com/gloriouseggroll/proton-ge-custom) to fix Vertex explosions in 32-bit games, caused by broken nvidia drivers.
* KDE Context Menu: Add to Steam, to easily import non-Steam games.

---

## Information
* To update Switchdeck simply run `update-switchdeck.sh` in your Steam folder.
* Several launch commands are defined in `launch-steam.sh`. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* `wineesync` is disabled in `launch-steam.sh` because it causes crashes with dxvk / vulkan.
* If a game crashes on launch try OpenGL instead: `PROTON_USE_WINED3D=1 %command%`.
* [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos/releases) and [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom) can be used instead of Valve-Proton. Some games may only work with [GE-Proton](https://github.com/gloriouseggroll/proton-ge-custom).
* For older games, you may need to force Proton 10+ in the settings, as Steam often defaults to unsupported older versions.
* Game compatibility is inconsistent, not every title is supported or fully playable.
* The Switch only supports up to Vulkan 1.2, that's why [DXVK-Sarek](https://github.com/pythonlover02/DXVK-Sarek) and an old version of [VKD3D](https://github.com/HansKristian-Work/vkd3d-proton/releases/tag/v2.3.1) are patched in to Proton.

---

## Explanation
This script automates the download and installation of Steam ARM64. Because Steam client builds newer than April 15th, 2026, cause "illegal instruction" crashes on the Nintendo Switch, the script automatically downgrades specific parts of Steam to that version. The L4T kernel (4.9) is too old to support modern FEX-Emu translation layers, this setup establishes an alternative x86_64 environment powered by Box64 to run x86_64 Proton builds. It also applies custom compatibility patches to both native Proton and GE-Proton to ensure Vulkan 1.2 support and to disable a broken Vulkan extension, directly resolving vertex explosion bugs in 32-bit games on the Tegra X1.

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
