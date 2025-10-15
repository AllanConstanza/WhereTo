//
//  ToDoEditorView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/14/25.
//

import SwiftUI

struct ToDoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var item: ToDoItem
    var onSave: (ToDoItem) -> Void

    @State private var hasDate: Bool

    init(item: ToDoItem, onSave: @escaping (ToDoItem) -> Void) {
        self._item = State(initialValue: item)
        self.onSave = onSave
        self._hasDate = State(initialValue: item.date != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (required)", text: $item.title)

                    TextField("City", text: Binding($item.city, replacingNilWith: ""))
                        .textInputAutocapitalization(.words)

                    Toggle("Has date/time", isOn: $hasDate)
                    if hasDate {
                        DatePicker("When",
                                   selection: Binding($item.date, default: Date()),
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Extras") {
                    TextField("Link (optional)", text: Binding($item.urlString, replacingNilWith: ""))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Notes", text: Binding($item.notes, replacingNilWith: ""))
                }
            }
            .navigationTitle(item.title.isEmpty ? "New To-Do" : "Edit To-Do")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !hasDate { item.date = nil }
                        onSave(item)
                        dismiss()
                    }
                    .disabled(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}


private extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in source.wrappedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue }
        )
    }
}

private extension Binding where Value == Date {
    init(_ source: Binding<Date?>, default defaultDate: Date) {
        self.init(
            get: { source.wrappedValue ?? defaultDate },
            set: { source.wrappedValue = $0 }
        )
    }
}
