<p align="center">
  <img src="Design/AppIconSource.svg" width="120" height="120" alt="Desktop Karaoke icon">
</p>

<h1 align="center">Desktop Karaoke</h1>

<p align="center">
  A native macOS menu bar app that shows synced, line-by-line lyrics for whatever's
  playing in Spotify — a personal karaoke teleprompter that floats over your desktop.
</p>

## What it does

Desktop Karaoke watches the Spotify desktop app for what's currently playing and
displays time-synced lyrics in a small, transparent, draggable floating panel. The
current line is shown large, with the next two lines dimmed below, sliding into place
as the track progresses.

- Lives in the menu bar only — no Dock icon, no window chrome.
- Reads playback directly from the local Spotify app (not the Spotify Web API), so it
  needs no login or OAuth.
- Lyrics are fetched from [lrclib.net](https://lrclib.net); synced (LRC) lyrics drive
  the line-by-line highlighting, falling back to plain text or "not found" when
  unavailable.
- Everything runs locally — no server, no account, no telemetry.

## Installing

Download the latest signed, notarized build from [the website](https://shubhamzanwar.com/desktop-karaoke/) and drag it to
`/Applications`. On first launch, macOS will ask you to grant Automation permission so
the app can read what's playing in Spotify — without it, the app just shows "No track
playing."

## Building from source

Requires macOS 13+ and Swift 5.9+. There's no Xcode project — this is a plain Swift
Package Manager executable.

```bash
swift build
swift test
.build/arm64-apple-macosx/debug/DesktopKaraoke
```

See [CLAUDE.md](CLAUDE.md) for architecture notes and known gotchas.

## Packaging a release

```bash
Packaging/package-app.sh <version>   # e.g. Packaging/package-app.sh 1.0.1
```

Builds a release binary, assembles the `.app`, codesigns it with a Developer ID
certificate, submits it for notarization, staples the ticket, and produces a ready-to
-distribute `.dmg` in `dist/`.

## License

The bundled [Fredoka](Sources/DesktopKaraoke/Resources/Fonts/OFL.txt) font is licensed
under the SIL Open Font License.
