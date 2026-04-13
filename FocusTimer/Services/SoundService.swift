import Foundation

@MainActor
protocol SoundServiceProtocol {
    func playCompletionSound()
}

#if os(macOS)
import AppKit

@MainActor
final class SoundService: SoundServiceProtocol {
    func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }
}
#endif
