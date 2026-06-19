//
//  RoleSelectionView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var selectedRoleRaw: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("AstraLing").font(.largeTitle.bold())
            Text("Pilih role").foregroundStyle(.secondary)
            
            
            VStack {
                Button {
                    selectedRoleRaw = AppRole.customer.rawValue
                } label: {
                    Text("Customer")
                        .padding()
                        .bold()
                }
                .frame(width: 200, height: 60)
                .background(Color.blue)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                
                Button {
                    selectedRoleRaw = AppRole.merchant.rawValue
                } label: {
                    Text("Merchant")
                        .padding()
                        .bold()
                }
                .frame(width: 200, height: 60)
                .background(Color.red)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            }
        }
    }}

#Preview {
    RoleSelectionView(selectedRoleRaw: .constant(""))
}
