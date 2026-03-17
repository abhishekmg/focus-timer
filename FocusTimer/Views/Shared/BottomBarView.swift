import SwiftUI

struct BottomBarView: View {
    let completedSessions: Int
    let targetSessions: Int
    let onSessionsTapped: () -> Void
    let onSettingsTapped: () -> Void
    let onDetachTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSessionsTapped) {
                Image(systemName: "list.dash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            // Session pips — filled dots for completed, hollow for remaining
            HStack(spacing: 5) {
                ForEach(0..<min(targetSessions, 8), id: \.self) { i in
                    Circle()
                        .fill(i < completedSessions ? Color.ember : Color.white.opacity(0.08))
                        .frame(width: 5, height: 5)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Button(action: onDetachTapped) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Button(action: onSettingsTapped) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
