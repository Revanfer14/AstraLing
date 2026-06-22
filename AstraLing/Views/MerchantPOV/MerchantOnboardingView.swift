//
//  MerchantOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct MerchantOnboardingView: View {
    @AppStorage("selectedRole") private var selectedRoleRaw: String = ""
    
    var body: some View {
        ZStack {
            Text("Hello, Merchant!")
            
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
    MerchantOnboardingView()
}
