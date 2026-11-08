import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleOutcome(symbol: String, entry: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Your analysis was graded"
        content.body = "\(symbol) at \(Theme.price(entry)) — open SnipEdge to see the outcome."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 72 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
