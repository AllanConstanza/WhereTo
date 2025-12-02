//
//  RootView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var store: ToDoStore

    var body: some View {
        Group {

            if !auth.isAuthLoaded {
                ProgressView("Loading…")
            }
            else if auth.user == nil {
                NavigationStack { SignInView() }
            }
            else {
                NavigationStack {
                    ContentView()
                }
            }
        }
        .task {
            store.connect(userID: auth.user?.uid)
        }
        .onChange(of: auth.user?.uid) { _, new in
            store.connect(userID: new)
        }
    }
}

