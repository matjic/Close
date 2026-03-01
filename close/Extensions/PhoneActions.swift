//
//  PhoneActions.swift
//  close
//

import UIKit

enum PhoneActions {
    static func call(_ phoneNumber: String) {
        let sanitized = phoneNumber.filter { $0.isNumber }
        if let url = URL(string: "tel://\(sanitized)") {
            UIApplication.shared.open(url)
        }
    }

    static func message(_ phoneNumber: String) {
        let sanitized = phoneNumber.filter { $0.isNumber }
        if let url = URL(string: "sms://\(sanitized)") {
            UIApplication.shared.open(url)
        }
    }

    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
