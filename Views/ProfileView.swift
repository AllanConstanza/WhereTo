//
//  ProfileView.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/17/25.
//
import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        Form {

            // MARK: — USER INFO SECTION
            Section {
                HStack(spacing: 16) {

                    // --- PROFILE IMAGE ---
                    ZStack {
                        if let urlString = auth.profile?.profileImageURL,
                           let url = URL(string: urlString) {

                            AsyncImage(url: url) { phase in
                                if let img = phase.image {
                                    img.resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.2)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())

                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .onTapGesture { showPhotoPicker = true }

                    // --- EMAIL ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text(auth.user?.email ?? "Unknown Email")
                            .font(.headline)

                        Text("Tap to change photo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            // MARK: — THEME SECTION
            Section(header: Text("Appearance")) {
                Button(action: toggleTheme) {
                    HStack {
                        Image(systemName: themeManager.theme == .dark ? "moon.fill" : "sun.max.fill")
                        Text(themeManager.theme == .dark ? "Switch to Light Mode" : "Switch to Dark Mode")
                    }
                }
            }

            // MARK: — ACCOUNT ACTIONS
            Section {
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Text("Sign Out")
                }

                Button(role: .destructive) {
                    Task { await auth.deleteAccount() }
                } label: {
                    Text("Delete Account")
                }
            }
        }
        .navigationTitle("Profile")
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: Binding(
                get: { nil },
                set: { newItem in
                    Task {
                        if let newItem,
                           let data = try? await newItem.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {

                            selectedImage = img

                            // Upload the JPEG version
                            if let jpeg = img.jpegData(compressionQuality: 0.8) {
                                await auth.uploadProfileImage(jpeg)
                            }
                        }
                    }
                }
            )
        )
    }


    // MARK: — THEME BUTTON ACTION
    private func toggleTheme() {
        withAnimation {
            themeManager.theme =
                themeManager.theme == .dark ? .light : .dark
        }
    }
}


