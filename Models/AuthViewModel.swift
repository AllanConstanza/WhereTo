//
//  AuthViewModel.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State
    @Published var isAuthLoaded = false
    @Published var user: FirebaseAuth.User? = nil
    @Published var profile: UserProfile? = nil

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorText: String?

    // MARK: - Firebase References
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var handle: AuthStateDidChangeListenerHandle?

    // MARK: - Init
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.user = user

            Task {
                if let _ = user {
                    await self.loadProfile()
                }
                self.isAuthLoaded = true   // finished loading initial state
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    // MARK: - Sign Up
    func signUp() async {
        errorText = nil
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorText = error.localizedDescription
        }
    }

    // MARK: - Sign In
    func signIn() async {
        errorText = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorText = error.localizedDescription
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.profile = nil
        } catch {
            errorText = error.localizedDescription
        }
    }

    // MARK: - Load profile (Firestore)
    func loadProfile() async {
        guard let uid = user?.uid else { return }

        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            let data = doc.data()

            let profile = UserProfile(
                id: uid,
                profileImageURL: data?["profileImageURL"] as? String,
                darkModeEnabled: data?["darkModeEnabled"] as? Bool
            )

            self.profile = profile

        } catch {
            print("Failed to load profile:", error)
        }
    }

    // MARK: - Upload Profile Image
    func uploadProfileImage(_ data: Data) async {
        guard let uid = user?.uid else { return }

        let ref = storage.reference().child("profileImages/\(uid).jpg")

        do {
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()

            try await db.collection("users").document(uid)
                .setData(["profileImageURL": url.absoluteString], merge: true)

            await loadProfile()

        } catch {
            print("Upload error:", error)
        }
    }

    // MARK: - Toggle Dark Mode
    func toggleDarkMode(_ newValue: Bool) async {
        guard let uid = user?.uid else { return }

        do {
            try await db.collection("users").document(uid)
                .setData(["darkModeEnabled": newValue], merge: true)

            await loadProfile()

        } catch {
            print("Failed to toggle dark mode:", error)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        let uid = user.uid

        do {
            // Delete Firestore profile document
            try await db.collection("users").document(uid).delete()

            // Delete profile picture
            let ref = storage.reference().child("profileImages/\(uid).jpg")
            try? await ref.delete()

            // Delete Auth user
            try await user.delete()

            // Reset state
            self.user = nil
            self.profile = nil
            return true

        } catch {
            print("Delete account error:", error)
            return false
        }
    }
}

