import AppKit
import Foundation

enum SpotifyPlayerState: String {
    case playing
    case paused
    case stopped
}

struct SpotifyTrackState {
    let name: String
    let artist: String
    let trackId: String
    let durationMs: Int
    let positionSec: Double
    let playerState: SpotifyPlayerState
}

enum SpotifyStatus {
    case notRunning
    case noTrack
    case track(SpotifyTrackState)
}

final class SpotifyController {
    private static let bundleIdentifier = "com.spotify.client"

    private let script: NSAppleScript?

    init() {
        let source = """
        if application "Spotify" is running then
            tell application "Spotify"
                try
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackId to id of current track
                    set trackDuration to duration of current track
                    set pos to player position
                    set stateStr to player state as string
                    return trackName & "|||" & trackArtist & "|||" & trackId & "|||" & (trackDuration as string) & "|||" & (pos as string) & "|||" & stateStr
                on error errMsg
                    return "NO_TRACK: " & errMsg
                end try
            end tell
        else
            return "NOT_RUNNING"
        end if
        """
        self.script = NSAppleScript(source: source)
    }

    var isSpotifyRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.bundleIdentifier
        }
    }

    func poll() -> SpotifyStatus {
        guard isSpotifyRunning else { return .notRunning }
        guard let script else { return .noTrack }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        guard errorInfo == nil, let raw = result.stringValue else {
            return .noTrack
        }

        if raw == "NOT_RUNNING" { return .notRunning }
        if raw.hasPrefix("NO_TRACK") { return .noTrack }

        let parts = raw.components(separatedBy: "|||")
        guard parts.count == 6,
              let durationMs = Int(parts[3]),
              let positionSec = Double(parts[4].replacingOccurrences(of: ",", with: ".")),
              let playerState = SpotifyPlayerState(rawValue: parts[5]) else {
            return .noTrack
        }

        return .track(SpotifyTrackState(
            name: parts[0],
            artist: parts[1],
            trackId: parts[2],
            durationMs: durationMs,
            positionSec: positionSec,
            playerState: playerState
        ))
    }
}
