//
//  SettingsView.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI
import SwiftData
import Contacts

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(NotificationManager.self) private var notificationManager
    @State private var contactsManager = ContactsManager()
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                Section("About") {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("Close")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Tracked Contacts")
                        Spacer()
                        Text("\(contacts.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Permissions Section
                Section("Permissions") {
                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(notificationStatusColor)
                            .font(.caption)
                    }
                    
                    if notificationManager.authorizationStatus != .authorized {
                        Button(action: {
                            PhoneActions.openSettings()
                        }) {
                            Text("Open Settings")
                        }
                    }
                    
                    HStack {
                        Label("Contacts", systemImage: "person.crop.circle")
                        Spacer()
                        Text(contactsStatusText)
                            .foregroundStyle(contactsStatusColor)
                            .font(.caption)
                    }
                    
                    if contactsManager.authorizationStatus != .authorized {
                        Button(action: {
                            contactsManager.openSettings()
                        }) {
                            Text("Open Settings")
                        }
                    }
                }
                
                // Help Section
                Section("Help") {
                    Button(action: { showingOnboarding = true }) {
                        Label("Show Onboarding", systemImage: "questionmark.circle")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Use Close")
                            .font(.headline)
                        
                        Text("1. Add contacts you want to stay in touch with")
                        Text("2. Set how often you want to contact each person")
                        Text("3. Get reminders when it's time to reach out")
                        Text("4. Mark contacts as contacted when you connect")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await notificationManager.checkAuthorizationStatus()
                contactsManager.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding, hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .background(Color("BackgroundPrimary"))
    }
    
    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var notificationStatusColor: Color {
        notificationManager.authorizationStatus == .authorized ? Color("StatusGreen") : Color("StatusOrange")
    }
    
    private var contactsStatusText: String {
        switch contactsManager.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .limited:
            return "Limited"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var contactsStatusColor: Color {
        contactsManager.authorizationStatus == .authorized ? Color("StatusGreen") : Color("StatusOrange")
    }
}

#Preview {
    SettingsView()
        .environment(NotificationManager.shared)
        .modelContainer(for: Contact.self, inMemory: true)
}

