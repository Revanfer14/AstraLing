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
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            RoleSelectionView()
        }
    }
}
