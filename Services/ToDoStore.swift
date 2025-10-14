//
//  ToDoStore.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//


import Foundation

@MainActor
final class ToDoStore: ObservableObject {
    @Published private(set) var items: [ToDoItem] = []

    init() {
        let now = Date()
        items = [
            ToDoItem(title: "Walk the riverfront", city: "Chicago", date: now.addingTimeInterval(60*60*24*1)),
            ToDoItem(title: "Museum stop",        city: "Boston",  date: now.addingTimeInterval(60*60*24*2)),
            ToDoItem(title: "Sunset viewpoint",   city: "LA",      date: now.addingTimeInterval(60*60*24*3))
        ]
        sortInPlace()
    }

    //Add a new dummy item with a future date
    func addDummy() {
        let n = items.count + 1
        let item = ToDoItem(
            title: "Sample Task \(n)",
            city: ["LA","SF","NYC","Miami","Boston"].randomElement(),
            date: Date().addingTimeInterval(Double(n) * 60*60*12) // every 12h
        )
        items.append(item)
        sortInPlace()
    }
    
    func add(title: String, city: String?, date: Date) {
        items.append(ToDoItem(title: title, city: city, date: date))
        items.sort { $0.date < $1.date }
    }


    func toggleDone(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isDone.toggle()
    }

    func remove(id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items.remove(at: idx)
        }
    }

    var sortedByDate: [ToDoItem] {
        items.sorted { $0.date < $1.date }
    }

    private func sortInPlace() {
        items.sort { $0.date < $1.date }
    }
}

