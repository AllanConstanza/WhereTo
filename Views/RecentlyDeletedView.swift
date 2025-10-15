//
//  RecentlyDeletedView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/14/25.
//

import SwiftUI

struct RecentlyDeletedView: View {
    @EnvironmentObject var store: ToDoStore
    @State private var confirmEmpty = false

    var body: some View {
        List {
            if store.recentlyDeletedSorted.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "trash")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Nothing in Trash")
                            .font(.headline)
                        Text("Deleted to-dos will appear here for easy restore.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(store.recentlyDeletedSorted) { item in
                        RecentlyDeletedRow(
                            item: item,
                            onRestore: { store.restore(item.id) },
                            onDelete: { store.deletePermanently(item.id) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recently Deleted")
        .toolbar {
            if !store.recentlyDeletedSorted.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Empty Trash") { confirmEmpty = true }
                }
            }
        }
        .alert("Empty Trash?", isPresented: $confirmEmpty) {
            Button("Cancel", role: .cancel) {}
            Button("Empty", role: .destructive) { store.emptyTrash() }
        } message: {
            Text("This permanently deletes all items in Recently Deleted.")
        }
    }
}

private struct RecentlyDeletedRow: View {
    let item: ToDoItem
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 10) {
                    if let city = item.city?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    if let d = item.date {
                        Label(d.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .lineLimit(1)
                    }
                    if let del = item.deletedAt {
                        let rel = RelativeDateTimeFormatter().localizedString(for: del, relativeTo: Date())
                        Label("Deleted \(rel)", systemImage: "clock")
                            .lineLimit(1)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: onRestore) {
                    Label("Restore", systemImage: "arrow.uturn.left.circle")
                }
                .buttonStyle(.bordered)
                .labelStyle(.titleAndIcon)
                .fixedSize() 
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                }
                .buttonStyle(.bordered)
                .labelStyle(.titleAndIcon)
                .fixedSize()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
    }
}
