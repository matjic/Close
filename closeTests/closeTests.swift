//
//  closeTests.swift
//  closeTests
//
//  Created by Mathew Jacob on 10/12/25.
//

import Testing
import Foundation
import SwiftData
@testable import close

// MARK: - Test Helpers

/// Creates an in-memory ModelContainer for SwiftData @Model classes.
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Contact.self, CustomDate.self, configurations: config)
}

/// Inserts a Contact into the given container's context and returns it.
@MainActor
func makeContact(
    in container: ModelContainer,
    name: String = "Test User",
    frequency: ContactFrequency = .weekly,
    customDaysInterval: Int = 7,
    lastContactedDate: Date? = nil,
    notes: String = ""
) -> Contact {
    let contact = Contact(
        name: name,
        frequency: frequency,
        customDaysInterval: customDaysInterval,
        lastContactedDate: lastContactedDate,
        notes: notes
    )
    container.mainContext.insert(contact)
    return contact
}

// MARK: - ContactFrequency Tests

struct ContactFrequencyTests {

    @Test func dailyDaysReturns1() {
        #expect(ContactFrequency.daily.days == 1)
    }

    @Test func weeklyDaysReturns7() {
        #expect(ContactFrequency.weekly.days == 7)
    }

    @Test func biweeklyDaysReturns14() {
        #expect(ContactFrequency.biweekly.days == 14)
    }

    @Test func monthlyDaysReturns30() {
        #expect(ContactFrequency.monthly.days == 30)
    }

    @Test func quarterlyDaysReturns90() {
        #expect(ContactFrequency.quarterly.days == 90)
    }

    @Test func yearlyDaysReturns365() {
        #expect(ContactFrequency.yearly.days == 365)
    }

    @Test func customDaysReturnsNil() {
        #expect(ContactFrequency.custom.days == nil)
    }

    @Test func displayNameMatchesRawValue() {
        for freq in ContactFrequency.allCases {
            #expect(freq.displayName == freq.rawValue)
        }
    }

    @Test func allCasesContainsSevenCases() {
        #expect(ContactFrequency.allCases.count == 7)
    }
}

// MARK: - Contact Tests

struct ContactTests {

    @Test @MainActor func initSetsAllProperties() throws {
        let container = try makeTestContainer()
        let date = Date()
        let id = UUID()
        let contact = Contact(
            id: id,
            name: "Alice",
            phoneNumber: "555-1234",
            email: "alice@example.com",
            frequency: .monthly,
            customDaysInterval: 45,
            lastContactedDate: date,
            notes: "Friend",
            contactIdentifier: "ABC123"
        )
        container.mainContext.insert(contact)

        #expect(contact.id == id)
        #expect(contact.name == "Alice")
        #expect(contact.phoneNumber == "555-1234")
        #expect(contact.email == "alice@example.com")
        #expect(contact.frequencyType == "Monthly")
        #expect(contact.customDaysInterval == 45)
        #expect(contact.lastContactedDate == date)
        #expect(contact.notes == "Friend")
        #expect(contact.contactIdentifier == "ABC123")
    }

    @Test @MainActor func initDefaults() throws {
        let container = try makeTestContainer()
        let contact = Contact(name: "Bob")
        container.mainContext.insert(contact)

        #expect(contact.phoneNumber == nil)
        #expect(contact.email == nil)
        #expect(contact.frequencyType == "Weekly")
        #expect(contact.customDaysInterval == 7)
        #expect(contact.lastContactedDate == nil)
        #expect(contact.notes == "")
        #expect(contact.contactIdentifier == nil)
    }

