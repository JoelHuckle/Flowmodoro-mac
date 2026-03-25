import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    
    init<Content: View>(contentView: Content) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.becomesKeyOnlyIfNeeded = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .underWindowBackground
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20
        visualEffect.layer?.masksToBounds = true
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])
        
        self.contentView = visualEffect
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
