import XCTest
@testable import DesktopKaraoke

final class LyricsServiceTests: XCTestCase {
    private let sampleLRC = """
    [ti:Test Song]
    [ar:Test Artist]
    [00:12.34]First line
    [00:16.80]Second line
    [00:21.05]Third line
    """

    func testParseLRCExtractsTimestampsAndText() {
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].text, "First line")
        XCTAssertEqual(lines[0].time, 12.34, accuracy: 0.001)
        XCTAssertEqual(lines[1].time, 16.80, accuracy: 0.001)
        XCTAssertEqual(lines[2].time, 21.05, accuracy: 0.001)
    }

    func testCurrentIndexBeforeFirstLineIsNil() {
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertNil(lines.currentIndex(at: 0))
        XCTAssertNil(lines.currentIndex(at: 12.0))
    }

    func testCurrentIndexAtExactBoundary() {
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertEqual(lines.currentIndex(at: 12.34), 0)
        XCTAssertEqual(lines.currentIndex(at: 16.80), 1)
        XCTAssertEqual(lines.currentIndex(at: 999), 2)
    }

    func testUpcomingReturnsNextLines() {
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertEqual(lines.upcoming(after: nil, count: 2), ["First line", "Second line"])
        XCTAssertEqual(lines.upcoming(after: 0, count: 2), ["Second line", "Third line"])
    }

    func testUpcomingTruncatesNearEndOfSong() {
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertEqual(lines.upcoming(after: 1, count: 2), ["Third line"])
        XCTAssertEqual(lines.upcoming(after: 2, count: 2), [])
    }

    func testDisplayStateForSyncedLyrics() {
        let lines = LyricsService.parseLRC(sampleLRC)
        guard case .lyrics(let current, let upcoming) = displayState(for: .synced(lines), position: 17.0) else {
            return XCTFail("expected .lyrics")
        }
        XCTAssertEqual(current, "Second line")
        XCTAssertEqual(upcoming, ["Third line"])
    }

    func testDisplayStateForPlainOnlyLyrics() {
        guard case .status(let text) = displayState(for: .plainOnly("some lyrics"), position: 0) else {
            return XCTFail("expected .status")
        }
        XCTAssertEqual(text, "Lyrics found, but not synced")
    }

    func testDisplayStateForNotFoundIsNil() {
        XCTAssertNil(displayState(for: .notFound, position: 0))
    }
}
