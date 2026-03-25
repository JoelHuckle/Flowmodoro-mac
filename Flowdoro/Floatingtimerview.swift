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

    private var backgroundColor: Color {
        if case .onBreak = timerVM.state {
            return Color(red: 0.14, green: 0.10, blue: 0.22)
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

            VStack(spacing: 0) {
                topBar
                Spacer()
                mainContent
                Spacer()
                actionButton
                    .padding(.bottom, 28)
            }
        }
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
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(height: 44)
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 10) {
            Text(modeLabel)
                .font(.system(size: 15, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(timerVM.formattedTime)
                .font(.system(size: 70, weight: .semibold, design: .default))
                .foregroundStyle(.white)
                .monospacedDigit()
                .animation(nil, value: timerVM.formattedTime)
        }
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
                    .stroke(Color.white.opacity(0.08), lineWidth: 2)
                    .frame(width: 74, height: 74)
                Circle()
                    .trim(from: 0, to: displayProgress)
                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
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
        withAnimation(.easeIn(duration: 0.45)) {
            animatedBreakProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            immediateIconName = nil
            skipAnimating = false
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
