import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: UserPreferences
    var onReset: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("settings")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .kerning(2)

                VStack(spacing: 16) {
                    durationRow("focus", value: preferences.workDuration / 60, range: 1...120) {
                        preferences.workDuration = $0 * 60
                    }
                    durationRow("break", value: preferences.breakDuration / 60, range: 1...30) {
                        preferences.breakDuration = $0 * 60
                    }
                    durationRow("long break", value: preferences.longBreakDuration / 60, range: 1...60) {
                        preferences.longBreakDuration = $0 * 60
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 0.5)

                VStack(spacing: 12) {
                    toggleRow("sound", isOn: $preferences.soundEnabled)
                    toggleRow("notifications", isOn: $preferences.notificationsEnabled)
                    toggleRow("auto-start breaks", isOn: $preferences.autoStartBreaks)
                    toggleRow("auto-start work", isOn: $preferences.autoStartWork)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 0.5)

                VStack(alignment: .leading, spacing: 10) {
                    Button(action: onReset) {
                        Text("reset timer")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.ember)
                    }
                    .buttonStyle(.plain)

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("quit")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }

    private func durationRow(
        _ title: String,
        value: Double,
        range: ClosedRange<Double>,
        onChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(Int(value))m")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
            }
            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: range, step: 1)
            .tint(Color.ember)
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
