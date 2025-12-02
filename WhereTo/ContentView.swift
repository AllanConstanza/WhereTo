//
//  ContentView.swift
//  WhereTo
//
//  Created by Allan Constanza 
import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var loc = LocationManager()
    private let imageService = WikipediaImageService()
    private let geocoder = GeocodingService()

    @State private var showProfile = false

    @State private var displayCities: [City] = [
        City(name: "Los Angeles"),
        City(name: "San Francisco"),
        City(name: "New York"),
        City(name: "Chicago"),
        City(name: "Miami"),
        City(name: "Detroit"),
        City(name: "Sacramento"),
        City(name: "Boston"),
        City(name: "Oakland"),

        City(name: "Seattle"),
        City(name: "San Diego"),
        City(name: "Portland"),
        City(name: "Houston"),
        City(name: "Dallas"),
        City(name: "Philadelphia"),
        City(name: "Atlanta"),
        City(name: "Washington D.C.")
    ]


    @State private var searchText = ""
    @State private var showNoLocationAlert = false

    private var visibleCities: [City] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return displayCities }
        return displayCities.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                CustomSearchBar(text: $searchText, placeholder: "Search Cities")

                List(visibleCities) { city in
                    let distance = loc.location.flatMap { user in
                        city.coord?.distance(from: user)
                    }

                    NavigationLink {
                        CityDetailView(city: city)
                    } label: {
                        CityCardView(city: city, distance: distance)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }
                .listStyle(.plain)
            }
            .navigationTitle("WhereTo")
            .toolbar {

                // To-Do list (leading)
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ToDoListView()
                    } label: {
                        Image(systemName: "checklist")
                    }
                    .accessibilityLabel("Open To-Do")
                }

                // Sort by proximity (trailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await sortByProximity() } } label: {
                        Image(systemName: "location.fill")
                    }
                    .accessibilityLabel("Sort by nearest")
                }

                // Profile button (trailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Open Profile")
                }
            }

            // Correctly placed navigation destination
            .navigationDestination(isPresented: $showProfile) {
                ProfileView()
            }
        }
        .task {
            await geocodeAllIfNeededInPlace()
            await prefetchImagesIfNeededInPlace()
        }
        .onAppear {
            loc.start()
            loc.refresh()
        }
        .alert("Location unavailable",
               isPresented: $showNoLocationAlert,
               actions: { Button("OK", role: .cancel) {} },
               message: { Text("Enable location or set a simulator location to sort by distance.") })
    }

    // Sort by proximity
    @MainActor
    private func sortByProximity() async {
        if loc.location == nil {
            loc.refresh()
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
        guard let user = loc.location else {
            showNoLocationAlert = true
            return
        }
        await geocodeAllIfNeededInPlace()

        var sorted = displayCities
        sorted.sort {
            let a = $0.coord?.distance(from: user) ?? .infinity
            let b = $1.coord?.distance(from: user) ?? .infinity
            return a < b
        }
        withAnimation(.easeInOut) { displayCities = sorted }
    }

    @MainActor
    private func geocodeAllIfNeededInPlace() async {
        try? await Task.sleep(nanoseconds: 150_000_000) // warm-up

        for i in displayCities.indices where displayCities[i].coord == nil {
            let name = displayCities[i].name
            let queries = queriesForCity(name)

            var found: CLLocation? = nil
            for (j, q) in queries.enumerated() {
                if let fix = try? await geocoder.coordinates(for: q) {
                    found = fix
                    break
                }
                try? await Task.sleep(nanoseconds: 180_000_000)

                if j == 0, found == nil {
                    if let fix = try? await geocoder.coordinates(for: q) {
                        found = fix
                        break
                    }
                }
            }

            if let found { displayCities[i].coord = found }
            try? await Task.sleep(nanoseconds: 220_000_000)
        }
    }

    private func queriesForCity(_ name: String) -> [String] {
        let stateHint: [String: String] = [
            "Los Angeles":"CA","San Francisco":"CA","New York":"NY",
            "Chicago":"IL","Miami":"FL","Detroit":"MI",
            "Sacramento":"CA","Boston":"MA","Oakland":"CA"
        ]
        if let st = stateHint[name] {
            return ["\(name), \(st), USA", "\(name), USA", name]
        } else {
            return ["\(name), USA", name]
        }
    }

    @MainActor
    private func prefetchImagesIfNeededInPlace() async {
        await withTaskGroup(of: (Int, URL?).self) { group in
            for (idx, city) in displayCities.enumerated() where city.imageURL == nil {
                group.addTask { [name = city.name] in
                    let url = await imageService.fetchCityImageURL(cityName: name)
                    return (idx, url)
                }
            }
            for await (idx, url) in group {
                if let url { displayCities[idx].imageURL = url }
            }
        }
    }
}

#Preview { ContentView() }

// Custom search bar
private struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .focused($focused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: focused ? .black.opacity(0.1) : .clear, radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
        .animation(.easeInOut, value: focused)
    }
}
