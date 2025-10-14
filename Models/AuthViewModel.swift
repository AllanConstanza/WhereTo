//
//  AuthViewModel.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorText: String?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    deinit { if let handle { Auth.auth().removeStateDidChangeListener(handle) } }

    func signUp() async {
        errorText = nil
        do { _ = try await Auth.auth().createUser(withEmail: email, password: password) }
        catch { errorText = error.localizedDescription }
    }

    func signIn() async {
        errorText = nil
        do { _ = try await Auth.auth().signIn(withEmail: email, password: password) }
        catch { errorText = error.localizedDescription }
    }

    func signOut() {
        do { try Auth.auth().signOut() } catch { errorText = error.localizedDescription }
    }
}
