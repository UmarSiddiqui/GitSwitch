<p align="center">
  <img src="assets/banner.png" alt="GitSwitch Banner" width="100%">
</p>

<h1 align="center">GitSwitch</h1>

<p align="center">
  <b>Minimalistic macOS menu-bar app for switching between GitHub profiles</b>
</p>

<p align="center">
  <a href="https://github.com/umarsiddiqui/GitSwitch/stargazers">
    <img src="https://img.shields.io/github/stars/umarsiddiqui/GitSwitch?style=flat-square&color=brightgreen" alt="Stars">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/platform-macOS%2014+-lightgrey.svg?style=flat-square&logo=apple" alt="Platform">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/swift-5.9+-FA7343.svg?style=flat-square&logo=swift" alt="Swift">
  </a>
  <a href="https://github.com/umarsiddiqui/GitSwitch/releases">
    <img src="https://img.shields.io/badge/release-v1.0-blue.svg?style=flat-square" alt="Latest Release">
  </a>
</p>

---

## Features

- 🚀 **One-click profile switching** from the menu bar
- 🔍 **Auto-scan existing accounts** — detects GitHub CLI logins, SSH keys, and Git configs in one click
- 🔑 **Automatic SSH key rotation** — swaps keys instantly
- ⚙️ **Global git config switching** — updates name & email automatically
- 🔗 **One-click GitHub auth** — authorize via browser or copy SSH key straight to GitHub settings
- 🎨 **Minimalistic native macOS design** — feels right at home on your Mac
- 🌓 **Light & Dark mode support** — adapts to your system appearance
- 🔒 **HTTPS→SSH URL rewriting** — ensures all remotes use the right key
- ➕ **Easy profile add/edit/delete** — manage identities in seconds

## Screenshots

<p align="center">
  <img src="assets/screenshot-menubar.png" alt="Menu Bar" width="45%">
  &nbsp;&nbsp;
  <img src="assets/screenshot-settings.png" alt="Settings" width="45%">
</p>

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=umarsiddiqui/gitswitch&type=Date)](https://star-history.com/#umarsiddiqui/gitswitch&Date)

## 📥 Download

**[⬇ Download GitSwitch.app.zip](../../raw/main/GitSwitch.app.zip)**

> **Latest build:** includes all fixes up to the current `main` branch.

## Installation

1. **Download** `GitSwitch.app.zip` using the link above (or from the [Releases](https://github.com/umarsiddiqui/GitSwitch/releases) page)
2. **Unzip** it and drag `GitSwitch.app` to your **Applications** folder (or run directly from Desktop)
3. **Right-click → Open** to bypass Gatekeeper on first launch
4. Look for the indigo icon in your menu bar — you're ready to go!

> **Note:** GitSwitch requires macOS 14.0 or later.

## Usage

- **Click** the menu bar icon to see your configured profiles
- **Click** a profile to instantly switch your Git identity
- **Click** **Settings…** to add, edit, or remove profiles

### Default Profiles

| Profile | Username | Email | SSH Key |
|---------|----------|-------|---------|
| Personal | `umarsiddiqui` | `your-personal@email.com` | `~/.ssh/id_rsa_personal` |
| Work | `umar-abweb` | `your-work@email.com` | `~/.ssh/id_rsa_work` |

## How It Works

When you pick a profile from the menu bar or Settings, GitSwitch runs a single switch pipeline (after checking that the profile’s SSH private key file exists):

1. **Global Git identity** — runs `git config --global user.name` and `user.email` so new commits use that profile’s name and email.
2. **HTTPS → SSH for GitHub** — sets `url.git@github.com:.insteadOf` to `https://github.com/` so existing HTTPS remotes are rewritten to SSH and use the active key.
3. **GitHub CLI (optional)** — if the `gh` command is installed, runs `gh auth switch --user <username>` so CLI actions match the profile.
4. **`~/.ssh/config` for GitHub** — updates or creates the `Host github.com` block so `IdentityFile` points at that profile’s private key.
5. **SSH agent** — runs `ssh-add -D` (clear identities), then `ssh-add` on the new key so authentication uses the right material.

Profiles, labels, and paths are stored in **UserDefaults** (`gitswitch_profiles`). On first launch, the app seeds example profiles you can edit in Settings.

On startup, GitSwitch tries to **detect the active profile** by comparing global `user.name` / `user.email` and the current `IdentityFile` for `github.com` in `~/.ssh/config`.

## Tech Stack

| Technology | Purpose |
|------------|---------|
| **Swift 5.9** | Core language |
| **SwiftUI + MenuBarExtra** | Native macOS UI |
| **Combine** | Reactive state management (`ObservableObject`) |
| **URLSession** | Future network operations |

## Contributing

Contributions are welcome! Whether it's a bug fix, a new feature, or documentation improvements — every pull request helps.

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-idea`)
3. Make your changes
4. Commit (`git commit -m 'Add amazing idea'`)
5. Push (`git push origin feature/amazing-idea`)
6. Open a Pull Request

Please make sure your code follows the existing style and includes appropriate tests where applicable.

## License

This project is licensed under the [MIT License](LICENSE) — see the file for details.

---

<p align="center">
  Crafted with ☕ by <a href="https://github.com/umarsiddiqui">Umar Siddiqui</a>
</p>
