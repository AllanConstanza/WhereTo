//
//  SignInView.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthViewModel
    @FocusState private var focused: Field?
    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 18) {
            Text("WhereTo").font(.largeTitle).bold().padding(.top, 24)

            VStack(spacing: 12) {
                TextField("Email", text: $auth.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .focused($focused, equals: .email)

                SecureField("Password (6+ chars)", text: $auth.password)
                    .textContentType(.password)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .focused($focused, equals: .password)
            }
            .padding(.horizontal)

            if let e = auth.errorText {
                Text(e).foregroundColor(.red).font(.footnote).padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button { Task { await auth.signIn() } } label: {
                    Text("Sign In").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)

                Button { Task { await auth.signUp() } } label: {
                    Text("Sign Up").frame(maxWidth: .infinity)
                }.buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .onAppear { focused = .email }
    }
}

#Preview {
    SignInView().environmentObject(AuthViewModel())
}
