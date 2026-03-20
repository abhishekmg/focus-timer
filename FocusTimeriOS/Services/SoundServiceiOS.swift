import AudioToolbox

@MainActor
final class SoundServiceiOS: SoundServiceProtocol {
    func playCompletionSound() {
        AudioServicesPlaySystemSound(1007) // Glass-like tone
    }
}
