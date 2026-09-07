import Combine
import Foundation

enum DisplayState: Equatable {
    case status(String)
    case lyrics(current: String, upcoming: [String])
}

final class PlaybackViewModel: ObservableObject {
    @Published var displayState: DisplayState = .status("Waiting for Spotify…")
}
