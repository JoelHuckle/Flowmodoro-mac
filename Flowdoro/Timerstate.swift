import Foundation

enum TimerState: Equatable {
    case idle
    case focusing
    case onBreak(breakDuration: TimeInterval)
}
