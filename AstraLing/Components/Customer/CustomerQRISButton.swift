//
//  CustomerQRISButton.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 22/06/26.
//

import SwiftUI

struct CustomerQRISButton: View {
    var body: some View {
        Button(action: {}) {
            Image("btn-qris")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
    }
}
