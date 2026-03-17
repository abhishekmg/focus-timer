import Foundation

@MainActor
final class TimerEngine: NSObject {
    private var timer: Timer?
    private var onTick: (() -> Void)?

    var isRunning: Bool { timer != nil }

    func start(onTick: @escaping () -> Void) {
        stop()
        self.onTick = onTick

        let t = Timer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onTick = nil
    }

    @objc private func fireTimer() {
        onTick?()
    }
}
