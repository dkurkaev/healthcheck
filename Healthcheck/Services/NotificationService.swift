import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleHealthRating(at times: [(hour: Int, minute: Int)]) {
        // Очищаем всё старое, включая бейджи
        cancelAll()
        
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Время оценить здоровье 🏥"
            content.body = "Оцените состояние ваших зон тела"
            content.sound = .default
            // Мы НЕ устанавливаем content.badge, чтобы не вешать красные кружки на иконку
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "healthRating_\(index)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelAll() {
        // Удаляем запланированные уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // Удаляем уже доставленные уведомления из списка
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // Сбрасываем бейдж на иконке (красный круг с цифрой)
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error resetting badge: \(error)")
            }
        }
    }
}

