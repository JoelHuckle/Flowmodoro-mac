import AppKit
import SwiftUI
import Observation
import Combine

// MARK: - Status bar timer view

private func makeStatusImage(for time: String) -> NSImage {
    let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let str = time as NSString
    let textSize = str.size(withAttributes: attrs)

    let hPad: CGFloat = 7
    let vPad: CGFloat = 3
    let cornerRadius: CGFloat = 6
    let lineWidth: CGFloat = 1.0
    let size = NSSize(width: ceil(textSize.width) + hPad * 2,
                      height: ceil(textSize.height) + vPad * 2)

    let image = NSImage(size: size, flipped: false) { rect in
        // Border
        let borderRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = NSBezierPath(roundedRect: borderRect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.white.setStroke()
        path.lineWidth = lineWidth
        path.stroke()

        // Text centred
        let textPoint = NSPoint(x: (rect.width - textSize.width) / 2,
                                y: (rect.height - textSize.height) / 2)
        str.draw(at: textPoint, withAttributes: attrs)
        return true
    }
    image.isTemplate = false
    return image
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    var timerVM = TimerViewModel()
    private var floatingPanel: FloatingPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupPanel()
        setupStatusItem()
        startObserving()
        timerVM.requestNotificationPermission()
    }

    // MARK: - Panel

    private func setupPanel() {
        var panel: FloatingPanel!
        let timerView = FloatingTimerView(timerVM: timerVM, onClose: {
            panel?.orderOut(nil)
        })
        panel = FloatingPanel(contentView: timerView)

        if let screenFrame = NSScreen.main?.visibleFrame {
            let panelWidth: CGFloat = 340
            let panelHeight: CGFloat = 280
            let x = screenFrame.maxX - panelWidth - 40
            let y = screenFrame.maxY - panelHeight - 40
            panel.setFrame(
                NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
                display: true
            )
        }

        panel.orderFront(nil)
        self.floatingPanel = panel
    }

    func togglePanel() {
        guard let panel = floatingPanel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFront(nil)
        }
    }

    var isPanelVisible: Bool {
        floatingPanel?.isVisible ?? false
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Quit Flowdoro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem?.popUpMenu(menu)
        } else {
            togglePanel()
        }
    }

    // MARK: - Live image observation

    private func startObserving() {
        func observe() {
            withObservationTracking {
                let image = makeStatusImage(for: self.timerVM.formattedTime)
                self.statusItem?.button?.image = image
                self.statusItem?.button?.title = ""
            } onChange: {
                DispatchQueue.main.async { observe() }
            }
        }
        observe()
    }
}
