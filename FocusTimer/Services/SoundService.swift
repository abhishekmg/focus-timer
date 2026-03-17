import AppKit

@MainActor
final class SoundService {
    func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }
}
