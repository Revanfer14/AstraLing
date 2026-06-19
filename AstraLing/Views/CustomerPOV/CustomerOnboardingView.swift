//
//  CustomerOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct CustomerOnboardingView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    
    var body: some View {
        ZStack {
            Text("Hello, Customer!")
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button("Ganti Peran") {
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
