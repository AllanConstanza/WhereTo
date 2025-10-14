//
//  ToDoListView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import SwiftUI

struct ToDoListView: View {
    @EnvironmentObject var store: ToDoStore

    var body: some View {
        List {
            if store.sortedByDate.isEmpty {
                ContentUnavailableView("No To-Dos yet",
                                       systemImage: "checklist",
                                       description: Text("Tap + to add a sample item."))
            } else {
                ForEach(store.sortedByDate) { item in
                    ToDoRow(item: item) {
                        store.toggleDone(item.id)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.remove(id: item.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("To-Do")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.addDummy()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add sample to-do")
            }
        }
    }
}

private struct ToDoRow: View {
    let item: ToDoItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .strikethrough(item.isDone, color: .secondary)

                HStack(spacing: 6) {
                    if let city = item.city {
                        Label(city, systemImage: "mappin.and.ellipse")
                    }
                    Label(item.date.formatted(date: .abbreviated, time: .shortened),
                          systemImage: "calendar")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }
}
