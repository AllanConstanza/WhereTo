//
//  ToDoStore.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class ToDoStore: ObservableObject {
    // Active (not trashed)
    @Published var items: [ToDoItem] = []
    // Recently Deleted (trash)
    @Published var deleted: [ToDoItem] = []

    private var db = Firestore.firestore()
    private var uid: String?
    private var activeListener: ListenerRegistration?
    private var trashListener: ListenerRegistration?

    deinit {
        // deinit is nonisolated; do minimal cleanup here
        activeListener?.remove()
        trashListener?.remove()
        activeListener = nil
        trashListener  = nil
    }


    func connect(userID: String?) {
        detach()
        items = []
        deleted = []
        uid = userID
        guard let uid else { return }

        // Active (todos)
        activeListener = db.collection("users").document(uid)
            .collection("todos")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snap, err in
                Task { @MainActor in
                    guard let self else { return }
                    if let err { print("Active listener error:", err.localizedDescription) }
                    let docs = snap?.documents ?? []
                    self.items = docs.compactMap { Self.itemFrom($0.data()) }
                    self.items.sort(by: Self.dateThenTitle)
                }
            }

        // Trash (recently deleted)
        trashListener = db.collection("users").document(uid)
            .collection("trash")
            .order(by: "deletedAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                Task { @MainActor in
                    guard let self else { return }
                    if let err { print("Trash listener error:", err.localizedDescription) }
                    let docs = snap?.documents ?? []
                    self.deleted = docs.compactMap { Self.itemFrom($0.data()) }
                }
            }
    }

    func detach() {
        activeListener?.remove(); activeListener = nil
        trashListener?.remove();  trashListener  = nil
        items.removeAll()
        deleted.removeAll()
        uid = nil
    }


    func add(_ item: ToDoItem) {
        guard let uid else { return }
        var copy = item; copy.deletedAt = nil
        db.collection("users").document(uid)
            .collection("todos")
            .document(copy.id.uuidString)
            .setData(Self.toDict(copy), merge: true)
    }

    func add(title: String, city: String?, date: Date?) {
        add(ToDoItem(title: title, city: city, date: date))
    }

    func update(_ item: ToDoItem) {
        guard let uid else { return }
        if items.contains(where: { $0.id == item.id }) {
            var copy = item; copy.deletedAt = nil
            db.collection("users").document(uid)
                .collection("todos")
                .document(copy.id.uuidString)
                .setData(Self.toDict(copy), merge: true)
        } else if deleted.contains(where: { $0.id == item.id }) {
            var copy = item; copy.deletedAt = copy.deletedAt ?? Date()
            db.collection("users").document(uid)
                .collection("trash")
                .document(copy.id.uuidString)
                .setData(Self.toDict(copy), merge: true)
        }
    }

    func toggleDone(_ id: UUID) {
        guard let uid, let current = items.first(where: { $0.id == id }) else { return }
        var copy = current; copy.isDone.toggle()
        db.collection("users").document(uid)
            .collection("todos")
            .document(copy.id.uuidString)
            .setData(Self.toDict(copy), merge: true)
    }


    func trash(_ id: UUID) {
        guard let uid,
              let i = items.firstIndex(where: { $0.id == id }) else { return }
        var removed = items.remove(at: i)
        removed.deletedAt = Date()

        deleted.insert(removed, at: 0)

        let batch = db.batch()
        let activeRef = db.collection("users").document(uid).collection("todos").document(removed.id.uuidString)
        let trashRef  = db.collection("users").document(uid).collection("trash").document(removed.id.uuidString)
        batch.deleteDocument(activeRef)
        batch.setData(Self.toDict(removed), forDocument: trashRef)
        batch.commit { error in
            if let error { print("Trash commit error:", error.localizedDescription) }
        }
    }

    func restore(_ id: UUID) {
        guard let uid,
              let j = deleted.firstIndex(where: { $0.id == id }) else { return }
        var restored = deleted.remove(at: j)
        restored.deletedAt = nil

        items.append(restored)
        items.sort(by: Self.dateThenTitle)

        let batch = db.batch()
        let activeRef = db.collection("users").document(uid).collection("todos").document(restored.id.uuidString)
        let trashRef  = db.collection("users").document(uid).collection("trash").document(restored.id.uuidString)
        batch.deleteDocument(trashRef)
        batch.setData(Self.toDict(restored), forDocument: activeRef)
        batch.commit { error in
            if let error { print("Restore commit error:", error.localizedDescription) }
        }
    }

    func deletePermanently(_ id: UUID) {
        guard let uid else { return }
        db.collection("users").document(uid)
            .collection("trash")
            .document(id.uuidString)
            .delete { error in
                if let error { print("Delete permanently error:", error.localizedDescription) }
            }
    }

    func emptyTrash() {
        guard let uid else { return }
        let refs = deleted.map {
            db.collection("users").document(uid).collection("trash").document($0.id.uuidString)
        }
        let batch = db.batch()
        refs.forEach { batch.deleteDocument($0) }
        batch.commit { error in
            if let error { print("Empty trash error:", error.localizedDescription) }
        }
    }


    var sortedByDate: [ToDoItem] {
        items.sorted(by: Self.dateThenTitle)
    }

    var recentlyDeletedSorted: [ToDoItem] {
        deleted.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    private static func dateThenTitle(_ a: ToDoItem, _ b: ToDoItem) -> Bool {
        switch (a.date, b.date) {
        case let (da?, db?):
            return da == db ? (a.title < b.title) : (da < db)
        case (nil, nil):
            return a.title < b.title
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        }
    }


    private static func toDict(_ item: ToDoItem) -> [String: Any] {
        var dict: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "isDone": item.isDone
        ]
        if let city = item.city { dict["city"] = city }
        if let date = item.date { dict["date"] = date }                // Firestore stores as Timestamp
        if let notes = item.notes { dict["notes"] = notes }
        if let urlString = item.urlString { dict["urlString"] = urlString }
        if let deletedAt = item.deletedAt { dict["deletedAt"] = deletedAt } // Firestore Timestamp
        return dict
    }

    private static func itemFrom(_ data: [String: Any]) -> ToDoItem? {
        guard
            let idStr = data["id"] as? String,
            let id = UUID(uuidString: idStr),
            let title = data["title"] as? String
        else { return nil }

        let city = data["city"] as? String

        let date: Date? = {
            if let ts = data["date"] as? Timestamp { return ts.dateValue() }
            if let d  = data["date"] as? Date { return d }
            return nil
        }()

        let notes = data["notes"] as? String
        let urlString = data["urlString"] as? String
        let isDone = data["isDone"] as? Bool ?? false

        let deletedAt: Date? = {
            if let ts = data["deletedAt"] as? Timestamp { return ts.dateValue() }
            if let d  = data["deletedAt"] as? Date { return d }
            return nil
        }()

        return ToDoItem(id: id,
                        title: title,
                        city: city,
                        date: date,
                        notes: notes,
                        urlString: urlString,
                        isDone: isDone,
                        deletedAt: deletedAt)
    }
}
