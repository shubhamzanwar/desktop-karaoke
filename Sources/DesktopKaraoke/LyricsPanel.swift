import AppKit
import SwiftUI

/// A view that lets the user drag the whole (transparent) window by clicking
/// anywhere on it, since `isMovableByWindowBackground` alone only works over
/// opaque pixels.
final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

final class LyricsPanel: NSPanel {
    static let panelSize = NSSize(width: 480, height: 160)

    init(viewModel: PlaybackViewModel) {
        let contentRect = NSRect(origin: .zero, size: Self.panelSize)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        let hostingView = DraggableHostingView(rootView: ContentView(viewModel: viewModel))
        hostingView.frame = self.contentRect(forFrameRect: frame)
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
