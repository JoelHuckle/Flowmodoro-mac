import WidgetKit
import SwiftUI

struct FlowdoroWidget: Widget {
    let kind = "FlowdoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowdoroWidgetProvider()) { entry in
            FlowdoroWidgetEntryView(entry: entry)
                .containerBackground(
                    Color(red: 0.10, green: 0.11, blue: 0.13),
                    for: .widget
                )
        }
        .configurationDisplayName("Flowdoro")
        .description("Today's total focused minutes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
