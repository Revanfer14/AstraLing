//
//  AstraLingApp.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 14/06/26.
//

import SwiftUI
import FirebaseCore

@main
struct AstraLingApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
