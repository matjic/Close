//
//  ContactsListView.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI
import SwiftData
import ContactsUI
import Contacts

struct ContactsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.name) private var contacts: [Contact]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var showingContactPicker = false
    @State private var showingOnboarding = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var contactsManager = ContactsManager()
    
    @Environment(NotificationManager.self) private var notificationManager
    private let scheduler = ContactScheduler()
    
    var sortedContacts: [Contact] {
        contacts.sorted { $0.nextReminderDate < $1.nextReminderDate }
    }
    
    var filteredContacts: [Contact] {
        let contactsToFilter = sortedContacts
        if searchText.isEmpty {
            return contactsToFilter
        } else {
            return contactsToFilter.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    emptyStateView
                } else {
                    contactsList
                }
            }
            .navigationTitle("Close")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        Task {
                            await checkContactsPermissionAndShowPicker()
                        }
                    }) {
                        Label("Add Contact", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { selectedContacts in
                    importContacts(selectedContacts)
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding, hasCompletedOnboarding: $hasCompletedOnboarding)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                // Show onboarding only on first launch
                if !hasCompletedOnboarding {
                    showingOnboarding = true
                }
                // Refresh imported dates from iOS Contacts
                await contactsManager.refreshImportedDates(for: contacts, modelContext: modelContext)
                // Schedule custom date notifications for all contacts
                for contact in contacts {
                    await scheduler.updateCustomDateSchedules(for: contact)
                }
            }
        }
        .background(Color("BackgroundPrimary"))
    }
    
    private var contactsList: some View {
        List {
            ForEach(filteredContacts) { contact in
                NavigationLink(destination: ContactDetailView(contact: contact)) {
                    ContactRowView(contact: contact)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(action: {
                        markAsContacted(contact)
                    }) {
                        Label("Done", systemImage: "checkmark")
                    }
                    .tint(Color("StatusGreen"))
                }
                .swipeActions(edge: .leading) {
                    if let phoneNumber = contact.phoneNumber {
                        Button(action: {
                            PhoneActions.call(phoneNumber)
                        }) {
                            Label("Call", systemImage: "phone")
                        }
                        .tint(Color("SoftBlue"))
                    }

                    if let phoneNumber = contact.phoneNumber {
                        Button(action: {
                            PhoneActions.message(phoneNumber)
                        }) {
                            Label("Message", systemImage: "message")
                        }
                        .tint(Color("SoftPurple"))
                    }
                }
            }
            .onDelete(perform: deleteContacts)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("No Contacts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add contacts to start tracking when to stay in touch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { 
                Task {
                    await checkContactsPermissionAndShowPicker()
                }
            }) {
                Label("Add Contacts", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func markAsContacted(_ contact: Contact) {
        Task {
            await scheduler.markContactedAndReschedule(contact: contact)
        }
    }

    private func deleteContacts(offsets: IndexSet) {
        for index in offsets {
            let contact = contacts[index]
            scheduler.cancelSchedule(for: contact)
            modelContext.delete(contact)
        }
    }
    
    private func checkContactsPermissionAndShowPicker() async {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .notDetermined:
            let granted = await contactsManager.requestAccess()
            if granted {
                await MainActor.run {
                    showingContactPicker = true
                }
            } else {
                // Show alert or settings prompt
                contactsManager.openSettings()
            }
        case .authorized:
            await MainActor.run {
                showingContactPicker = true
            }
        case .denied, .restricted:
            contactsManager.openSettings()
        case .limited:
            await MainActor.run {
                showingContactPicker = true
            }
        @unknown default:
            break
        }
    }
    
    private func importContacts(_ cnContacts: [CNContact]) {
        let importedContacts = contactsManager.importFromDeviceContacts(
            cnContacts,
            existingContacts: contacts,
            modelContext: modelContext
        )

        Task {
            await scheduler.updateSchedules(for: importedContacts)
            for contact in importedContacts {
                await scheduler.updateCustomDateSchedules(for: contact)
            }
        }
    }
}

struct ContactRowView: View {
    let contact: Contact

    private var hasTodayEvent: Bool {
        let calendar = Calendar.current
        let today = Date()
        return contact.customDates.contains { customDate in
            let label = customDate.label.lowercased()
            guard label == "birthday" || label == "anniversary" else { return false }
            return calendar.component(.month, from: customDate.date) == calendar.component(.month, from: today)
                && calendar.component(.day, from: customDate.date) == calendar.component(.day, from: today)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ContactImageView(contactIdentifier: contact.contactIdentifier, size: 50)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                    if hasTodayEvent {
                        Image(systemName: "birthday.cake.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }

                Text(contact.statusText)
                    .font(.subheadline)
                    .foregroundStyle(contact.status.color)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                if let phoneNumber = contact.phoneNumber {
                    Button(action: {
                        PhoneActions.call(phoneNumber)
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color("SoftBlue"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        PhoneActions.message(phoneNumber)
                    }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color("SoftPurple"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
}

#Preview {
    ContactsListView()
        .environment(NotificationManager.shared)
        .modelContainer(for: Contact.self, inMemory: true)
}

