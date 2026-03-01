//
//  AddCustomDateSheet.swift
//  close
//

import SwiftUI

struct AddCustomDateSheet: View {
    @Binding var isPresented: Bool
    let onSave: (String, Date, Bool) -> Void

    @State private var label = ""
    @State private var date = Date()
    @State private var isRecurring = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label (e.g., Graduation)", text: $label)

                DatePicker("Date", selection: $date, displayedComponents: [.date])

                Toggle("Repeats annually", isOn: $isRecurring)
            }
            .navigationTitle("Add Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(label, date, isRecurring)
                        isPresented = false
                    }
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
