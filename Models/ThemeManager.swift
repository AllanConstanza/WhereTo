//
//  ThemeManager.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/30/25.
//

import SwiftUI

enum AppTheme: String, Codable {
    case system
    case light
    case dark
}

final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { saveTheme() }
    }

    init() {
        self.theme = ThemeManager.loadTheme()
    }

    private func saveTheme() {
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
    }

    private static func loadTheme() -> AppTheme {
        let raw = UserDefaults.standard.string(forKey: "app_theme") ?? "system"
        return AppTheme(rawValue: raw) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
