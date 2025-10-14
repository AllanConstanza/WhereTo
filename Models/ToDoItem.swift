//
//  ToDoItem.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import Foundation

struct ToDoItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var city: String?
    var date: Date
    var isDone: Bool

    init(id: UUID = UUID(), title: String, city: String? = nil, date: Date, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.city = city
        self.date = date
        self.isDone = isDone
    }
}


