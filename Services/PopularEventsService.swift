//
//  PopularEventsService.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/3/25.
//

import Foundation
import FirebaseFirestore

final class PopularEventsService {
    private let db = Firestore.firestore()

    private func cityKey(for city: String) -> String {
        city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func upvote(event: PopularEvent, uid: String) async throws {
        try await db.runTransaction { tx, _ in
            let eventRef  = self.db.collection("events").document(event.id)
            let memberRef = eventRef.collection("members").document(uid)

            if let snap = try? tx.getDocument(memberRef), snap.exists { return nil }

            var data: [String: Any] = [
                "title": event.title,
                "city":  event.city,
                "cityKey": event.cityKey,
                "popularityCount": FieldValue.increment(Int64(1))
            ]
            if let d = event.date { data["date"] = Timestamp(date: d) }
            if let u = event.imageURL { data["imageURL"] = u.absoluteString }
            if let tm = event.tmId { data["tmId"] = tm }

            tx.setData(data, forDocument: eventRef, merge: true)
            tx.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: memberRef, merge: true)
            return nil
        }
    }

    func removeVote(eventId: String, uid: String) async throws {
        try await db.runTransaction { tx, _ in
            let eventRef  = self.db.collection("events").document(eventId)
            let memberRef = eventRef.collection("members").document(uid)

            guard let memberSnap = try? tx.getDocument(memberRef), memberSnap.exists else {
                return nil
            }

            if let eventSnap = try? tx.getDocument(eventRef),
               eventSnap.exists,
               let curr = eventSnap.data()?["popularityCount"] as? Int,
               curr <= 1 {
                tx.deleteDocument(eventRef)
            } else {
                tx.setData(["popularityCount": FieldValue.increment(Int64(-1))],
                           forDocument: eventRef,
                           merge: true)
            }

            tx.deleteDocument(memberRef)
            return nil
        }
    }

    func listenTopEvents(
        city: String,
        limit: Int = 5,
        onUpdate: @escaping ([PopularEvent]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        let key = cityKey(for: city)
        let now = Timestamp(date: Date())

        return db.collection("events")
            .whereField("cityKey", isEqualTo: key)
            .whereField("date", isGreaterThanOrEqualTo: now)
            .order(by: "date", descending: false)
            .order(by: "popularityCount", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snap, err in
                if let err = err { onError(err); return }
                guard let docs = snap?.documents else { onUpdate([]); return }

                let items: [PopularEvent] = docs.compactMap { d in
                    let x = d.data()
                    let title = (x["title"] as? String) ?? ""
                    let city  = (x["city"]  as? String) ?? ""
                    let date  = (x["date"]  as? Timestamp)?.dateValue()
                    let img   = (x["imageURL"] as? String).flatMap(URL.init(string:))
                    let tmId  = x["tmId"] as? String
                    let pop   = (x["popularityCount"] as? Int) ?? 0
                    return PopularEvent(
                        id: d.documentID,
                        title: title,
                        city: city,
                        date: date,
                        imageURL: img,
                        tmId: tmId,
                        popularity: pop
                    )
                }
                onUpdate(items)
            }
    }

    func purgeExpired(in city: String) async {
        let key = cityKey(for: city)
        let now = Timestamp(date: Date())
        do {
            let q = db.collection("events")
                .whereField("cityKey", isEqualTo: key)
                .whereField("date", isLessThan: now)
            let snap = try await q.getDocuments()
            guard !snap.documents.isEmpty else { return }
            let batch = db.batch()
            for doc in snap.documents { batch.deleteDocument(doc.reference) }
            try await batch.commit()
        } catch {
        }
    }
}

