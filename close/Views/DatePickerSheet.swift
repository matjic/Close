//
//  DatePickerSheet.swift
//  close
//

import SwiftUI

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onSave: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Contact Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Mark as Contacted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedDate)
                        isPresented = false
                    }
                }
            }
        }
        .background(Color("BackgroundPrimary"))
    }
}
