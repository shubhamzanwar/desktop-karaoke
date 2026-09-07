import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PlaybackViewModel

    var body: some View {
        content
            .frame(width: LyricsPanel.panelSize.width, height: LyricsPanel.panelSize.height)
            .clipped()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.displayState {
        case .status(let text):
            Text(text)
                .font(.fredoka(size: 20, weight: .semiBold))
                .foregroundColor(.white)
                .textShadow()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .lyrics(let current, let upcoming):
            VStack(spacing: 12) {
                Text(current)
                    .id(current)
                    .font(.fredoka(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .textShadow()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                ForEach(Array(upcoming.enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.fredoka(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(index == 0 ? 0.4 : 0.25))
                        .textShadow()
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 20)
        }
    }
}

private extension View {
    func textShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.9), radius: 1, x: 0, y: 0)
            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 1)
    }
}

extension Font {
    enum FredokaWeight: String {
        case regular = "Fredoka-Regular"
        case medium = "Fredoka-Medium"
        case semiBold = "Fredoka-SemiBold"
        case bold = "Fredoka-Bold"
    }

    /// SwiftUI's `.weight()` modifier is ignored on custom fonts, so each
    /// weight needs its own named-instance PostScript name from the
    /// variable font.
    static func fredoka(size: CGFloat, weight: FredokaWeight) -> Font {
        .custom(weight.rawValue, size: size)
    }
}
