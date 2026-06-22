//
//  AuthViewModel.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    func login(email: String, password: String) async -> String? {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let uid = authResult.user.uid
            
            let userRole = try await fetchUserRole(uid: uid)
            
            isLoading = false
            return userRole
            
        } catch {
            isLoading = false
            self.errorMessage = error.localizedDescription
            return nil
        }
    }
    
    private func fetchUserRole(uid: String) async throws -> String {
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard let data = document.data(), let role = data["role"] as? String else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Role user tidak ditemukan di database."])
        }
        
        return role
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
