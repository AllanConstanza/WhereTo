//
//  CityDetailView.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//

import SwiftUI
import CoreLocation
import UIKit

struct CityDetailView: View {
    let city: City

    @EnvironmentObject private var todo: ToDoStore

    @State private var cityCoord: CLLocationCoordinate2D?
    @State private var landmarks: [Landmark] = []
    @State private var isLoadingLandmarks = false
    @State private var landmarkError: String?

    @State private var events: [LiveEvent] = []
    @State private var isLoadingEvents = false
    @State private var eventsError: String?

    @State private var showAddedToast = false

    private let geocoder = GeocodingService()
    private let wiki     = WikipediaImageService()
    private let osm      = LandmarksService()
    private let tm       = TicketmasterService(key: AppConfig.ticketmasterKey)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                AsyncImage(url: city.imageURL) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.gray.opacity(0.15)
                    }
                }
                .frame(height: 220)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    Text(city.name)
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                        .padding()
                }

                HStack {
                    Text("Top Landmarks").font(.title2).bold()
                    if isLoadingLandmarks { ProgressView().padding(.leading, 6) }
                }
                .padding(.horizontal)

                if let err = landmarkError {
                    Text(err).foregroundColor(.red).padding(.horizontal)
                }

                if !landmarks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(landmarks.prefix(10)) { lm in
                                LandmarkCard(landmark: lm) {
                                    let when = Date().addingTimeInterval(60*60*24*2)
                                    todo.add(title: lm.name, city: city.name, date: when)
                                    notifyAdded()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                HStack {
                    Text("Live Events").font(.title2).bold()
                    if isLoadingEvents { ProgressView().padding(.leading, 6) }
                }
                .padding(.horizontal)

                if let err = eventsError {
                    Text(err).foregroundColor(.red).padding(.horizontal)
                }

                VStack(spacing: 12) {
                    ForEach(events) { ev in
                        EventRow(event: ev) {
                            todo.add(title: ev.title, city: city.name, date: ev.date)
                            notifyAdded()
                        }
                        .padding(.horizontal)
                    }
                }

                Text("Data © OpenStreetMap contributors, Wikipedia, Ticketmaster")
                    .font(.footnote).foregroundColor(.secondary)
                    .padding([.horizontal, .bottom])
            }
        }
        .task { await loadAll() }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showAddedToast {
                AddedToastView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showAddedToast)
    }

    private func loadAll() async {
        do {
            let loc: CLLocation
            if let c = city.coord {
                cityCoord = c.coordinate
                loc = c
            } else if let found = try await geocoder.coordinates(for: city.name) {
                cityCoord = found.coordinate
                loc = found
            } else {
                throw NSError(domain: "WhereTo", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Could not locate city."])
            }

            await loadLandmarks(near: loc.coordinate)

            await loadEvents(near: loc.coordinate)

        } catch {
            landmarkError = error.localizedDescription
            eventsError = "Waiting for location…"
        }
    }

    private func loadLandmarks(near coord: CLLocationCoordinate2D) async {
        isLoadingLandmarks = true
        landmarkError = nil
        defer { isLoadingLandmarks = false }

        do {
            var items = try await osm.fetchLandmarks(near: coord, radiusMeters: 12_000, limit: 20)

            await withTaskGroup(of: Void.self) { group in
                for i in items.indices {
                    group.addTask {
                        if let url = await wiki.fetchImageURL(title: items[i].name) {
                            Task { @MainActor in items[i].imageURL = url }
                        } else if let tag = items[i].wikipedia,
                                  let url = await wiki.fetchImageURL(wikipediaTag: tag) {
                            Task { @MainActor in items[i].imageURL = url }
                        } else if let qid = items[i].wikidata,
                                  let url = await wiki.fetchImageURL(wikidataID: qid) {
                            Task { @MainActor in items[i].imageURL = url }
                        }
                    }
                }
            }

            func score(_ lm: Landmark) -> Int {
                let c = (lm.category ?? "").lowercased()
                if c.contains("museum") || c.contains("landmark") || c.contains("monument") { return 0 }
                if c.contains("historic") || c.contains("attraction") { return 1 }
                if c.contains("park") || c.contains("viewpoint") { return 2 }
                return 3
            }
            items.sort { a, b in
                let sa = score(a), sb = score(b)
                return sa == sb ? (a.name < b.name) : (sa < sb)
            }

            self.landmarks = items

        } catch {
            self.landmarkError = error.localizedDescription
        }
    }

    private func loadEvents(near coord: CLLocationCoordinate2D) async {
        guard AppConfig.hasTicketmasterKey else {
            self.events = dummyEvents()
            return
        }
        isLoadingEvents = true
        eventsError = nil
        defer { isLoadingEvents = false }

        do {
            let start = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
            let tmEvents = try await tm.events(near: coord, radiusMiles: 25, size: 20, startDate: start)
            self.events = tmEvents.map { tm in
                LiveEvent(title: tm.name,
                          venue: tm.venue ?? "TBA",
                          date: tm.date ?? Date().addingTimeInterval(86400),
                          url: tm.url,
                          imageURL: tm.imageURL)
            }
        } catch {
            self.eventsError = error.localizedDescription
            self.events = dummyEvents()
        }
    }

    private func notifyAdded() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showAddedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showAddedToast = false }
    }

    private func dummyEvents() -> [LiveEvent] {
        let now = Date()
        return [
            LiveEvent(title: "Sunset Rooftop Sessions", venue: "Skyline Lounge", date: now.addingTimeInterval(60*60*24*1)),
            LiveEvent(title: "Indie Night Market",      venue: "Harbor Walk",    date: now.addingTimeInterval(60*60*24*2)),
            LiveEvent(title: "Open-Air Jazz",           venue: "Central Park",   date: now.addingTimeInterval(60*60*24*3)),
            LiveEvent(title: "Food Truck Fridays",      venue: "Arts District",  date: now.addingTimeInterval(60*60*24*4))
        ]
    }
}

private struct LandmarkCard: View {
    let landmark: Landmark
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: landmark.imageURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.gray.opacity(0.2)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(landmark.name)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 100)

            Button(action: onAdd) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(landmark.name) to To-Do")
        }
    }
}

private struct EventRow: View {
    let event: LiveEvent
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let url = event.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.gray.opacity(0.15)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "sparkles")
                    .frame(width: 64, height: 64)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.headline)
                HStack(spacing: 8) {
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                    Label(event.date.formatted(date: .abbreviated, time: .shortened),
                          systemImage: "calendar")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if let link = event.url {
                    Link("Open in Ticketmaster", destination: link).font(.footnote)
                }
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle").imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(event.title) to To-Do")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
    }
}

private struct AddedToastView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").imageScale(.large)
            Text("Added to To-Do").font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.top, 8)
    }
}

private struct LiveEvent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let venue: String
    let date: Date
    var url: URL? = nil
    var imageURL: URL? = nil
}

