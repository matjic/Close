//
//  ContactDetailView.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var contact: Contact
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingDeleteAlert = false
    @State private var showingContactCard = false
    @State private var showingAddCustomDate = false
    
    private let scheduler = ContactScheduler()
    @Environment(NotificationManager.self) private var notificationManager
    
    var body: some View {
        List {
            headerSection
            quickActionsSection
            contactInfoSection
            statusSection
            importantDatesSection
            frequencySection
            notesSection
            deleteSection
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                isPresented: $showingDatePicker,
                onSave: { date in
                    markAsContacted(on: date)
                }
            )
        }
        .sheet(isPresented: $showingContactCard) {
            if let identifier = contact.contactIdentifier {
                ContactCardView(contactIdentifier: identifier)
            }
        }
        .sheet(isPresented: $showingAddCustomDate) {
            AddCustomDateSheet(isPresented: $showingAddCustomDate) { label, date, isRecurring in
                addCustomDate(label: label, date: date, isRecurring: isRecurring)
            }
        }
        .alert("Remove Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Are you sure you want to remove \(contact.name) from tracking? This cannot be undone.")
        }
        .onAppear {
            selectedDate = Date()
        }
        .background(Color("BackgroundPrimary"))
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            VStack(spacing: 12) {
                ContactImageView(contactIdentifier: contact.contactIdentifier, size: 100)

                Text(contact.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(statusColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private var quickActionsSection: some View {
        Section {
            HStack(spacing: 16) {
                Spacer()

                Button(action: { showingDatePicker = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color("StatusGreen"))
                        Text("Done")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                if let phoneNumber = contact.phoneNumber {
                    Button(action: { PhoneActions.call(phoneNumber) }) {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color("SoftBlue"))
                            Text("Call")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }

                    Spacer()
                }

                if let phoneNumber = contact.phoneNumber {
                    Button(action: { PhoneActions.message(phoneNumber) }) {
                        VStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color("SoftPurple"))
                            Text("Message")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .buttonStyle(.plain)
        }
    }

    private var contactInfoSection: some View {
        Section("Contact Information") {
            if contact.contactIdentifier != nil {
                Button(action: { showingContactCard = true }) {
                    HStack {
                        Label("View Full Contact", systemImage: "person.crop.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Text("Name")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(contact.name)
            }

            if let phoneNumber = contact.phoneNumber {
                HStack {
                    Text("Phone")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(phoneNumber)
                }
            }

            if let email = contact.email {
                HStack {
                    Text("Email")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(email)
                        .lineLimit(1)
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Text("Last Contacted")
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastDate = contact.lastContactedDate {
                    let calendar = Calendar.current
                    if calendar.isDateInToday(lastDate) {
                        Text("Today")
                            .foregroundStyle(Color("StatusGreen"))
                    } else if calendar.isDateInYesterday(lastDate) {
                        Text("Yesterday")
                            .foregroundStyle(Color("StatusGreen"))
                    } else {
                        Text(lastDate, style: .date)
                    }
                } else {
                    Text("Never")
                        .foregroundStyle(.tertiary)
                }
            }

            HStack {
                Text("Next Reminder")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(contact.nextReminderDate, style: .date)
                    .foregroundStyle(statusColor)
            }

            HStack {
                Text("Status")
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
            }
        }
    }

    private var importantDatesSection: some View {
        Section {
            ForEach(contact.customDates.sorted(by: { $0.label < $1.label })) { customDate in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(customDate.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if customDate.isRecurring {
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(customDate.date, format: .dateTime.month(.wide).day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if customDate.sourceType == .contacts {
                        Text("Synced")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .onDelete { offsets in
                deleteCustomDates(at: offsets)
            }

            Button(action: { showingAddCustomDate = true }) {
                Label("Add Date", systemImage: "plus.circle")
            }
        } header: {
            Text("Important Dates")
        }
    }

    private var frequencySection: some View {
        Section("Contact Frequency") {
            Picker("Frequency", selection: $contact.frequency) {
                ForEach(ContactFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .onChange(of: contact.frequency) { _, _ in
                updateSchedule()
            }

            if contact.frequency == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Every \(contact.customDaysInterval) day\(contact.customDaysInterval == 1 ? "" : "s")")
                        .font(.subheadline)

                    Stepper("Days", value: $contact.customDaysInterval, in: ContactFrequency.customDaysRange)
                        .labelsHidden()
                        .onChange(of: contact.customDaysInterval) { _, _ in
                            updateSchedule()
                        }

                    Slider(
                        value: Binding(
                            get: { Double(contact.customDaysInterval) },
                            set: { contact.customDaysInterval = Int($0) }
                        ),
                        in: 1.0...365.0,
                        step: 1
                    )
                    .onChange(of: contact.customDaysInterval) { _, _ in
                        updateSchedule()
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $contact.notes)
                .frame(minHeight: 100)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Remove from Tracking", systemImage: "trash")
            }
        }
    }
    
    private var statusColor: Color { contact.status.color }
    private var statusText: String { contact.statusText }

    private func markAsContacted(on date: Date) {
        Task {
            await scheduler.markContactedAndReschedule(contact: contact, on: date)
            try? modelContext.save()
        }
    }
    
    private func updateSchedule() {
        Task {
            await scheduler.updateSchedule(for: contact)
            try? modelContext.save()
        }
    }
    
    private func deleteContact() {
        scheduler.cancelSchedule(for: contact)
        modelContext.delete(contact)
        dismiss()
    }

    private func deleteCustomDates(at offsets: IndexSet) {
        let sorted = contact.customDates.sorted(by: { $0.label < $1.label })
        for index in offsets {
            let customDate = sorted[index]
            // Only allow deleting manual dates
            guard customDate.sourceType != .contacts else { continue }
            notificationManager.cancelCustomDateNotification(for: customDate, contact: contact)
            modelContext.delete(customDate)
        }
    }

    private func addCustomDate(label: String, date: Date, isRecurring: Bool) {
        let customDate = CustomDate(
            label: label,
            date: date,
            isRecurring: isRecurring,
            source: .manual,
            contact: contact
        )
        modelContext.insert(customDate)
        Task {
            await notificationManager.scheduleCustomDateNotification(for: customDate, contact: contact)
            try? modelContext.save()
        }
    }
    
    
}

#Preview {
    @Previewable @State var previewContact = Contact(
        name: "John Doe",
        phoneNumber: "+1234567890",
        email: "john@example.com",
        frequency: .weekly,
        lastContactedDate: Date().addingTimeInterval(-3 * 24 * 60 * 60)
    )
    
    NavigationStack {
        ContactDetailView(contact: previewContact)
            .environment(NotificationManager.shared)
            .modelContainer(for: Contact.self, inMemory: true)
    }
}

