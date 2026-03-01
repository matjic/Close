//
//  CustomDate.swift
//  close
//
//  Created by Mathew Jacob on 2/28/26.
//

import Foundation
import SwiftData

enum CustomDateSource: String {
    case contacts = "contacts"
    case manual = "manual"
}

@Model
final class CustomDate {
    var id: UUID
    var label: String
    var date: Date
    var isRecurring: Bool
    var source: String
    var contact: Contact?

    var sourceType: CustomDateSource {
        get { CustomDateSource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        label: String,
        date: Date,
        isRecurring: Bool = true,
        source: CustomDateSource = .manual,
        contact: Contact? = nil
    ) {
        self.id = id
        self.label = label
        self.date = date
        self.isRecurring = isRecurring
        self.source = source.rawValue
        self.contact = contact
    }
}
