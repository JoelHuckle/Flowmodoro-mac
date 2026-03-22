import Foundation

enum TimerState {
    case idle
    case focusing
    case onBreak(breakDuration: TimeInterval)
}
