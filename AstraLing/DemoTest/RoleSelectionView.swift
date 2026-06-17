import SwiftUI

enum AppRole {
    case customer, merchant
}

struct RoleSelectionView: View {
    @State private var role: AppRole?

    var body: some View {
        if let role {
            switch role {
            case .customer: CustomerMapView()
            case .merchant: MerchantView()
            }
        } else {
            VStack(spacing: 24) {
                Spacer()
                Text("AstraLing")
                    .font(.largeTitle.bold())
                Text("Pick a role for this device")
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    role = .customer
                } label: {
                    Label("I'm a Customer", systemImage: "person.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    role = .merchant
                } label: {
                    Label("I'm a Merchant", systemImage: "cart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(32)
        }
    }
}
