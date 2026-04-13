import WidgetKit
import SwiftUI
import ActivityKit

@main
struct FocusTimerLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        FocusTimerLiveActivityWidget()
    }
}

struct FocusTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            // Lock Screen Live Activity
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.phase.lowercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    } icon: {
                        Circle()
                            .fill(phaseColor(context.state.phase))
                            .frame(width: 8, height: 8)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context: context)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                DynamicIslandExpandedRegion(.center) {
                    if !context.attributes.taskName.isEmpty {
                        Text(context.attributes.taskName)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(phaseColor(context.state.phase))
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                // Compact leading — phase-colored dot
                Circle()
                    .fill(phaseColor(context.state.phase))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Compact trailing — countdown
                timerText(context: context)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(minWidth: 40)
                    .padding(.trailing, 4)
            } minimal: {
                // Minimal — colored dot
                Circle()
                    .fill(phaseColor(context.state.phase))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<FocusTimerAttributes>) -> some View {
        HStack(spacing: 16) {
            // Phase indicator
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.phase.lowercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(phaseColor(context.state.phase))
                    .kerning(2)

                if !context.attributes.taskName.isEmpty {
                    Text(context.attributes.taskName)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Timer countdown
            timerText(context: context)
                .font(.system(size: 28, weight: .thin, design: .monospaced))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(16)
        .background(Color.black)
    }

    @ViewBuilder
    private func timerText(context: ActivityViewContext<FocusTimerAttributes>) -> some View {
        if context.state.timerState == "paused" {
            let mins = Int(context.state.remainingSeconds) / 60
            let secs = Int(context.state.remainingSeconds) % 60
            Text(String(format: "%02d:%02d", mins, secs))
                .opacity(0.5)
        } else {
            Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
        }
    }

    private func phaseColor(_ phase: String) -> Color {
        phase == "work"
            ? Color(red: 0.96, green: 0.50, blue: 0.30)
            : Color(red: 0.42, green: 0.77, blue: 0.72)
    }
}
