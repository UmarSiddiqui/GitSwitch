# Contributing to GitSwitch

Thanks for helping improve GitSwitch. Small, focused changes are easiest to review and ship.

## Project layout

- **Main UI and app entry:** `src/` — `GitSwitchApp.swift`, `MenuBarView.swift`, `ContentView.swift`, plus `Views/` and `Utils/`
- **Xcode project:** `GitSwitch.xcodeproj`

## Getting started

1. Clone the repository (see the canonical URL in [README.md](README.md)).
2. Open `GitSwitch.xcodeproj` in Xcode.
3. Select the **GitSwitch** scheme and run (**⌘R**).

## Building from the command line

**Debug**

```bash
xcodebuild -scheme GitSwitch -configuration Debug -destination 'platform=macOS' build
```

**Release** (unsigned local build)

```bash
xcodebuild -scheme GitSwitch -configuration Release -destination 'platform=macOS' build
```

The built app is under `build/` (exact path appears in the Xcode build log).

## Pull requests

- Keep diffs **focused** on one concern (bugfix, single feature, or doc update).
- Match existing Swift style and patterns in `src/`.
- If you change behavior, say **what** you changed and **why** in the PR description.
- Run a local **Debug** build before opening a PR (command above).

## Code of conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/) code of conduct. Be respectful and constructive in issues and PRs.
