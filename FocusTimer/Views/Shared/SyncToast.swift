import SwiftUI

struct SyncToast: View {
    let isVisible: Bool

    var body: some View {
        Text("synced timer")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .offset(y: isVisible ? 0 : -8)
            .animation(.easeInOut(duration: 0.4), value: isVisible)
    }
}
