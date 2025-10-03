//
//  City.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/14/25.
//

import Foundation
import CoreLocation

struct City: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var coord: CLLocation? = nil
    var imageURL: URL? = nil       
    var imageData: Data? = nil
}


