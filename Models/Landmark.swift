//
//  Landmark.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//
import Foundation
import CoreLocation

struct Landmark: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var category: String?
    var coord: CLLocationCoordinate2D?
    var imageURL: URL? = nil
    var osmID: String? = nil
    var wikipedia: String? = nil
    var wikidata: String? = nil

    static func == (lhs: Landmark, rhs: Landmark) -> Bool {
        (lhs.osmID ?? lhs.id.uuidString) == (rhs.osmID ?? rhs.id.uuidString)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(osmID ?? id.uuidString)
    }
}


