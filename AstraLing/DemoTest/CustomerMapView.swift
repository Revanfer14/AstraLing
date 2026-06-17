import SwiftUI
import MapKit

struct CustomerMapView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var firestore = FirestoreService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedMerchant: Merchant?

    // For the demo this is a fixed name; swap for a real customer profile later.
    private let customerName = "Customer"

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(firestore.activeMerchants) { merchant in
                Annotation(merchant.name, coordinate: merchant.coordinate) {
                    Button {
                        selectedMerchant = merchant
                    } label: {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.blue, in: Circle())
                            .shadow(radius: 3)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
        .onAppear {
            location.request()
            firestore.startListeningToMerchants()
        }
        .sheet(item: $selectedMerchant) { merchant in
            VendorDetailSheet(merchant: merchant) {
                firestore.sendPing(
                    to: merchant,
                    customerName: customerName,
                    location: location.location
                )
            }
            .presentationDetents([.medium])
        }
    }
}

struct VendorDetailSheet: View {
    let merchant: Merchant
    let onPing: () -> Void
    @State private var pinged = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(merchant.name)
                .font(.title2.bold())
            Text(merchant.category)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                onPing()
                pinged = true
            } label: {
                Label(pinged ? "Ping sent!" : "Ping this merchant",
                      systemImage: pinged ? "checkmark.circle.fill" : "hand.wave.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pinged)
        }
        .padding(24)
    }
}
