//
//  UserProfile.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/30/25.
//

struct UserProfile: Codable, Identifiable {
    var id: String?
    var profileImageURL: String?
    var darkModeEnabled: Bool?
    var displayName: String?   // REQUIRED for your ProfileView
}


