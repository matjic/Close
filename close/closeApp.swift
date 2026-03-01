//
//  closeApp.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct closeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Contact.self,
            CustomDate.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContactsListView()
                .environment(NotificationManager.shared)
                .onAppear {
                    appDelegate.modelContainer = sharedModelContainer
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// AppDelegate to handle notification actions
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var modelContainer: ModelContainer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let contactIdString = userInfo["contactId"] as? String,
              let contactId = UUID(uuidString: contactIdString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case NotificationManager.callActionIdentifier:
            handleCallAction(contactId: contactId)
        case NotificationManager.messageActionIdentifier:
            handleMessageAction(contactId: contactId)
        case NotificationManager.doneActionIdentifier:
            handleDoneAction(contactId: contactId)
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleCallAction(contactId: UUID) {
        Task {
            if let contact = await getContact(by: contactId),
               let phoneNumber = contact.phoneNumber {
                await MainActor.run {
                    PhoneActions.call(phoneNumber)
                }
                await markAsContacted(contactId: contactId)
            }
        }
    }

    private func handleMessageAction(contactId: UUID) {
        Task {
            if let contact = await getContact(by: contactId),
               let phoneNumber = contact.phoneNumber {
                await MainActor.run {
                    PhoneActions.message(phoneNumber)
                }
                await markAsContacted(contactId: contactId)
            }
        }
    }
    
    private func handleDoneAction(contactId: UUID) {
        // Mark contact as contacted
        Task {
            await markAsContacted(contactId: contactId)
        }
    }
    
    private func getContact(by id: UUID) async -> Contact? {
        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let modelContainer = self.modelContainer,
              let contact = try? modelContainer.mainContext.fetch(descriptor).first else {
            return nil
        }
        
        return contact
    }
    
    private func markAsContacted(contactId: UUID) async {
        guard let contact = await getContact(by: contactId) else { return }
        
        let scheduler = ContactScheduler()
        await scheduler.markContactedAndReschedule(contact: contact)
    }
}
