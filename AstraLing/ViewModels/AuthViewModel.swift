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
    
    func register(name: String, email: String, password: String, role: AppRole) async -> String? {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            let now = Timestamp(date: Date())
            let jakarta = GeoPoint(latitude: -6.2088, longitude: 106.8456)
            let geohash = Geohash.encode(latitude: -6.2088, longitude: 106.8456)

            try db.collection("users").document(uid).setData(from: AppUser(role: role))

            switch role {
            case .customer:
                let customer = Customer(
                    name: name, email: email, balance: 250_000, astraPoints: 0,
                    location: jakarta, geohash: geohash,
                    locationUpdatedAt: now, favorites: [])
                try db.collection("customers").document(uid).setData(from: customer)
            case .merchant:
                let merchant = Merchant(
                    name: name, email: email, balance: 0, astraPoints: 0,
                    category: "lainnya", qrPayload: "astraling://pay/\(uid)")
                try db.collection("merchants").document(uid).setData(from: merchant)
                let presence: [String: Any] = [
                    "merchantUid": uid, "name": name, "category": "lainnya",
                    "isVisible": false, "location": jakarta,
                    "geohash": geohash, "locationUpdatedAt": now
                ]
                try await db.collection("merchants").document(uid)
                    .collection("presence").document("live").setData(presence)
            }

            isLoading = false
            return role.rawValue
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
