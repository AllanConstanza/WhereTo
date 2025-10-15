//
//  ToDoItem.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import Foundation

struct ToDoItem: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var city: String?
    var date: Date?
    var notes: String?
    var urlString: String?
    var isDone: Bool

    var deletedAt: Date?

    init(id: UUID = UUID(),
         title: String,
         city: String? = nil,
         date: Date? = nil,
         notes: String? = nil,
         urlString: String? = nil,
         isDone: Bool = false,
         deletedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.city = city
        self.date = date
        self.notes = notes
        self.urlString = urlString
        self.isDone = isDone
        self.deletedAt = deletedAt
    }

    var url: URL? {
        guard let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }
        return URL(string: s)
    }
}


