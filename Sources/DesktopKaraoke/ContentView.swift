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
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .textShadow()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .lyrics(let current, let upcoming):
            VStack(spacing: 12) {
                Text(current)
                    .id(current)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .textShadow()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))

                ForEach(Array(upcoming.enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
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
