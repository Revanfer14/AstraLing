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

    func postPingArrived(customerName: String, pingId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Ping Baru"
        content.body = "\(customerName) menunggu kamu. Ketuk untuk membalas."
        content.sound = .default
        content.userInfo = ["type": "ping_arrived", "pingId": pingId]
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func postTransactionArrived(amount: String, customerName: String, txnId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pembayaran Berhasil"
        content.body = "\(amount) dari \(customerName) sudah masuk ke saldo usahamu."
        content.sound = .default
        content.userInfo = ["type": "transaction_success", "txnId": txnId]
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
        let userInfo = response.notification.request.content.userInfo
        switch userInfo["type"] as? String {
        case "transaction_success":
            NotificationCenter.default.post(name: .transactionNotificationTapped, object: userInfo["txnId"] as? String)
        case "ping_arrived":
            NotificationCenter.default.post(name: .pingNotificationTapped, object: userInfo["pingId"] as? String)
        default:
            break
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let transactionNotificationTapped = Notification.Name("transactionNotificationTapped")
    static let pingNotificationTapped = Notification.Name("pingNotificationTapped")
}
