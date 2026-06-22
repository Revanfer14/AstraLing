//
//  ContentView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 14/06/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    
    private var role: AppRole? {
        AppRole(rawValue: selectedRoleRaw)
    }
    
    var body: some View {
        switch role {
        case .customer: CustomerOnboardingView()
        case .merchant: MerchantOnboardingView()
        case nil:       LoginView(selectedRoleRaw: $selectedRoleRaw)
        }
    }
}

#Preview {
    ContentView()
}
