//
//  ContactCardView.swift
//  close
//

import SwiftUI
import Contacts
import ContactsUI

struct ContactCardView: UIViewControllerRepresentable {
    let contactIdentifier: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let keys = [CNContactViewController.descriptorForRequiredKeys()]

        do {
            let contact = try store.unifiedContact(withIdentifier: contactIdentifier, keysToFetch: keys)
            let contactViewController = CNContactViewController(for: contact)
            contactViewController.allowsEditing = false
            contactViewController.allowsActions = true

            let navigationController = UINavigationController(rootViewController: contactViewController)

            contactViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: context.coordinator,
                action: #selector(Coordinator.dismissContactCard)
            )

            return navigationController
        } catch {
            let emptyViewController = UIViewController()
            emptyViewController.view.backgroundColor = .systemBackground
            emptyViewController.title = "Contact Not Found"

            let navigationController = UINavigationController(rootViewController: emptyViewController)

            emptyViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: context.coordinator,
                action: #selector(Coordinator.dismissContactCard)
            )

            return navigationController
        }
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        @objc func dismissContactCard() {
            dismiss()
        }
    }
}
