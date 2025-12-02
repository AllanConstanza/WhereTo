//
//  WhereToApp.swift
//  WhereTo
//
//  Created by Allan Constanza 
import SwiftUI
import Firebase

@main
struct WhereToApp: App {
    @StateObject var auth = AuthViewModel()
    @StateObject var themeManager = ThemeManager()
    @StateObject var store = ToDoStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()                     
                .environmentObject(auth)
                .environmentObject(themeManager)
                .environmentObject(store)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
