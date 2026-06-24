//
//  NotificationService.swift
//  AstraLing
//
//  Created by Rasya Devan on 25/06/26.
//

import UserNotifications

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func postTransactionArrived(amount: String, customerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pembayaran Berhasil"
        content.body = "\(amount) dari \(customerName) sudah masuk ke saldo usahamu."
        content.sound = .default
        content.userInfo = ["type": "transaction_success"]
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.userInfo["type"] as? String == "transaction_success" {
            NotificationCenter.default.post(name: .transactionNotificationTapped, object: nil)
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let transactionNotificationTapped = Notification.Name("transactionNotificationTapped")
}
