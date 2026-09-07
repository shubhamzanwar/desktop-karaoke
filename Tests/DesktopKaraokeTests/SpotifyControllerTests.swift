import XCTest
@testable import DesktopKaraoke

final class SpotifyControllerTests: XCTestCase {
    func testParsesNotRunning() {
        XCTAssertEqual(SpotifyController.parse("NOT_RUNNING"), .notRunning)
    }

    func testParsesNoTrack() {
        XCTAssertEqual(SpotifyController.parse("NO_TRACK: some AppleScript error"), .noTrack)
    }

    func testParsesMalformedResponseAsNoTrack() {
        XCTAssertEqual(SpotifyController.parse("only|||two"), .noTrack)
    }

    func testParsesValidTrackWithDotDecimalPosition() {
        let raw = "Iris|||The Goo Goo Dolls|||spotify:track:123|||289533|||161.044|||playing"
        guard case .track(let state) = SpotifyController.parse(raw) else {
            return XCTFail("expected .track")
        }
        XCTAssertEqual(state.name, "Iris")
        XCTAssertEqual(state.artist, "The Goo Goo Dolls")
        XCTAssertEqual(state.trackId, "spotify:track:123")
        XCTAssertEqual(state.durationMs, 289533)
        XCTAssertEqual(state.positionSec, 161.044, accuracy: 0.0001)
        XCTAssertEqual(state.playerState, .playing)
    }

    func testParsesValidTrackWithCommaDecimalPosition() {
        // Regression test: comma-decimal locales previously caused Double(_:)
        // to silently fail, making every track look like "no track playing".
        let raw = "Choosin' Texas|||Ella Langley|||spotify:track:abc|||231746|||33,569999694824|||playing"
        guard case .track(let state) = SpotifyController.parse(raw) else {
            return XCTFail("expected .track")
        }
        XCTAssertEqual(state.positionSec, 33.569999694824, accuracy: 0.0001)
    }

    func testParsesPausedState() {
        let raw = "Song|||Artist|||id|||1000|||5.0|||paused"
        guard case .track(let state) = SpotifyController.parse(raw) else {
            return XCTFail("expected .track")
        }
        XCTAssertEqual(state.playerState, .paused)
    }
}
