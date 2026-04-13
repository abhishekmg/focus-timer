import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: UserPreferences
    var onReset: () -> Void
    var onDurationChanged: (() -> Void)?
    var onShowToast: ((String) -> Void)?

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
                        set: {
                            preferences.workDuration = $0 * 60
                            onDurationChanged?()
                            onShowToast?("focus set to \(Int($0))m")
                        }
                    ), range: 1...120)
                    durationRow("break", minutes: Binding(
                        get: { preferences.breakDuration / 60 },
                        set: {
                            preferences.breakDuration = $0 * 60
                            onDurationChanged?()
                            onShowToast?("break set to \(Int($0))m")
                        }
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

                // Theme selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("theme")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textTertiary)
                        .kerning(2)

                    HStack(spacing: 8) {
                        ForEach(ThemeIdentifier.allCases, id: \.self) { theme in
                            Button {
                                preferences.selectedTheme = theme
                                onShowToast?("theme: \(theme.rawValue)")
                            } label: {
                                Text(theme.rawValue)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(preferences.selectedTheme == theme ? Color.textPrimary : Color.textTertiary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(preferences.selectedTheme == theme ? Color.surfaceGlass : .clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(preferences.selectedTheme == theme ? Color.borderSubtle : .clear, lineWidth: 0.5)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
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
                    toggleRow("sound", isOn: Binding(
                        get: { preferences.soundEnabled },
                        set: { preferences.soundEnabled = $0; onShowToast?("sound \($0 ? "on" : "off")") }
                    ))
                    toggleRow("notifications", isOn: Binding(
                        get: { preferences.notificationsEnabled },
                        set: { preferences.notificationsEnabled = $0; onShowToast?("notifications \($0 ? "on" : "off")") }
                    ))
                    toggleRow("auto-start breaks", isOn: Binding(
                        get: { preferences.autoStartBreaks },
                        set: { preferences.autoStartBreaks = $0; onShowToast?("auto-start breaks \($0 ? "on" : "off")") }
                    ))
                    toggleRow("auto-start work", isOn: Binding(
                        get: { preferences.autoStartWork },
                        set: { preferences.autoStartWork = $0; onShowToast?("auto-start work \($0 ? "on" : "off")") }
                    ))
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
                VStack(spacing: 10) {
                    Button {
                        onReset()
                        onShowToast?("timer reset")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .medium))
                            Text("reset timer")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(Color.ember)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.emberMuted)
                        )
                    }
                    .buttonStyle(.plain)

                    #if os(macOS)
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    #endif
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
        HStack {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color.ember)
        }
    }
}
