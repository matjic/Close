//
//  ContactSchedulerTests.swift
//  closeTests
//
//  Created by Mathew Jacob on 2/28/26.
//

import Testing
import Foundation
import SwiftData
@testable import close

// MARK: - Mock NotificationManager

@MainActor
class MockNotificationManager: NotificationManager {
    var scheduledContacts: [UUID] = []
    var cancelledContacts: [UUID] = []
    var scheduledCustomDates: [(customDateId: UUID, contactId: UUID)] = []
    var cancelledCustomDates: [(customDateId: UUID, contactId: UUID)] = []
    var allCancelled = false

    override func scheduleNotification(for contact: Contact) async {
        scheduledContacts.append(contact.id)
    }

    override func cancelNotification(for contact: Contact) {
        cancelledContacts.append(contact.id)
    }

    override func scheduleCustomDateNotification(for customDate: CustomDate, contact: Contact) async {
        scheduledCustomDates.append((customDateId: customDate.id, contactId: contact.id))
    }

    override func cancelCustomDateNotification(for customDate: CustomDate, contact: Contact) {
        cancelledCustomDates.append((customDateId: customDate.id, contactId: contact.id))
    }

    override func cancelAllNotifications() {
        allCancelled = true
    }
}

// MARK: - ContactScheduler Tests

struct ContactSchedulerTests {

    @Test @MainActor func markContactedAndRescheduleUpdatesLastContactedDate() async throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, name: "Test", lastContactedDate: nil)
        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        let now = Date()
        await scheduler.markContactedAndReschedule(contact: contact, on: now)

        #expect(contact.lastContactedDate == now)
        #expect(mock.scheduledContacts.contains(contact.id))
    }

    @Test @MainActor func initWithDefaultNotificationManager() {
        let scheduler = ContactScheduler()
        _ = scheduler
    }

    @Test @MainActor func updateScheduleSchedulesNotification() async throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, name: "Alice", lastContactedDate: Date())
        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        await scheduler.updateSchedule(for: contact)

        #expect(mock.scheduledContacts == [contact.id])
    }

    @Test @MainActor func updateSchedulesIteratesAllContacts() async throws {
        let container = try makeTestContainer()
        let contact1 = makeContact(in: container, name: "Alice", lastContactedDate: Date())
        let contact2 = makeContact(in: container, name: "Bob", lastContactedDate: Date())
        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        await scheduler.updateSchedules(for: [contact1, contact2])

        #expect(mock.scheduledContacts.count == 2)
        #expect(mock.scheduledContacts.contains(contact1.id))
        #expect(mock.scheduledContacts.contains(contact2.id))
    }

    @Test @MainActor func cancelScheduleCancelsContactAndCustomDates() async throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, name: "Alice", lastContactedDate: Date())
        let customDate1 = CustomDate(label: "Birthday", date: Date(), isRecurring: true, source: .contacts, contact: contact)
        let customDate2 = CustomDate(label: "Anniversary", date: Date(), isRecurring: true, source: .manual, contact: contact)
        container.mainContext.insert(customDate1)
        container.mainContext.insert(customDate2)

        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        scheduler.cancelSchedule(for: contact)

        #expect(mock.cancelledContacts == [contact.id])
        #expect(mock.cancelledCustomDates.count == 2)
    }

    @Test @MainActor func refreshAllSchedulesCancelsAndReschedules() async throws {
        let container = try makeTestContainer()
        let contact1 = makeContact(in: container, name: "Alice", lastContactedDate: Date())
        let contact2 = makeContact(in: container, name: "Bob", lastContactedDate: Date())
        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        await scheduler.refreshAllSchedules(contacts: [contact1, contact2])

        #expect(mock.allCancelled == true)
        #expect(mock.scheduledContacts.count == 2)
    }

    @Test @MainActor func updateCustomDateSchedulesSchedulesEachDate() async throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, name: "Alice", lastContactedDate: Date())
        let cd1 = CustomDate(label: "Birthday", date: Date(), isRecurring: true, source: .contacts, contact: contact)
        let cd2 = CustomDate(label: "Graduation", date: Date(), isRecurring: false, source: .manual, contact: contact)
        container.mainContext.insert(cd1)
        container.mainContext.insert(cd2)

        let mock = MockNotificationManager()
        let scheduler = ContactScheduler(notificationManager: mock)

        await scheduler.updateCustomDateSchedules(for: contact)

        #expect(mock.scheduledCustomDates.count == 2)
    }
}

// MARK: - Model Edge Case Tests

struct ContactEdgeCaseTests {

    @Test @MainActor func contactWithNilLastContactedDateDefaultsToNow() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: nil)

        // nextReminderDate should be ~7 days from now
        let expected = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let diff = abs(contact.nextReminderDate.timeIntervalSince(expected))
        #expect(diff < 2)
    }

    @Test @MainActor func yearBoundaryDecemberToJanuary() throws {
        let container = try makeTestContainer()
        let calendar = Calendar.current
        // Dec 28 with weekly frequency should wrap to Jan 4
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 28
        let dec28 = calendar.date(from: components)!

        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: dec28)
        let nextDate = contact.nextReminderDate

        let expectedComponents = calendar.dateComponents([.month, .day], from: nextDate)
        #expect(expectedComponents.month == 1)
        #expect(expectedComponents.day == 4)
    }

    @Test @MainActor func statusTextOverduePlural() throws {
        let container = try makeTestContainer()
        let longAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: longAgo)

        #expect(contact.statusText.contains("overdue"))
        #expect(contact.status == .overdue)
    }

    @Test @MainActor func statusTextOnTrack() throws {
        let container = try makeTestContainer()
        let contact = makeContact(in: container, frequency: .yearly, lastContactedDate: Date())

        #expect(contact.statusText.contains("day"))
        #expect(contact.status == .onTrack)
    }

    @Test @MainActor func dueSoonThresholdIsRespected() throws {
        let container = try makeTestContainer()
        let calendar = Calendar.current
        // Set last contacted so next reminder is exactly dueSoonThresholdDays away
        let daysAgo = 7 - Contact.dueSoonThresholdDays
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
        let contact = makeContact(in: container, frequency: .weekly, lastContactedDate: date)

        #expect(contact.isDueSoon == true)
        #expect(contact.daysUntilNextContact == Contact.dueSoonThresholdDays)
    }
}

struct CustomDateEdgeCaseTests {

    @Test @MainActor func sourceTypeDefaultsToManual() throws {
        let container = try makeTestContainer()
        let customDate = CustomDate(label: "Test", date: Date())
        container.mainContext.insert(customDate)

        #expect(customDate.sourceType == .manual)
        #expect(customDate.source == "manual")
    }

    @Test @MainActor func sourceTypeContactsRoundTrips() throws {
        let container = try makeTestContainer()
        let customDate = CustomDate(label: "Birthday", date: Date(), source: .contacts)
        container.mainContext.insert(customDate)

        #expect(customDate.sourceType == .contacts)
        #expect(customDate.source == "contacts")
    }

    @Test @MainActor func sourceTypeSetterUpdatesRawValue() throws {
        let container = try makeTestContainer()
        let customDate = CustomDate(label: "Test", date: Date(), source: .manual)
        container.mainContext.insert(customDate)

        customDate.sourceType = .contacts
        #expect(customDate.source == "contacts")
    }
}
