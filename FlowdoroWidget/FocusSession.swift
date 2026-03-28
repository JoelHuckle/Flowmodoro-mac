import Foundation

struct FocusSession: Codable {
    let duration: Int  // seconds
    let date: Date
}

enum FlowdoroShared {
    static let appGroupID  = "group.com.JoelHuckle.Flowdoro"
    static let sessionsKey = "focusSessions"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}
