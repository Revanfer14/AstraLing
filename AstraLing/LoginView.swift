//
//  LoginView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Binding var selectedRoleRaw: String
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("AstraLing")
                .font(.largeTitle.bold())
            
            Text("Silakan Login")
                .foregroundStyle(.secondary)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
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
                
                if let errorMessage = authVM.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task {
                        if let role = await authVM.login(email: email, password: password) {
                            selectedRoleRaw = role
                        }
                    }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 56)
                .background(authVM.isLoading ? Color.blue.opacity(0.6) : Color.blue)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .padding(.top, 8)
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    LoginView(selectedRoleRaw: .constant(""))
}
