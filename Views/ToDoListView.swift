//
//  ToDoListView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import SwiftUI

enum ToDoFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case upcoming = "Upcoming"
    case done = "Done"
    var id: String { rawValue }
}

struct ToDoListView: View {
    @EnvironmentObject var store: ToDoStore
    @State private var showEditor = false
    @State private var draft: ToDoItem? = nil
    @State private var filter: ToDoFilter = .all

    private var filtered: [ToDoItem] {
        let base = store.sortedByDate
        switch filter {
        case .all:      return base
        case .upcoming: return base.filter { !$0.isDone }
        case .done:     return base.filter { $0.isDone }
        }
    }

    var body: some View {
        List {
            FilterChips(filter: $filter)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))

            if filtered.isEmpty {
                EmptyStateRow()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filtered) { item in
                    ToDoRowView(
                        item: item,
                        onToggle: { store.toggleDone(item.id) },
                        onTap: { draft = item; showEditor = true },
                        onDelete: { store.trash(item.id) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.trash(item.id)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("To-Do")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    RecentlyDeletedView()
                } label: { Image(systemName: "trash") }
                .accessibilityLabel("Recently Deleted")
            }
        }
        .sheet(isPresented: $showEditor) {
            if let d = draft {
                ToDoEditorView(item: d) { updated in
                    if store.sortedByDate.contains(where: { $0.id == updated.id }) {
                        store.update(updated)
                    } else if store.recentlyDeletedSorted.contains(where: { $0.id == updated.id }) {
                        store.update(updated) // stays in trash
                    } else {
                        store.add(updated)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}


private struct FilterChips: View {
    @Binding var filter: ToDoFilter
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ToDoFilter.allCases) { f in
                    Chip(title: f.rawValue, selected: filter == f) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { filter = f }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(selected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(selected ? Color.accentColor : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateRow: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist").font(.system(size: 44)).foregroundStyle(.secondary)
            Text("No To-Dos yet").font(.headline)
            Text("Add plans from city pages.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
        .background(Color.clear)
    }
}


