//
//  GeocodingService.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/14/25.
//

import Foundation
import CoreLocation

final class GeocodingService {
    private let geocoder = CLGeocoder()

    func coordinates(for city: String) async throws -> CLLocation? {
        let placemarks = try await geocoder.geocodeAddressString(city)
        return placemarks.first?.location
    }
}


