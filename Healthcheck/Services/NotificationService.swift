import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
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
    
    func scheduleHealthRating(timesPerDay: Int) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let hours: [Int]
        switch timesPerDay {
        case 1:
            hours = [20] // Evening
        case 2:
            hours = [12, 20] // Noon and Evening
        case 3:
            hours = [9, 15, 21] // Morning, Afternoon, Evening
        default:
            hours = [20]
        }
        
        for hour in hours {
            let content = UNMutableNotificationContent()
            content.title = "Время оценить здоровье 🏥"
            content.body = "Оцените состояние ваших зон тела"
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "healthRating_\(hour)",
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
