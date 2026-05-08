# Switchdeck: Steam ARM64 for Linux ARM64 devices

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
4. To launch Steam, use `launch-steam.sh` in your Steam folder or use the provided shortcuts.

---

## Information
* **Games** can be launched with: `SWITCHDECK_GAMEMODE=1 or 2 %command%`. This is a unique Switchdeck feature that **frees up 1GB+ of RAM** while keeping Steam Input and Multiplayer functional.
* In **Mode 1** it unloads steamwebhelper on launch and restores it on exit. In **Mode 2** it also stops KDE Plasma & background services. It will take a few seconds to restore Steam or KDE after the game exits.
* `launch-steam.sh` contains several launch commands. Feel free to tweak them to fit your needs. Changing `STEAMDECK_MODE="false"` to `true` at the top enables steamdeck / big picture mode.
* For older games, you may need to force Proton 10+ in the settings, as Steam often defaults to unsupported older versions.

---

## Explanation
This script downloads and installs the latest Steam ARM64 version.

*Credits to Ivy for the original steam-arm64 download script*

---

## Community & Support

* **[My Discord](https://discord.gg/EbsAecrVXg)** – My Discord for all my mods and projects.
* **[Twitter](https://x.com/SildurFX)** – Updates, clips, and general progress.
* **[Patreon](https://www.patreon.com/Sildur)** / **[PayPal](https://www.paypal.com/donate?token=_2027BoQI-5DqpHvI-Du7HX8MHdXJ5_vQ05_Owto9XiM8x3j76yxS1nevrBbpn5UV2yJfymQNmTsMPw6&locale.x=US)** – If you'd like to support my work!

---

### Legal Notice
The bash scripts (`launch-steam.sh`, etc.) in this repository are provided under the **GNU General Public License v3.0 (GPL-3.0)**.
The Steam binaries, libraries are the proprietary property of **Valve Corporation**. These files are **NOT** covered by any open-source license and are subject to the [Steam Subscriber Agreement (SSA)](https://store.steampowered.com/subscriber_agreement).
This project is **not** affiliated with, maintained by, or endorsed by Valve Corporation. It is provided "as-is" for the sole purpose of maintaining ARM64 compatibility for the Nintendo Switch (L4T) community.
