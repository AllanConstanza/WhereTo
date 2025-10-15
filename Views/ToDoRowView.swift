//
//  ToDoRowView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/14/25.
//

import SwiftUI

struct ToDoRowView: View {
    let item: ToDoItem
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.isDone ? .green : .secondary)
                    .padding(.top, 3)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .strikethrough(item.isDone, color: .secondary)

                HStack(spacing: 10) {
                    if let city = item.city, !city.isEmpty {
                        Label(city, systemImage: "mappin.and.ellipse")
                    }
                    if let d = item.date {
                        Label(d.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let url = item.url {
                    Link(destination: url) {
                        Label("Open link", systemImage: "link")
                            .font(.footnote)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("Delete", role: .destructive, action: onDelete)
            Button(item.isDone ? "Mark as Not Done" : "Mark as Done", action: onToggle)
        }
    }
}
