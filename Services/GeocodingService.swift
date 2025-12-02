//
//  GeocodingService.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/14/25.
//

import Foundation
import CoreLocation

actor GeocodingService {
    private let geocoder = CLGeocoder()

    // In-memory cache to avoid repeating calls
    private var cache: [String: CLLocation] = [:]

    func coordinates(for city: String) async throws -> CLLocation {
        // 1. If cached → instant
        if let loc = cache[city] { return loc }

        // 2. One normalized query only
        let query = "\(city), USA"

        // 3. Call Apple geocoder
        let placemarks = try await geocoder.geocodeAddressString(query)

        if let loc = placemarks.first?.location {
            cache[city] = loc
            return loc
        }

        // 4. Fallback → try plain city name
        let fallback = try await geocoder.geocodeAddressString(city)

        if let loc = fallback.first?.location {
            cache[city] = loc
            return loc
        }

        throw NSError(domain: "Geocoder", code: 0)
    }
}


