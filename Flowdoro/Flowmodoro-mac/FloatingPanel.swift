import AppKit
import SwiftUI

// This is the core of "making it work like Flow's floating timer."
// NSPanel is a subclass of NSWindow designed for auxiliary/utility windows.
// It has special behaviours that NSWindow doesn't:
//   - Can float above other windows
//   - Can be configured to not steal focus (nonactivatingPanel)
//   - Can be a "utility panel" that hides with the app
//
// Think of NSWindow as a <div> and NSPanel as a <dialog> —
// same underlying thing but with different default behaviours.

class FloatingPanel: NSPanel {
    
    init<Content: View>(contentView: Content) {
        
        // NSRect.zero = start with no size, we'll set it in AppDelegate.
        // styleMask configures the window's behaviour:
        super.init(
            contentRect: NSRect.zero,
            
            // styleMask is a bitmask (like CSS classes combined with |).
            // Each option adds a behaviour:
            styleMask: [
                .borderless,            // No title bar, no close/minimize/zoom buttons
                .fullSizeContentView,   // Content fills the entire window frame
                .nonactivatingPanel,    // KEY: clicking this panel does NOT steal focus
                                        // from whatever app you're currently using.
                                        // Without this, clicking the timer would yank
                                        // you out of your code editor. Terrible UX.
            ],
            
            backing: .buffered,         // Standard double-buffered drawing
            defer: false                // Create the window immediately (don't wait)
        )
        
        // MARK: - Window behaviour configuration
        
        // Float above normal windows (but below alerts/sheets).
        // .floating is one of several levels:
        //   .normal (default) < .floating < .modalPanel < .mainMenu < .screenSaver
        self.level = .floating
        
        // Don't hide when the app is deactivated (user switches to another app).
        // Without this, the timer disappears every time you cmd+tab away. Useless.
        self.hidesOnDeactivate = false
        
        // Allow dragging by clicking anywhere on the window background.
        // Without this, there's no title bar to grab, so the user couldn't move it.
        self.isMovableByWindowBackground = true
        
        // Make the window background transparent so we can draw our own rounded shape.
        self.isOpaque = false
        self.backgroundColor = .clear
        
        // Allow the panel to become the "key" window (receive keyboard events)
        // even though it's non-activating. This matters if you add text fields later.
        self.becomesKeyOnlyIfNeeded = true
        
        // Prevent the panel from appearing in Mission Control / Exposé.
        self.collectionBehavior = [
            .canJoinAllSpaces,   // Show on all desktop Spaces (not just the one it was created in)
            .fullScreenAuxiliary // Don't interfere with full-screen apps
        ]
        
        // MARK: - Content setup
        
        // NSVisualEffectView gives us the macOS "frosted glass" background.
        // This is what makes it look native — like Spotlight, Control Center,
        // or... Flow's timer panel.
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow        // Dark translucent material
        visualEffect.state = .active               // Always show the effect (don't dim)
        visualEffect.blendingMode = .behindWindow  // Blur whatever's behind the window
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20      // Rounded corners
        visualEffect.layer?.masksToBounds = true    // Clip content to the rounded shape
        
        // NSHostingView bridges SwiftUI into AppKit.
        // It takes a SwiftUI View and wraps it so it can be used as an AppKit NSView.
        // This is how you put SwiftUI content inside an AppKit window.
        //
        // Think of it as: ReactDOM.render(<YourComponent />, appKitContainer)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the hosting view inside the visual effect view
        visualEffect.addSubview(hostingView)
        
        // Auto Layout constraints — the AppKit equivalent of CSS.
        // This pins the SwiftUI view to all edges of the visual effect view.
        // Like: position: absolute; top: 0; right: 0; bottom: 0; left: 0;
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])
        
        // Set the visual effect view as the window's content
        self.contentView = visualEffect
    }
    
    // MARK: - Overrides
    
    // Allow the panel to become the key window when clicked.
    // NSPanel normally refuses this — we override to allow keyboard input.
    override var canBecomeKey: Bool { true }
    
    // Prevent the panel from becoming the "main" window.
    // The main window gets the menu bar — we don't want that.
    override var canBecomeMain: Bool { false }
}
