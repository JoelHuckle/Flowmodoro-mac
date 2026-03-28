import WidgetKit
import Foundation

struct FlowdoroWidgetEntry: TimelineEntry {
    let date: Date
    let totalMinutesToday: Int
}

struct FlowdoroWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> FlowdoroWidgetEntry {
        FlowdoroWidgetEntry(date: Date(), totalMinutesToday: 45)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlowdoroWidgetEntry) -> Void) {
        completion(FlowdoroWidgetEntry(date: Date(), totalMinutesToday: todayMinutes()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlowdoroWidgetEntry>) -> Void) {
        let entry = FlowdoroWidgetEntry(date: Date(), totalMinutesToday: todayMinutes())
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func todayMinutes() -> Int {
        guard let data = FlowdoroShared.sharedDefaults?.data(forKey: FlowdoroShared.sessionsKey),
              let sessions = try? JSONDecoder().decode([FocusSession].self, from: data)
        else { return 0 }
        return sessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.duration } / 60
    }
}
