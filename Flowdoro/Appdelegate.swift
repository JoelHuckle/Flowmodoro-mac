import AppKit
import SwiftUI
import Observation
import Combine

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
        button.title = timerVM.formattedTime
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

    // MARK: - Live title observation

    private func startObserving() {
        func observe() {
            withObservationTracking {
                self.statusItem?.button?.title = self.timerVM.formattedTime
            } onChange: {
                DispatchQueue.main.async { observe() }
            }
        }
        observe()
    }
}
