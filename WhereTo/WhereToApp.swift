//
//  WhereToApp.swift
//  WhereTo
//
//  Created by Allan Constanza 
//
import SwiftUI

@main
struct WhereToApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthViewModel()
    @StateObject private var store = ToDoStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }
}


