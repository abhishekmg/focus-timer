import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: UserPreferences
    var onReset: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("settings")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .kerning(3)

                // Duration controls
                VStack(spacing: 16) {
                    durationRow("focus", minutes: Binding(
                        get: { preferences.workDuration / 60 },
                        set: { preferences.workDuration = $0 * 60 }
                    ), range: 1...120)
                    durationRow("break", minutes: Binding(
                        get: { preferences.breakDuration / 60 },
                        set: { preferences.breakDuration = $0 * 60 }
                    ), range: 1...30)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.surfaceGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderSubtle, lineWidth: 0.5)
                        )
                )

                // Toggle controls
                VStack(spacing: 14) {
                    toggleRow("sound", isOn: $preferences.soundEnabled)
                    toggleRow("notifications", isOn: $preferences.notificationsEnabled)
                    toggleRow("auto-start breaks", isOn: $preferences.autoStartBreaks)
                    toggleRow("auto-start work", isOn: $preferences.autoStartWork)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.surfaceGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderSubtle, lineWidth: 0.5)
                        )
                )

                // Actions
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: onReset) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .medium))
                            Text("reset timer")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(Color.ember)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.emberMuted)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                                .font(.system(size: 10, weight: .medium))
                            Text("quit")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
        }
    }

    private func durationRow(
        _ title: String,
        minutes: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(Int(minutes.wrappedValue))m")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            Slider(value: minutes, in: range, step: 1)
                .tint(.white.opacity(0.3))
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
        }
        .toggleStyle(.switch)
        .tint(Color.ember)
    }
}