    @Test @MainActor func frequencyGetterMapsCorrectly() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .quarterly)
        #expect(contact.frequency == .quarterly)
    }

    @Test @MainActor func frequencyGetterFallsBackToWeekly() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container)
        contact.frequencyType = "InvalidValue"
        #expect(contact.frequency == .weekly)
    }

    @Test @MainActor func frequencySetterUpdatesRawValue() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .daily)
        contact.frequency = .yearly
        #expect(contact.frequencyType == "Yearly")
    }

    @Test @MainActor func nextReminderDateWithKnownLastContact() throws {
        let container = try makeTestContainer()
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: fiveDaysAgo)

        let expected = Calendar.current.date(byAdding: .day, value: 7, to: fiveDaysAgo)!
        let diff = abs(contact.nextReminderDate.timeIntervalSince(expected))
        #expect(diff < 1) // within 1 second
    }

    @Test @MainActor func nextReminderDateCustomFrequency() throws {
        let container = try makeTestContainer()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let contact = makeContact(
            in: container,
            frequency: .custom,
            customDaysInterval: 10,
            lastContactedDate: threeDaysAgo
        )

        let expected = Calendar.current.date(byAdding: .day, value: 10, to: threeDaysAgo)!
        let diff = abs(contact.nextReminderDate.timeIntervalSince(expected))
        #expect(diff < 1)
    }

    @Test @MainActor func nextReminderDateNilLastContactDefaultsToNow() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .daily, lastContactedDate: nil)

        // Should be ~1 day from now
        let expected = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let diff = abs(contact.nextReminderDate.timeIntervalSince(expected))
        #expect(diff < 2) // within 2 seconds tolerance
    }

    @Test @MainActor func daysUntilNextContactPositive() throws {
        let container = try makeTestContainer()
        let today = Date()
        let contact = makeContact(in: container, frequency: .monthly, lastContactedDate: today)
        #expect(contact.daysUntilNextContact > 0)
    }

    @Test @MainActor func daysUntilNextContactZeroWhenDueToday() throws {
        let container = try makeTestContainer()
        let calendar = Calendar.current
        // Set lastContactedDate exactly `days` ago so nextReminder is start of today
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: sevenDaysAgo)
        #expect(contact.daysUntilNextContact == 0)
    }

    @Test @MainActor func daysUntilNextContactNegativeWhenOverdue() throws {
        let container = try makeTestContainer()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: thirtyDaysAgo)
        #expect(contact.daysUntilNextContact < 0)
    }

    @Test @MainActor func isOverdueTrue() throws {
        let container = try makeTestContainer()
        let longAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: longAgo)
        #expect(contact.isOverdue == true)
    }

    @Test @MainActor func isOverdueFalse() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: Date())
        #expect(contact.isOverdue == false)
    }

    @Test @MainActor func isDueSoonTrueWithinThreeDays() throws {
        let container = try makeTestContainer()
        let calendar = Calendar.current
        // Set last contacted so next reminder is 2 days from now
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: calendar.startOfDay(for: Date()))!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: fiveDaysAgo)
        #expect(contact.isDueSoon == true)
    }

    @Test @MainActor func isDueSoonFalseWhenFarOut() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .yearly, lastContactedDate: Date())
        #expect(contact.isDueSoon == false)
    }

    @Test @MainActor func isDueSoonFalseWhenOverdue() throws {
        let container = try makeTestContainer()
        let longAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: longAgo)
        #expect(contact.isDueSoon == false)
    }

    @Test @MainActor func statusOverdue() throws {
        let container = try makeTestContainer()
        let longAgo = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: longAgo)
        #expect(contact.status == .overdue)
    }

    @Test @MainActor func statusDueSoon() throws {
        let container = try makeTestContainer()
        let calendar = Calendar.current
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: calendar.startOfDay(for: Date()))!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: fiveDaysAgo)
        #expect(contact.status == .dueSoon)
    }

    @Test @MainActor func statusOnTrack() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .yearly, lastContactedDate: Date())
        #expect(contact.status == .onTrack)
    }

    @Test @MainActor func markAsContactedUpdatesDate() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, lastContactedDate: nil)
        let now = Date()
        contact.markAsContacted(on: now)
        #expect(contact.lastContactedDate == now)
    }
}

// MARK: - CustomDate Tests

struct CustomDateTests {

    @Test @MainActor func initSetsAllProperties() throws {
        let container = try makeTestContainer()
        let date = Date()
        let id = UUID()
        let customDate = CustomDate(id: id, label: "Birthday", date: date)
        container.mainContext.insert(customDate)

        #expect(customDate.id == id)
        #expect(customDate.label == "Birthday")
        #expect(customDate.date == date)
        #expect(customDate.isRecurring == true)
        #expect(customDate.sourceType == .manual)
        #expect(customDate.contact == nil)
    }

    @Test @MainActor func initCustomValuesOverrideDefaults() throws {
        let container = try makeTestContainer()
        let date = Date()
        let contact = makeContact(in: container, name: "Owner")
        let customDate = CustomDate(
            label: "Anniversary",
            date: date,
            isRecurring: false,
            source: .contacts,
            contact: contact
        )
        container.mainContext.insert(customDate)

        #expect(customDate.isRecurring == false)
        #expect(customDate.sourceType == .contacts)
        #expect(customDate.contact === contact)
    }
}
