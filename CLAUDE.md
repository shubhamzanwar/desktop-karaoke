# Desktop Karaoke

A native macOS menu bar utility (Swift + AppKit/SwiftUI, no Dock icon) that reads what's
currently playing in the Spotify desktop app and shows synced, line-by-line lyrics in a
transparent, draggable floating panel — like a personal karaoke teleprompter.

## Architecture

- **No server/backend.** Everything runs locally; the only network calls are direct,
  unauthenticated requests to lrclib.net for lyrics.
- **Now-playing data** comes from the Spotify macOS app via AppleScript (`NSAppleScript`,
  in-process — not spawned `osascript`), not the Spotify Web API. This means it only
  reflects local desktop-app playback, not other Spotify Connect devices, but needs no
  OAuth/login flow.
- **Lyrics** come from lrclib.net (`LyricsService.swift`), looked up by artist/title/duration.
  Synced (time-tagged, LRC format) lyrics drive the line highlighting; falls back to
  plain/unsynced text or "not found" if lrclib has nothing for a track.
- **UI** is a borderless, transparent, always-on-top `NSPanel` (`LyricsPanel.swift`) with
  fixed dimensions — it never resizes itself (that caused real bugs, see Gotchas) — and is
  dragged via a custom `NSHostingView` subclass that forwards `mouseDown` to
  `window.performDrag`. Content is SwiftUI (`ContentView.swift`): the current lyric line on
  top, next two lines dimmed below, sliding/fading between lines via `.transition`.
- **Polling loop** (`AppDelegate.swift`) ticks every 300ms: poll Spotify → detect track
  change → fetch lyrics if needed → compute display state from lyrics + position → update
  the view model only if the state actually changed (unnecessary `setDisplay` calls were a
  real source of animation bugs, see Gotchas).

### Key files
- `SpotifyController.swift` — AppleScript polling + **pure** response parsing
  (`SpotifyController.parse(_:)`), unit-testable without a running Spotify.
- `LyricsService.swift` — lrclib.net client, LRC parsing, and the **pure**
  `displayState(for:position:)` decision function shared between the poll loop and the
  async lyrics-fetch callback.
- `AppDelegate.swift` — owns all mutable state (current track, current lyrics, the poll
  timer) and wires the above together; deliberately thin/imperative, with the actual logic
  extracted into the pure functions above so it's testable.
- `PlaybackViewModel.swift` / `ContentView.swift` / `LyricsPanel.swift` — the UI layer.
- `FontLoader.swift` — registers the bundled Fredoka font at runtime via CoreText (no
  Info.plist font registration, since this isn't a bundled `.app`).

## Build, run, test

```bash
swift build
swift test
.build/arm64-apple-macosx/debug/DesktopKaraoke   # run directly; it's a plain executable, not a .app bundle
```

First run will prompt for Automation permission ("wants to control Spotify") — without
granting it, AppleScript calls silently fail and the app just shows "No track playing".

There's no Xcode project; this is a pure Swift Package executable. `Design/` holds the
source SVGs and the built `.icns`, kept outside `Sources/` so SPM doesn't require declaring
them as target resources.

## Gotchas already hit (don't reintroduce these)

- **AppleScript reserved words:** a bare variable named `st` fails to compile as an
  AppleScript identifier (`Expected expression but found "st"`) even outside any
  Spotify-specific context. Don't assume short variable names are safe in embedded
  AppleScript.
- **Locale-formatted numbers:** Spotify's AppleScript `player position` is locale-formatted
  (e.g. `33,57` on comma-decimal systems), so `Double(_:)` can silently fail. Always
  normalize (`replacingOccurrences(of: ",", with: ".")`) before parsing.
- **Non-atomic multi-property AppleScript reads:** `SpotifyController`'s script issues five
  separate `X of current track` reads in one `tell` block. Each is its own Apple Event
  round-trip, so a track change mid-poll can produce a mixed snapshot (e.g. old name paired
  with new track id). This is a known, not-yet-fixed source of an occasional stale-title
  display bug when switching tracks quickly. If revisiting, prefer a single compound
  property read (e.g. `properties of current track`) to make the read atomic.
- **Don't resize the floating panel programmatically.** An earlier version resized the
  `NSPanel` to fit content on every lyric-line change; a content-view/window sync bug made
  it drift and eventually fly off-screen. The panel is now a fixed size, dragged only by the
  user; the "roller" line animation happens entirely inside SwiftUI via `.clipped()`, never
  by resizing the window.
- **Don't animate/update on every poll tick.** `setDisplay` only applies `withAnimation` when
  the new `DisplayState` actually differs from the current one (`Equatable` check) — without
  that guard, the UI re-triggers its transition ~3x/second regardless of whether the lyric
  line changed, causing a visible "bounce".
- **Pausing freezes the display, it doesn't announce "Paused".** `tick()` intentionally
  returns early (no-op) when `playerState != .playing`, leaving whatever was last shown —
  this is deliberate ("freeze on the last lyric line"), not a missed case.
