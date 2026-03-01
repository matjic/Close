//
//  ContactsManager.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import Foundation
import Contacts
import SwiftUI
import SwiftData

struct DeviceContact: Identifiable {
    let id: String
    let name: String
    let phoneNumber: String?
    let email: String?
    let birthday: DateComponents?
    let dates: [(label: String, date: DateComponents)]

    var displayName: String {
        return name.isEmpty ? "Unknown" : name
    }
}

@Observable
class ContactsManager {
    var authorizationStatus: CNAuthorizationStatus = .notDetermined
    var deviceContacts: [DeviceContact] = []
    var errorMessage: String?
    
    init() {
        self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestAccess() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            return granted
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request contacts access: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func fetchContacts() async {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            await MainActor.run {
                self.errorMessage = "Contacts access not authorized"
            }
            return
        }
        
        // Perform contact enumeration on a background thread
        let contacts = await Task.detached {
            let store = CNContactStore()
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey,
                CNContactBirthdayKey,
                CNContactDatesKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            
            var deviceContacts: [DeviceContact] = []
            
            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let phone = contact.phoneNumbers.first?.value.stringValue
                    let email = contact.emailAddresses.first?.value as String?
                    
                    let contactDates: [(label: String, date: DateComponents)] = contact.dates.compactMap { labeledValue in
                        let label = CNLabeledValue<NSDateComponents>.localizedString(forLabel: labeledValue.label ?? "Other").capitalized
                        return (label: label, date: labeledValue.value as DateComponents)
                    }

                    let deviceContact = DeviceContact(
                        id: contact.identifier,
                        name: fullName,
                        phoneNumber: phone,
                        email: email,
                        birthday: contact.birthday,
                        dates: contactDates
                    )
                    
                    deviceContacts.append(deviceContact)
                }
                
                return Result<[DeviceContact], Error>.success(deviceContacts.sorted { $0.name < $1.name })
            } catch {
                return Result<[DeviceContact], Error>.failure(error)
            }
        }.value
        
        await MainActor.run {
            switch contacts {
            case .success(let fetchedContacts):
                self.deviceContacts = fetchedContacts
            case .failure(let error):
                self.errorMessage = "Failed to fetch contacts: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchCNContact(identifier: String) -> CNContact? {
        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactBirthdayKey,
            CNContactDatesKey
        ] as [CNKeyDescriptor]

        return try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys)
    }

    func refreshImportedDates(for contacts: [Contact], modelContext: ModelContext) async {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }

        await Task.detached {
            for contact in contacts {
                guard let identifier = contact.contactIdentifier else { continue }

                let store = CNContactStore()
                let keys = [
                    CNContactBirthdayKey,
                    CNContactDatesKey
                ] as [CNKeyDescriptor]

                guard let cnContact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys) else { continue }

                let calendar = Calendar.current
                let existingImported = contact.customDates.filter { $0.sourceType == .contacts }

                // Build expected dates from CNContact
                var expectedDates: [(label: String, date: Date)] = []

                if let birthday = cnContact.birthday,
                   let date = calendar.date(from: birthday) {
                    expectedDates.append((label: "Birthday", date: date))
                }

                for labeledValue in cnContact.dates {
                    let label = CNLabeledValue<NSDateComponents>.localizedString(forLabel: labeledValue.label ?? "Other").capitalized
                    // Skip birthday - already added above via CNContactBirthdayKey
                    if label.lowercased() == "birthday" { continue }
                    let components = labeledValue.value as DateComponents
                    if let date = calendar.date(from: components) {
                        expectedDates.append((label: label, date: date))
                    }
                }

                // Remove imported dates that no longer exist
                for existing in existingImported {
                    let stillExists = expectedDates.contains { expected in
                        expected.label == existing.label && calendar.isDate(expected.date, equalTo: existing.date, toGranularity: .day)
                    }
                    if !stillExists {
                        await MainActor.run {
                            modelContext.delete(existing)
                        }
                    }
                }

                // Add or update dates
                for expected in expectedDates {
                    let existingMatch = existingImported.first { existing in
                        existing.label == expected.label
                    }
                    if let match = existingMatch {
                        if !calendar.isDate(match.date, equalTo: expected.date, toGranularity: .day) {
                            await MainActor.run {
                                match.date = expected.date
                            }
                        }
                    } else {
                        let newDate = CustomDate(
                            label: expected.label,
                            date: expected.date,
                            isRecurring: true,
                            source: .contacts,
                            contact: contact
                        )
                        await MainActor.run {
                            modelContext.insert(newDate)
                        }
                    }
                }
            }
        }.value
    }

    func importFromDeviceContacts(_ cnContacts: [CNContact], existingContacts: [Contact], modelContext: ModelContext) -> [Contact] {
        var importedContacts: [Contact] = []

        for cnContact in cnContacts {
            let identifier = cnContact.identifier
            let alreadyTracked = existingContacts.contains { $0.contactIdentifier == identifier }

            if !alreadyTracked {
                let fullName = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
                let phone = cnContact.phoneNumbers.first?.value.stringValue
                let email = cnContact.emailAddresses.first?.value as String?

                let contact = Contact(
                    name: fullName.isEmpty ? "Unknown" : fullName,
                    phoneNumber: phone,
                    email: email,
                    frequency: .weekly,
                    customDaysInterval: 7,
                    lastContactedDate: Date(),
                    contactIdentifier: identifier
                )

                modelContext.insert(contact)

                let calendar = Calendar.current
                if cnContact.isKeyAvailable(CNContactBirthdayKey),
                   let birthday = cnContact.birthday,
                   let date = calendar.date(from: birthday) {
                    let birthdayDate = CustomDate(
                        label: "Birthday",
                        date: date,
                        isRecurring: true,
                        source: .contacts,
                        contact: contact
                    )
                    modelContext.insert(birthdayDate)
                }

                if cnContact.isKeyAvailable(CNContactDatesKey) {
                    for labeledValue in cnContact.dates {
                        let label = CNLabeledValue<NSDateComponents>.localizedString(forLabel: labeledValue.label ?? "Other").capitalized
                        if label.lowercased() == "birthday" { continue }
                        let components = labeledValue.value as DateComponents
                        if let date = calendar.date(from: components) {
                            let customDate = CustomDate(
                                label: label,
                                date: date,
                                isRecurring: true,
                                source: .contacts,
                                contact: contact
                            )
                            modelContext.insert(customDate)
                        }
                    }
                }

                importedContacts.append(contact)
            }
        }

        return importedContacts
    }

    func openSettings() {
        PhoneActions.openSettings()
    }
}

