//
//  ContactScheduler.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import Foundation
import SwiftData

@MainActor
class ContactScheduler {
    private let notificationManager: NotificationManager
    
    init(notificationManager: NotificationManager? = nil) {
        self.notificationManager = notificationManager ?? NotificationManager.shared
    }
    
    func updateSchedule(for contact: Contact) async {
        await notificationManager.scheduleNotification(for: contact)
    }
    
    func updateSchedules(for contacts: [Contact]) async {
        for contact in contacts {
            await notificationManager.scheduleNotification(for: contact)
        }
    }
    
    func updateCustomDateSchedules(for contact: Contact) async {
        for customDate in contact.customDates {
            await notificationManager.scheduleCustomDateNotification(for: customDate, contact: contact)
        }
    }

    func cancelSchedule(for contact: Contact) {
        notificationManager.cancelNotification(for: contact)
        for customDate in contact.customDates {
            notificationManager.cancelCustomDateNotification(for: customDate, contact: contact)
        }
    }
    
    func refreshAllSchedules(contacts: [Contact]) async {
        // Cancel all existing notifications
        notificationManager.cancelAllNotifications()
        
        // Reschedule all contacts
        await updateSchedules(for: contacts)
    }
    
    func markContactedAndReschedule(contact: Contact, on date: Date = Date()) async {
        contact.markAsContacted(on: date)
        await updateSchedule(for: contact)
    }
}

