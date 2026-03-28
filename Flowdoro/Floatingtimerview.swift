import SwiftUI

struct FloatingTimerView: View {
    var timerVM: TimerViewModel
    var onClose: () -> Void
    @State private var isHovering = false
    @State private var skipAnimating = false
    @State private var animatedBreakProgress: Double = 0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0
    @State private var immediateIconName: String? = nil
    @State private var arcOpacity: Double = 1.0
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var customRatioText = ""
    @State private var ratioInputInvalid = false
    @State private var invalidShakeOffset: CGFloat = 0
    @State private var barsVisible = false

    private let presetRatios = [3.0, 4.0, 5.0, 6.0, 8.0]
    private var isCustomRatio: Bool {
        !presetRatios.contains(timerVM.breakRatio)
    }

    private var backgroundColor: Color {
        if case .onBreak = timerVM.state {
            return Color(red: 0.07, green: 0.20, blue: 0.38)
        }
        return Color(red: 0.10, green: 0.11, blue: 0.13)
    }

    private var stateKey: String {
        switch timerVM.state {
        case .idle: return "idle"
        case .focusing: return "focusing"
        case .onBreak: return "break"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .animation(.easeInOut(duration: 0.5), value: stateKey)

            if showSettings {
                settingsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if showLeaderboard {
                leaderboardView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    mainContent
                    Spacer()
                    actionButton
                        .padding(.bottom, 28)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSettings)
        .animation(.easeInOut(duration: 0.3), value: showLeaderboard)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)

            Spacer()

            Button(action: {
                customRatioText = ""
                withAnimation(.easeInOut(duration: 0.3)) { showSettings = true }
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) { showLeaderboard = true }
            }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)

            Button(action: {
                if timerVM.state == .idle {
                    timerVM.startFocusing()
                } else {
                    timerVM.togglePause()
                }
            }) {
                Image(systemName: topBarIconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                    .contentTransition(.symbolEffect(.replace.downUp))
                    .animation(.easeInOut(duration: 0.2), value: topBarIconName)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(height: 44)
    }

    private var topBarIconName: String {
        switch timerVM.state {
        case .idle: return "play.fill"
        case .focusing, .onBreak: return timerVM.isPaused ? "play.fill" : "pause.fill"
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 10) {
            Text(modeLabel)
                .font(.system(size: 18, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(timerVM.formattedTime)
                .font(.system(size: 70, weight: .semibold, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .animation(nil, value: timerVM.formattedTime)
        }
    }

    // MARK: - Settings view

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { showSettings = false }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()
                Color.clear.frame(width: 22, height: 22)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Break ratio
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Break ratio")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Minutes of break per minutes of focus")
                        .font(.system(size: 12, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Presets + custom chip
                HStack(spacing: 7) {
                    ForEach(presetRatios, id: \.self) { ratio in
                        let selected = timerVM.breakRatio == ratio
                        Button("1:\(Int(ratio))") {
                            timerVM.breakRatio = ratio
                            customRatioText = ""
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(selected ? 1.0 : 0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.white.opacity(selected ? 0.18 : 0.07))
                        )
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selected)
                    }

                    if isCustomRatio {
                        let label = timerVM.breakRatio.truncatingRemainder(dividingBy: 1) == 0
                            ? "1:\(Int(timerVM.breakRatio))"
                            : "1:\(String(format: "%.1f", timerVM.breakRatio))"
                        Text(label)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.white.opacity(0.18))
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCustomRatio)

                // Custom input
                HStack(spacing: 8) {
                    Text("Custom  1:")
                        .font(.system(size: 13, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    TextField("e.g. 7", text: $customRatioText)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(ratioInputInvalid ? Color.red : .white)
                        .frame(width: 52)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(ratioInputInvalid
                                      ? Color.red.opacity(0.18)
                                      : Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.red.opacity(ratioInputInvalid ? 0.7 : 0), lineWidth: 1)
                        )
                        .offset(x: invalidShakeOffset)
                        .onSubmit {
                            if let value = Double(customRatioText), value > 0 {
                                timerVM.breakRatio = value
                                ratioInputInvalid = false
                            } else {
                                ratioInputInvalid = true
                                withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                                    invalidShakeOffset = -6
                                }
                                withAnimation(.interpolatingSpring(stiffness: 600, damping: 10).delay(0.05)) {
                                    invalidShakeOffset = 6
                                }
                                withAnimation(.interpolatingSpring(stiffness: 600, damping: 10).delay(0.1)) {
                                    invalidShakeOffset = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { ratioInputInvalid = false }
                                    customRatioText = ""
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Leaderboard view

    private var leaderboardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { showLeaderboard = false }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Leaderboard")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    statsStripView
                    bestSessionsSection
                    recentSessionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            barsVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                barsVisible = true
            }
        }
        .onDisappear {
            barsVisible = false
        }
    }

    private var statsStripView: some View {
        HStack(spacing: 0) {
            let totalSeconds = timerVM.sessions.reduce(0) { $0 + $1.duration }
            VStack(spacing: 2) {
                Text(formatTotalDuration(totalSeconds))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .monospacedDigit()
                Text("total focus")
                    .font(.system(size: 10, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 30)

            VStack(spacing: 2) {
                Text("\(timerVM.sessions.count)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text("sessions")
                    .font(.system(size: 10, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
        .opacity(barsVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: barsVisible)
    }

    private var bestSessionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BEST")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)

            let sessions = timerVM.topSessions
            let maxDuration = max(sessions.first?.duration ?? 1, 1)

            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    bestSessionRow(index: index, session: session, maxDuration: maxDuration)
                }
            }
        }
    }

    private func bestSessionRow(index: Int, session: FocusSession, maxDuration: Int) -> some View {
        let proportion = Double(session.duration) / Double(maxDuration)
        let delay = Double(index) * 0.06
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geo.size.width, height: 32)

                RoundedRectangle(cornerRadius: 7)
                    .fill(rankBarColor(index: index))
                    .frame(
                        width: barsVisible ? geo.size.width * proportion : 0,
                        height: 32
                    )
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.78).delay(delay + 0.1),
                        value: barsVisible
                    )

                HStack(spacing: 7) {
                    rankBadge(index: index)
                    Text(formatDuration(session.duration))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(index == 0 ? 1.0 : 0.82))
                        .monospacedDigit()
                    Spacer()
                    Text(formatDate(session.date))
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                }
                .padding(.horizontal, 9)
            }
        }
        .frame(height: 32)
        .offset(x: barsVisible ? 0 : -16)
        .opacity(barsVisible ? 1 : 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay), value: barsVisible)
    }

    private func rankBadge(index: Int) -> some View {
        Text("\(index + 1)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(index < 3 ? rankColor(index: index) : Color.white.opacity(0.28))
            .frame(width: 16, alignment: .trailing)
    }

    private func rankColor(index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.82, blue: 0.28)
        case 1: return Color(red: 0.78, green: 0.78, blue: 0.82)
        case 2: return Color(red: 0.82, green: 0.55, blue: 0.30)
        default: return .white
        }
    }

    private func rankBarColor(index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.82, blue: 0.28).opacity(0.28)
        case 1: return Color(red: 0.78, green: 0.78, blue: 0.82).opacity(0.20)
        case 2: return Color(red: 0.82, green: 0.55, blue: 0.30).opacity(0.24)
        default: return Color.white.opacity(0.09)
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)

            let sessions = timerVM.recentSessions

            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    recentSessionCard(index: index, session: session)
                }
            }
        }
    }

    private func recentSessionCard(index: Int, session: FocusSession) -> some View {
        let delay = Double(index) * 0.06 + 0.15
        return HStack(spacing: 10) {
            Text(formatDuration(session.duration))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .monospacedDigit()
            Spacer()
            Text(formatDate(session.date))
                .font(.system(size: 11, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.055)))
        .offset(x: barsVisible ? 0 : -16)
        .opacity(barsVisible ? 1 : 0)
        .animation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay), value: barsVisible)
    }

    private func formatTotalDuration(_ seconds: Int) -> String {
        if seconds < 3600 { return "\(seconds / 60)m" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            let s = seconds % 60
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return fmt.string(from: date)
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }

    // MARK: - Action button

    private var actionButton: some View {
        ZStack {
            Color.clear.frame(width: 74, height: 74)
            // Break: countdown arc around button
            if case let .onBreak(duration) = timerVM.state {
                let total = Double(duration)
                let remaining = Double(timerVM.breakSecondsRemaining)
                let actualProgress = total > 0 ? (total - remaining) / total : 0
                let displayProgress = skipAnimating ? animatedBreakProgress : actualProgress
                let arcAnimation: Animation? = skipAnimating ? .easeIn(duration: 0.45) : .linear(duration: 1)

                Circle()
                    .stroke(Color.white.opacity(0.08 * arcOpacity), lineWidth: 2)
                    .frame(width: 74, height: 74)
                Circle()
                    .trim(from: 0, to: displayProgress)
                    .stroke(Color.white.opacity(0.5 * arcOpacity), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 74, height: 74)
                    .rotationEffect(.degrees(-90))
                    .animation(arcAnimation, value: displayProgress)
            }

            // Focus→Break ripple burst
            Circle()
                .stroke(Color.white.opacity(rippleOpacity), lineWidth: 1.5)
                .frame(width: 60, height: 60)
                .scaleEffect(rippleScale)
                .allowsHitTesting(false)

            // Core button
            Button(action: buttonAction) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 60, height: 60)
                    Image(systemName: immediateIconName ?? buttonIconName)
                        .font(.system(size: buttonIconSize, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .animation(.easeInOut(duration: 0.25), value: stateKey)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func startBreak() {
        immediateIconName = "cup.and.saucer.fill"
        rippleScale = 1.0
        rippleOpacity = 0.45
        withAnimation(.easeOut(duration: 0.25)) {
            rippleScale = 74.0 / 60.0
            rippleOpacity = 0.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            immediateIconName = nil
            timerVM.stopFocusing()
            withAnimation(.easeOut(duration: 0.15)) {
                rippleOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                rippleScale = 1.0
            }
        }
    }

    private func skipBreak() {
        guard case let .onBreak(duration) = timerVM.state, !skipAnimating else { return }
        immediateIconName = "forward.fill"
        let total = Double(duration)
        let remaining = Double(timerVM.breakSecondsRemaining)
        animatedBreakProgress = total > 0 ? (total - remaining) / total : 0
        skipAnimating = true

        withAnimation(.easeIn(duration: 0.4)) {
            animatedBreakProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                arcOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            immediateIconName = nil
            skipAnimating = false
            arcOpacity = 1.0
            if case .onBreak = timerVM.state {
                timerVM.endBreak()
            }
        }
    }

    private var buttonIconName: String {
        switch timerVM.state {
        case .idle: return "play.fill"
        case .focusing: return "forward.fill"
        case .onBreak: return "cup.and.saucer.fill"
        }
    }

    private var buttonIconSize: CGFloat {
        switch timerVM.state {
        case .idle: return 22
        case .focusing, .onBreak: return 20
        }
    }

    private var buttonAction: () -> Void {
        switch timerVM.state {
        case .idle: return { timerVM.startFocusing() }
        case .focusing: return { startBreak() }
        case .onBreak: return { skipBreak() }
        }
    }

    // MARK: - Helpers

    private var modeLabel: String {
        switch timerVM.state {
        case .idle: return "Flowdoro"
        case .focusing: return "Focus"
        case .onBreak: return "Break"
        }
    }
}
