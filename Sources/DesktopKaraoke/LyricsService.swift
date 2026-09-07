import Foundation

struct LyricLine {
    let time: TimeInterval
    let text: String
}

struct LrcLibResponse: Decodable {
    let plainLyrics: String?
    let syncedLyrics: String?
}

enum LyricsResult {
    case synced([LyricLine])
    case plainOnly(String)
    case notFound
}

final class LyricsService {
    private let session = URLSession(configuration: .ephemeral)

    func fetchLyrics(artist: String, title: String, durationMs: Int) async -> LyricsResult {
        var components = URLComponents(string: "https://lrclib.net/api/get")!
        components.queryItems = [
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "duration", value: String(durationMs / 1000))
        ]

        guard let url = components.url else { return .notFound }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .notFound
            }
            let decoded = try JSONDecoder().decode(LrcLibResponse.self, from: data)

            if let synced = decoded.syncedLyrics, !synced.isEmpty {
                return .synced(Self.parseLRC(synced))
            } else if let plain = decoded.plainLyrics, !plain.isEmpty {
                return .plainOnly(plain)
            } else {
                return .notFound
            }
        } catch {
            return .notFound
        }
    }

    private static let lrcTimeRegex = try! NSRegularExpression(pattern: #"\[(\d{2}):(\d{2})\.(\d{2,3})\]"#)

    static func parseLRC(_ text: String) -> [LyricLine] {
        var lines: [LyricLine] = []

        for rawLine in text.components(separatedBy: .newlines) {
            let nsLine = rawLine as NSString
            let matches = lrcTimeRegex.matches(in: rawLine, range: NSRange(location: 0, length: nsLine.length))
            guard let lastMatch = matches.last else { continue }

            let minutes = Double(nsLine.substring(with: lastMatch.range(at: 1))) ?? 0
            let seconds = Double(nsLine.substring(with: lastMatch.range(at: 2))) ?? 0
            let fractionStr = nsLine.substring(with: lastMatch.range(at: 3))
            let fraction = Double(fractionStr) ?? 0
            let fractionScale = pow(10.0, Double(fractionStr.count))
            let time = minutes * 60 + seconds + (fraction / fractionScale)

            let textStart = lastMatch.range.location + lastMatch.range.length
            let lyricText = nsLine.substring(from: textStart).trimmingCharacters(in: .whitespaces)

            lines.append(LyricLine(time: time, text: lyricText))
        }

        return lines.sorted { $0.time < $1.time }
    }
}

extension Array where Element == LyricLine {
    func currentIndex(at position: TimeInterval) -> Int? {
        var result: Int? = nil
        for (index, line) in enumerated() {
            if line.time <= position {
                result = index
            } else {
                break
            }
        }
        return result
    }

    func upcoming(after index: Int?, count: Int) -> [String] {
        let start = (index ?? -1) + 1
        guard start < self.count else { return [] }
        let end = Swift.min(start + count, self.count)
        return self[start..<end].map { $0.text }
    }
}
