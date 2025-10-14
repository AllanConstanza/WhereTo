//
//  RootView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.user != nil {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Sign out") { auth.signOut() }
                        }
                    }
            }
        } else {
            NavigationStack { SignInView() }
        }
    }
}
