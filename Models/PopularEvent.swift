//
//  PopularEvent.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/3/25.
//

import Foundation

struct PopularEvent: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var city: String
    var date: Date?
    var imageURL: URL?
    var tmId: String?
    var popularity: Int             
    
    
    var cityKey: String {
        city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}





