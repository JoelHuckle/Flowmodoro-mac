import Foundation
import Observation
import Combine
import UserNotifications

@Observable
class TimerViewModel {
    private var timerCancellable: AnyCancellable?
    
    var state = TimerState.idle
    var isPaused: Bool = false
    var elapsedSeconds: Int = 0
    var breakSecondsRemaining: Int = 0
    var breakRatio: Double = 5.0
    
    var formattedTime: String {
        switch state {
        case .idle: return "00:00"
        case .focusing: return String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
        case .onBreak: return String(format: "%02d:%02d", breakSecondsRemaining / 60, breakSecondsRemaining % 60)
        }
    }
    
    func togglePause() {
        guard state != .idle else { return }
        if isPaused {
            isPaused = false
            startTimer()
        } else {
            isPaused = true
            stopTimer()
        }
    }

    func startFocusing() {
        isPaused = false
        state = .focusing
        elapsedSeconds = 0
        startTimer()
    }
    
    func stopFocusing() {
        let breakSeconds = max(Int(Double(elapsedSeconds) / breakRatio), 60)
        breakSecondsRemaining = breakSeconds
        state = .onBreak(breakDuration: TimeInterval(breakSeconds))
        sendBreakNotification(breakSeconds: breakSeconds)
    }
    
    func endBreak() {
        isPaused = false
        stopTimer()
        breakSecondsRemaining = 0
        startFocusing()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.tick()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func tick() {
        switch state {
        case .idle:
            stopTimer()
        case .focusing:
            elapsedSeconds += 1
        case .onBreak:
            if breakSecondsRemaining > 0 {
                breakSecondsRemaining -= 1
            } else {
                sendBreakOverNotification()
                endBreak()
            }
        }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendBreakNotification(breakSeconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        content.body = "You focused for \(elapsedSeconds / 60) min. Take a \(breakSeconds / 60) min break."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "break-start", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendBreakOverNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break's over"
        content.body = "Ready to focus again?"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "break-end", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
