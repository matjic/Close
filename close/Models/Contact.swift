//
//  Contact.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import Foundation
import SwiftUI
import SwiftData

// Ensure ContactFrequency is defined in the same file or imported properly
// Since we're in the same module, this should work

@Model
final class Contact {
    var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var frequencyType: String // ContactFrequency raw value
    var customDaysInterval: Int
    var lastContactedDate: Date?
    var notes: String
    var contactIdentifier: String? // iOS Contacts framework identifier

    @Relationship(deleteRule: .cascade, inverse: \CustomDate.contact)
    var customDates: [CustomDate] = []

    // Computed properties
    var frequency: ContactFrequency {
        get {
            ContactFrequency(rawValue: frequencyType) ?? .weekly
        }
        set {
            frequencyType = newValue.rawValue
        }
    }
    
    var nextReminderDate: Date {
        let lastDate = lastContactedDate ?? Date() // Default to now if somehow nil
        
        let interval = frequency == .custom ? customDaysInterval : (frequency.days ?? 7)
        return Calendar.current.date(byAdding: .day, value: interval, to: lastDate) ?? Date()
    }
    
    var daysUntilNextContact: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextDate = calendar.startOfDay(for: nextReminderDate)
        
        let components = calendar.dateComponents([.day], from: today, to: nextDate)
        return components.day ?? 0
    }
    
    var isOverdue: Bool {
        return daysUntilNextContact < 0
    }
    
    static let dueSoonThresholdDays = 3

    var isDueSoon: Bool {
        return daysUntilNextContact >= 0 && daysUntilNextContact <= Self.dueSoonThresholdDays
    }
    
    enum Status {
        case overdue, dueSoon, onTrack

        var color: Color {
            switch self {
            case .overdue: Color("StatusRed")
            case .dueSoon: Color("StatusOrange")
            case .onTrack: Color("StatusGreen")
            }
        }
    }

    var status: Status {
        if isOverdue { return .overdue }
        else if isDueSoon { return .dueSoon }
        else { return .onTrack }
    }

    var statusText: String {
        let days = abs(daysUntilNextContact)
        switch status {
        case .overdue:
            return days == 0 ? "Due today" : "\(days) day\(days == 1 ? "" : "s") overdue"
        case .dueSoon:
            return days == 0 ? "Due today" : "Due in \(days) day\(days == 1 ? "" : "s")"
        case .onTrack:
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        frequency: ContactFrequency = .weekly,
        customDaysInterval: Int = 7,
        lastContactedDate: Date? = nil,
        notes: String = "",
        contactIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.frequencyType = frequency.rawValue
        self.customDaysInterval = customDaysInterval
        self.lastContactedDate = lastContactedDate
        self.notes = notes
        self.contactIdentifier = contactIdentifier
    }
    
    func markAsContacted(on date: Date = Date()) {
        self.lastContactedDate = date
    }
}

