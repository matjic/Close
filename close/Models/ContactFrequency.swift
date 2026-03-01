//
//  ContactFrequency.swift
//  close
//
//  Created by Mathew Jacob on 10/12/25.
//

import Foundation

enum ContactFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var days: Int? {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .custom: return nil
        }
    }
    
    static let customDaysRange = 1...365

    var displayName: String {
        return self.rawValue
    }
}

