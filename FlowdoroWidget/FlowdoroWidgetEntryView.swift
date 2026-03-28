import SwiftUI
import WidgetKit

struct FlowdoroWidgetEntryView: View {
    var entry: FlowdoroWidgetEntry

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.11, blue: 0.13)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                    Text("FLOWDORO")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .tracking(1.2)
                }

                Spacer()

                Text("\(entry.totalMinutesToday)")
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("min focused today")
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
