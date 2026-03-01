//
//  NotificationManager.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import Foundation
import UserNotifications
import SwiftUI

@Observable
class NotificationManager {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    static let shared = NotificationManager()
    
    // Notification action identifiers
    static let categoryIdentifier = "CONTACT_REMINDER"
    static let callActionIdentifier = "CALL_ACTION"
    static let messageActionIdentifier = "MESSAGE_ACTION"
    static let doneActionIdentifier = "DONE_ACTION"
    static let defaultNotificationHour = 9
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
        }
    }
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            
            if granted {
                await setupNotificationCategories()
            }
            
            return granted
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func setupNotificationCategories() async {
        let callAction = UNNotificationAction(
            identifier: NotificationManager.callActionIdentifier,
            title: "Call",
            options: .foreground
        )
        
        let messageAction = UNNotificationAction(
            identifier: NotificationManager.messageActionIdentifier,
            title: "Message",
            options: .foreground
        )
        
        let doneAction = UNNotificationAction(
            identifier: NotificationManager.doneActionIdentifier,
            title: "Mark Done",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: NotificationManager.categoryIdentifier,
            actions: [callAction, messageAction, doneAction],
            intentIdentifiers: [],
            options: []
        )
        
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
    }
    
    func scheduleNotification(for contact: Contact) async {
        guard authorizationStatus == .authorized else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing notification for this contact
        center.removePendingNotificationRequests(withIdentifiers: [contact.id.uuidString])
        
        // Only schedule if next reminder is in the future
        let nextDate = contact.nextReminderDate
        guard nextDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to reach out!"
        content.body = "Stay in touch with \(contact.name)"
        content.sound = .default
        content.categoryIdentifier = NotificationManager.categoryIdentifier
        
        // Store contact ID in userInfo for handling actions
        content.userInfo = ["contactId": contact.id.uuidString]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: contact.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
            }
        }
    }
    
    func scheduleCustomDateNotification(for customDate: CustomDate, contact: Contact) async {
        guard authorizationStatus == .authorized else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = "\(contact.id.uuidString)-\(customDate.id.uuidString)"

        // Remove existing notification for this custom date
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "It's \(contact.name)'s \(customDate.label) today!"
        content.body = "Don't forget to reach out to \(contact.name)"
        content.sound = .default
        content.userInfo = ["contactId": contact.id.uuidString]

        let calendar = Calendar.current
        var dateComponents: DateComponents

        if customDate.isRecurring {
            // For recurring dates, schedule on month/day only (repeats annually)
            dateComponents = calendar.dateComponents([.month, .day], from: customDate.date)
        } else {
            // For one-off dates, use full date
            dateComponents = calendar.dateComponents([.year, .month, .day], from: customDate.date)
            // Don't schedule if date is in the past
            guard customDate.date > Date() else { return }
        }

        dateComponents.hour = Self.defaultNotificationHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: customDate.isRecurring)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to schedule custom date notification: \(error.localizedDescription)"
            }
        }
    }

    func cancelCustomDateNotification(for customDate: CustomDate, contact: Contact) {
        let center = UNUserNotificationCenter.current()
        let identifier = "\(contact.id.uuidString)-\(customDate.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelNotification(for contact: Contact) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [contact.id.uuidString])
    }
    
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
}

