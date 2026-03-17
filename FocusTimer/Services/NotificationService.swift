import UserNotifications

@MainActor
final class NotificationService {
    func requestPermission() {
        Task.detached {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        Task.detached {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}
