import SwiftUI

@main
struct FlowdoroApp: App {
    @State private var timerVM = TimerViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            switch timerVM.state {
                case .idle:
                    Button("Start Focus"){
                        timerVM.startFocusing()
                    }
                case .focusing:
                    Button("Stop Focus"){
                        timerVM.stopFocusing()
                    }
                case .onBreak:
                    Button("Skip Break") {
                        timerVM.endBreak()
                }
            }
            Button("Quit Flowdoro") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Text(timerVM.formattedTime)
        }
        .menuBarExtraStyle(.menu)
    }
}
