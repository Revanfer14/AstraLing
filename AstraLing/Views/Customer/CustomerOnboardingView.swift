//
//  CustomerOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct CustomerOnboardingView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Text("Hello, Customer!")
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button("Logout") {
                        authViewModel.logout()
                        selectedRoleRaw = ""
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    CustomerOnboardingView()
}
