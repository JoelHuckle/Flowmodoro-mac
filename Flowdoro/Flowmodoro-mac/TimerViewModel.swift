import Foundation
import Observation
import Combine

@Observable
class TimerViewModel {
    private var timerCancellable: AnyCancellable?
    
    var state = TimerState.idle
    var elapsedSeconds: Int = 0
    var breakSecondsRemaining: Int = 0
    var breakRatio: Double = 5.0
        
    var formattedTime: String {
        //runs each time something accesses formattedTime
        switch state {
            case .idle: return "00:00"
            case .focusing: return String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
            case .onBreak: return String(format: "%02d:%02d", breakSecondsRemaining / 60, breakSecondsRemaining % 60)
        }
    }
    
    func startFocusing() {
        state = .focusing
        elapsedSeconds = 0
        
        startTimer()
    }
    
    func stopFocusing() {
        let breakSeconds = max(Int(Double(elapsedSeconds) / breakRatio), 60)
        breakSecondsRemaining = breakSeconds
        state = .onBreak(breakDuration: TimeInterval(breakSeconds))
    }
    
    func endBreak() {
        stopTimer()

        elapsedSeconds = 0
        breakSecondsRemaining = 0
        state = .idle
    }
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.tick()
            }
    }
    
    private func stopTimer() {
        timerCancellable = nil
    }
    
    private func tick() {
        switch state {
        case .idle:
            stopTimer()
            
        case .focusing:
            elapsedSeconds += 1
            
        case .onBreak:
            breakSecondsRemaining -= 1
            if breakSecondsRemaining <= 0 {
                endBreak()
            }
        }
    }
}
