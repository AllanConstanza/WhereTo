//
//  CityDetailView.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//

import SwiftUI
import CoreLocation

struct CityDetailView: View {
    let city: City
    let userLocation: CLLocation?

    @State private var landmarks: [Landmark] = []
    @State private var loading = true

    private let geocoder = GeocodingService()
    private let osm = LandmarksService()
    private let wikipedia = WikipediaImageService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = city.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: Rectangle().fill(Color.gray.opacity(0.2))
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure: Rectangle().fill(Color.gray.opacity(0.2))
                        @unknown default: Rectangle().fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text(city.name)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 6)
                            .padding()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Landmarks").font(.headline)
                        if loading { ProgressView().scaleEffect(0.8) }
                    }
                    .padding(.horizontal)

                    if landmarks.isEmpty && !loading {
                        Text("No landmarks found nearby.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(landmarks) { lm in
                                    LandmarkCard(lm: lm)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }

                Divider().padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Events")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(Event.samples(for: city.name)) { evt in
                        EventRow(event: evt).padding(.horizontal)
                    }
                    Spacer(minLength: 16)
                }
            }
            .navigationTitle(city.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await loadLandmarks() }
    }

    @MainActor
    private func loadLandmarks() async {
        loading = true
        defer { loading = false }

        var center = city.coord?.coordinate
        if center == nil, let fix = try? await geocoder.coordinates(for: city.name) {
            center = fix.coordinate
        }
        guard let center else { return }

        let list = (try? await osm.fetchLandmarks(near: center, radiusMeters: 12_000, limit: 18)) ?? []
        var enriched = list
        await withTaskGroup(of: (Int, URL?).self) { group in
            for (idx, lm) in enriched.enumerated() {
                group.addTask { [wikipedia] in
                    if let tag = lm.wikipedia, let u = await wikipedia.fetchImageURL(wikipediaTag: tag) { return (idx, u) }
                    if let qid = lm.wikidata, let u = await wikipedia.fetchImageURL(wikidataID: qid) { return (idx, u) }
                    let t1 = "\(lm.name) \(city.name)"
                    if let u = await wikipedia.fetchImageURL(title: t1) { return (idx, u) }
                    let u2 = await wikipedia.fetchImageURL(title: lm.name)
                    return (idx, u2)
                }
            }
            for await (idx, url) in group {
                if let url { enriched[idx].imageURL = url }
            }
        }
        landmarks = enriched
    }
}

private struct LandmarkCard: View {
    let lm: Landmark
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = lm.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: Rectangle().fill(Color.gray.opacity(0.2))
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: Rectangle().fill(Color.gray.opacity(0.2))
                    @unknown default: Rectangle().fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 200, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))
                    Image(systemName: "mappin.and.ellipse")
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                }
                .frame(width: 200, height: 120)
            }

            Text(lm.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            if let cat = lm.category, !cat.isEmpty {
                Text(cat.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }
}

private struct Event: Identifiable {
    let id = UUID()
    let title: String
    let venue: String
    let time: String

    static func samples(for city: String) -> [Event] {
        switch city.lowercased() {
        case "san francisco":
            return [
                Event(title: "Food Truck Friday", venue: "Fort Mason", time: "Fri 7:00 PM"),
                Event(title: "Open Mic Night", venue: "Mission District", time: "Sat 8:30 PM"),
                Event(title: "Sunset Hike", venue: "Twin Peaks", time: "Sun 6:15 PM")
            ]
        case "los angeles":
            return [
                Event(title: "Outdoor Movie Night", venue: "Griffith Park", time: "Fri 7:30 PM"),
                Event(title: "Indie Concert", venue: "Echo Park", time: "Sat 9:00 PM"),
                Event(title: "Farmers Market", venue: "Santa Monica", time: "Sun 10:00 AM")
            ]
        default:
            return [
                Event(title: "Local Meetup", venue: "Downtown", time: "Thu 6:00 PM"),
                Event(title: "Live Jazz", venue: "Main Street", time: "Sat 8:00 PM"),
                Event(title: "Art Walk", venue: "Old Town", time: "Sun 2:00 PM")
            ]
        }
    }
}

private struct EventRow: View {
    let event: Event
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().frame(width: 10, height: 10).foregroundStyle(.blue).padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.weight(.semibold))
                Text(event.venue).font(.footnote).foregroundColor(.secondary)
                Text(event.time).font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
