import Foundation

/// Calls the Vercel serverless function to push Live Activity updates via APNs.
/// Used by macOS to update the iOS Dynamic Island when the app is backgrounded.
@MainActor
final class PushService {
    private let endpointURL: String
    private let authSecret: String

    private let syncService: SyncService

    init(syncService: SyncService) {
        self.syncService = syncService

        // Load secrets from Secrets.plist (gitignored — not committed to repo)
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            self.endpointURL = dict["PUSH_ENDPOINT_URL"] ?? ""
            self.authSecret = dict["PUSH_AUTH_SECRET"] ?? ""
        } else {
            self.endpointURL = ""
            self.authSecret = ""
            print("[PushService] Warning: Secrets.plist not found. Push notifications disabled.")
        }
    }

    /// Push a state update to the Dynamic Island
    func pushUpdate(phase: TimerPhase, timerState: String, endTime: Date, progress: Double, remainingSeconds: TimeInterval) {
        guard !endpointURL.isEmpty, let token = syncService.readPushToken() else { return }

        let contentState: [String: Any] = [
            "phase": phase.rawValue,
            "timerState": timerState,
            "endTime": endTime.timeIntervalSinceReferenceDate,
            "progress": progress,
            "remainingSeconds": remainingSeconds
        ]

        send(pushToken: token, contentState: contentState, event: "update")
    }

    /// Push an end event to dismiss the Dynamic Island
    func pushEnd() {
        guard !endpointURL.isEmpty, let token = syncService.readPushToken() else { return }

        let contentState: [String: Any] = [
            "phase": "work",
            "timerState": "idle",
            "endTime": Date.now.timeIntervalSinceReferenceDate,
            "progress": 1.0,
            "remainingSeconds": 0
        ]

        send(pushToken: token, contentState: contentState, event: "end")
    }

    // MARK: - Private

    private func send(pushToken: String, contentState: [String: Any], event: String) {
        guard let url = URL(string: endpointURL) else { return }

        let body: [String: Any] = [
            "pushToken": pushToken,
            "contentState": contentState,
            "event": event
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("[PushService] sending \(event): timerState=\(contentState["timerState"] ?? "?"), remaining=\(contentState["remainingSeconds"] ?? "?"), token=\(pushToken.prefix(8))...")
        Task.detached {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let responseBody = String(data: data, encoding: .utf8) ?? ""
                print("[PushService] \(event) → status: \(statusCode), body: \(responseBody)")
            } catch {
                print("[PushService] error: \(error)")
            }
        }
    }
}
