import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: LyricsPanel?
    private let viewModel = PlaybackViewModel()

    private let spotify = SpotifyController()
    private let lyricsService = LyricsService()

    private var pollTimer: Timer?
    private var currentTrackId: String?
    private var currentLyrics: LyricsResult = .notFound

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        FontLoader.registerBundledFonts()
        setupStatusItem()
        setupPanel()
        startPolling()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Desktop Karaoke")
            button.target = self
            button.action = #selector(togglePanel)
        }
        statusItem = item
    }

    private func setupPanel() {
        let panel = LyricsPanel(viewModel: viewModel)
        if let screenFrame = NSScreen.main?.visibleFrame {
            let margin: CGFloat = 20
            let x = screenFrame.maxX - panel.frame.width - margin
            let y = screenFrame.maxY - panel.frame.height - margin
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        self.panel = panel
    }

    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        switch spotify.poll() {
        case .notRunning:
            resetTrack()
            setDisplay(.status("Spotify isn't running"))

        case .noTrack:
            resetTrack()
            setDisplay(.status("No track playing"))

        case .track(let state):
            if state.playerState != .playing {
                // Leave the display exactly as it was — freeze on the
                // last-shown lyric line instead of overwriting it.
                return
            }

            if state.trackId != currentTrackId {
                currentTrackId = state.trackId
                currentLyrics = .notFound
                setDisplay(.status("\(state.name) — \(state.artist)"))
                fetchLyrics(for: state)
            } else {
                updateDisplay(for: state.positionSec)
            }
        }
    }

    private func fetchLyrics(for state: SpotifyTrackState) {
        let trackId = state.trackId
        Task {
            let result = await lyricsService.fetchLyrics(
                artist: state.artist,
                title: state.name,
                durationMs: state.durationMs
            )
            await MainActor.run {
                guard trackId == self.currentTrackId else { return }
                self.currentLyrics = result
                self.updateDisplay(for: state.positionSec)
            }
        }
    }

    private func updateDisplay(for position: TimeInterval) {
        guard let display = displayState(for: currentLyrics, position: position) else { return }
        setDisplay(display)
    }

    private func resetTrack() {
        currentTrackId = nil
        currentLyrics = .notFound
    }

    private func setDisplay(_ state: DisplayState) {
        guard state != viewModel.displayState else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.displayState = state
        }
    }
}
