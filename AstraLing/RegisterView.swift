//
//  RegisterView.swift
//  AstraLing
//
//  Created by Rasya Devan on 25/06/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Binding var selectedRoleRaw: String
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var role: AppRole = .customer

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Daftar Akun")
                .font(.largeTitle.bold())

            Text("Buat akun baru untuk mencoba AstraLing")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                TextField("Nama", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocorrectionDisabled()

                TextField("Email (contoh: saya@test.com)", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Picker("Peran", selection: $role) {
                    ForEach(AppRole.allCases, id: \.self) { r in
                        Text(r == .customer ? "Customer" : "Merchant").tag(r)
                    }
                }
                .pickerStyle(.segmented)

                if let errorMessage = authVM.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        if let roleStr = await authVM.register(
                            name: name.trimmingCharacters(in: .whitespaces),
                            email: email.trimmingCharacters(in: .whitespaces),
                            password: password,
                            role: role
                        ) {
                            selectedRoleRaw = roleStr
                        }
                    }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Daftar")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 56)
                .background(authVM.isLoading || !isFormValid ? Color.blue.opacity(0.6) : Color.blue)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .padding(.top, 8)
                .disabled(authVM.isLoading || !isFormValid)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RegisterView(selectedRoleRaw: .constant(""))
            .environmentObject(AuthViewModel())
    }
}
