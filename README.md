# Cobalt for CodeX

Cobalt for CodeX is a small Windows theme installer for Codex Desktop. It applies a Cobalt-inspired dark blue UI surface, yellow accent color, and the `cobalt` code theme IDs to your local Codex configuration.

## Install

Double-click:

```text
Install Cobalt for CodeX.cmd
```

The installer will:

- Create `C:\Users\<you>\.codex\config.toml` if it does not exist.
- Back up the current config next to it before changing anything.
- Set Codex Desktop to dark mode.
- Apply the Cobalt surface, accent, semantic colors, and code theme IDs.
- Save the config as UTF-8 without BOM.

Restart Codex Desktop after installing so the title bar, sidebar, and conversation area can reload the theme.

## What It Changes

The installer updates only these Codex Desktop theme fields:

```toml
[desktop]
appearanceTheme = "dark"
appearanceLightCodeThemeId = "cobalt"
appearanceDarkCodeThemeId = "cobalt"

[desktop.appearanceLightChromeTheme]
accent = "#ffc600"
contrast = 55
ink = "#002240"
opaqueWindows = true
surface = "#f4f8ff"

[desktop.appearanceDarkChromeTheme]
accent = "#ffc600"
contrast = 65
ink = "#ffffff"
opaqueWindows = true
surface = "#002240"
```

The full theme fragment is available in `theme/cobalt-for-codex.toml`.

## Restore

The installer writes backups named like:

```text
config.toml.cobalt-for-codex-backup-YYYYMMDD-HHMMSS
```

To restore, replace `C:\Users\<you>\.codex\config.toml` with one of those backup files.

## Notes

Codex Desktop does not currently expose a public theme-package format. This project is therefore a practical installer that applies the same local configuration fields Codex Desktop already uses.
