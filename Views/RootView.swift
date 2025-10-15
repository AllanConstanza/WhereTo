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
            if auth.user != nil {
                NavigationStack {
                    ContentView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Sign out") {
                                    auth.signOut()
                                    store.connect(userID: nil) 
                                }
                            }
                        }
                }
            } else {
                NavigationStack { SignInView() }
            }
        }
        .onAppear {
            store.connect(userID: auth.user?.uid)
        }
        .onChange(of: auth.user?.uid) { _, newUID in
            store.connect(userID: newUID)
        }
    }
}
