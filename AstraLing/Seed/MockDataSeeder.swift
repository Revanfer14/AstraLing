import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Mock accounts
//
// 2 merchants + 4 customers, all using the same password below.
// Credentials are printed to the Xcode console when the seeder runs.
// Trigger: the orange "Seed Mock Data" button visible only in DEBUG builds on the role-selection screen.

@MainActor
final class MockDataSeeder {

    static let password = "Astra123!"

    private let db = Firestore.firestore()

    func seedAll() async {
        print("""

        [Seeder] ══════════════════════════════════════
        [Seeder]   AstraLing — Seeding mock accounts
        [Seeder]   Password (all accounts): \(MockDataSeeder.password)
        [Seeder] ══════════════════════════════════════
        """)

        let merchantIds = await seedMerchants()
        await seedCustomers(merchantIds: merchantIds)

        try? Auth.auth().signOut()

        print("""

        [Seeder] ══════════════════════════════════════
        [Seeder]   Done! Sign in with any account above.
        [Seeder]   Password: \(MockDataSeeder.password)
        [Seeder] ══════════════════════════════════════
        """)
    }

    // MARK: - Merchants

    private struct MerchantSeed {
        let email, name, category, description: String
        let lat, lng: Double
        let balance, astraPoints: Int
        let menu: [(name: String, price: Int, category: String)]
    }

    private func seedMerchants() async -> [String] {
        let seeds: [MerchantSeed] = [
            MerchantSeed(
                email: "merchant1@astraling.test",
                name: "Warung Bakso Pak Haji",
                category: "bakso",
                description: "Bakso segar dibuat tiap hari, kuah gurih khas Malang.",
                lat: -6.2088, lng: 106.8456,
                balance: 2_500_000, astraPoints: 150,
                menu: [
                    ("Bakso Biasa", 15_000, "Makanan"),
                    ("Bakso Urat", 18_000, "Makanan"),
                    ("Bakso Malang Komplit", 22_000, "Makanan"),
                    ("Es Teh Manis", 5_000, "Minuman")
                ]
            ),
            MerchantSeed(
                email: "merchant2@astraling.test",
                name: "Martabak Bang Jarwo",
                category: "martabak",
                description: "Martabak legendaris sejak 1985, isi melimpah tidak pelit.",
                lat: -6.2215, lng: 106.8412,
                balance: 1_800_000, astraPoints: 90,
                menu: [
                    ("Manis Coklat", 35_000, "Makanan"),
                    ("Manis Keju", 35_000, "Makanan"),
                    ("Manis Coklat Keju", 40_000, "Makanan"),
                    ("Telur Kornet", 40_000, "Makanan")
                ]
            ),
            MerchantSeed(
                email: "merchant3@astraling.test",
                name: "Batagor Cimol",
                category: "batagor",
                description: "Batagor dan cimol kenyal bumbu kacang khas Bandung.",
                lat: -6.2100, lng: 106.8440,
                balance: 900_000, astraPoints: 60,
                menu: [
                    ("Batagor Kuah", 12_000, "Makanan"),
                    ("Batagor Kering", 12_000, "Makanan"),
                    ("Cimol Original", 8_000, "Makanan"),
                    ("Cimol Pedas", 8_000, "Makanan")
                ]
            ),
            MerchantSeed(
                email: "merchant4@astraling.test",
                name: "Cilok Gemoy",
                category: "cilok",
                description: "Cilok kenyal isi telur puyuh, saus kacang dan saus pedas.",
                lat: -6.2050, lng: 106.8480,
                balance: 700_000, astraPoints: 40,
                menu: [
                    ("Cilok Original", 5_000, "Makanan"),
                    ("Cilok Isi Telur", 7_000, "Makanan"),
                    ("Cilok Jumbo", 10_000, "Makanan")
                ]
            ),
            MerchantSeed(
                email: "merchant5@astraling.test",
                name: "Soto Betawi Makyar",
                category: "soto",
                description: "Soto Betawi asli santan segar, daging empuk, taburan emping.",
                lat: -6.2140, lng: 106.8395,
                balance: 3_200_000, astraPoints: 220,
                menu: [
                    ("Soto Betawi Biasa", 25_000, "Makanan"),
                    ("Soto Betawi Spesial", 32_000, "Makanan"),
                    ("Es Jeruk", 7_000, "Minuman"),
                    ("Kerupuk", 3_000, "Makanan")
                ]
            ),
            MerchantSeed(
                email: "merchant6@astraling.test",
                name: "Cakwe & Odading Mas Boing",
                category: "cakwe",
                description: "Cakwe goreng renyah dan odading viral, cocok buat sarapan.",
                lat: -6.2070, lng: 106.8510,
                balance: 1_100_000, astraPoints: 75,
                menu: [
                    ("Cakwe Polos", 5_000, "Makanan"),
                    ("Cakwe Isi Udang", 8_000, "Makanan"),
                    ("Odading", 6_000, "Makanan"),
                    ("Kopi Susu", 10_000, "Minuman")
                ]
            )
        ]

        var merchantIds: [String] = []
        for (i, seed) in seeds.enumerated() {
            guard let uid = await getOrCreate(email: seed.email) else { continue }

            let geo = GeoPoint(latitude: seed.lat, longitude: seed.lng)
            let now = Timestamp(date: Date())

            let user = AppUser(role: .merchant)
            let merchant = Merchant(
                name: seed.name,
                email: seed.email,
                balance: seed.balance,
                astraPoints: seed.astraPoints,
                category: seed.category,
                description: seed.description,
                qrPayload: "astraling://pay/\(uid)",
                location: geo,
                geohash: Geohash.encode(latitude: seed.lat, longitude: seed.lng),
                locationUpdatedAt: now,
                isVisible: true
            )

            do {
                try db.collection("users").document(uid).setData(from: user)
                try db.collection("merchants").document(uid).setData(from: merchant)

                let menuRef = db.collection("merchants").document(uid).collection("menu")
                for (order, item) in seed.menu.enumerated() {
                    let menuItem = MenuItem(name: item.name, price: item.price, category: item.category, order: order)
                    _ = try menuRef.addDocument(from: menuItem)
                }

                merchantIds.append(uid)
                print("[Seeder] ✓ Merchant \(i + 1): \(seed.name)  (\(seed.email))")
            } catch {
                print("[Seeder] ✗ Failed writing merchant '\(seed.name)': \(error)")
            }
        }
        return merchantIds
    }

    // MARK: - Customers

    private struct CustomerSeed {
        let email, name: String
        let lat, lng: Double
        let balance, astraPoints: Int
        let favoriteIndices: [Int]       // indices into the merchantIds array returned above
    }

    private func seedCustomers(merchantIds: [String]) async {
        let seeds: [CustomerSeed] = [
            CustomerSeed(
                email: "customer1@astraling.test",
                name: "Erin Setiawan",
                lat: -6.2095, lng: 106.8462,
                balance: 250_000, astraPoints: 75,
                favoriteIndices: [0, 1]
            ),
            CustomerSeed(
                email: "customer2@astraling.test",
                name: "Budi Santoso",
                lat: -6.2115, lng: 106.8430,
                balance: 150_000, astraPoints: 30,
                favoriteIndices: [0]
            ),
            CustomerSeed(
                email: "customer3@astraling.test",
                name: "Dewi Rahayu",
                lat: -6.2060, lng: 106.8470,
                balance: 500_000, astraPoints: 200,
                favoriteIndices: [1]
            ),
            CustomerSeed(
                email: "customer4@astraling.test",
                name: "Ahmad Fauzi",
                lat: -6.2200, lng: 106.8400,
                balance: 75_000, astraPoints: 10,
                favoriteIndices: []
            )
        ]

        for (i, seed) in seeds.enumerated() {
            guard let uid = await getOrCreate(email: seed.email) else { continue }

            let geo = GeoPoint(latitude: seed.lat, longitude: seed.lng)
            let now = Timestamp(date: Date())
            let favorites = seed.favoriteIndices.compactMap {
                merchantIds.indices.contains($0) ? merchantIds[$0] : nil
            }

            let user = AppUser(role: .customer)
            let customer = Customer(
                name: seed.name,
                email: seed.email,
                balance: seed.balance,
                astraPoints: seed.astraPoints,
                location: geo,
                geohash: Geohash.encode(latitude: seed.lat, longitude: seed.lng),
                locationUpdatedAt: now,
                favorites: favorites
            )

            do {
                try db.collection("users").document(uid).setData(from: user)
                try db.collection("customers").document(uid).setData(from: customer)
                print("[Seeder] ✓ Customer \(i + 1): \(seed.name)  (\(seed.email))")
            } catch {
                print("[Seeder] ✗ Failed writing customer '\(seed.name)': \(error)")
            }
        }
    }

    // MARK: - Auth helper

    /// Creates a new Auth user, or signs in as the existing one if the email is already registered.
    /// Returns the uid on success, nil on failure.
    private func getOrCreate(email: String) async -> String? {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: MockDataSeeder.password)
            return result.user.uid
        } catch let error as NSError where error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: MockDataSeeder.password)
                return result.user.uid
            } catch {
                print("[Seeder] ✗ Sign-in failed for '\(email)': \(error)")
                return nil
            }
        } catch let error as NSError {
            // Print the full error so the underlying API response is visible.
            // "An internal error has occurred" (code 17999) almost always means
            // Email/Password sign-in is disabled in the Firebase Console.
            // Fix: Firebase Console → Authentication → Sign-in method → Email/Password → Enable
            print("[Seeder] ✗ createUser failed for '\(email)'")
            print("          code     : \(error.code)")
            print("          domain   : \(error.domain)")
            print("          message  : \(error.localizedDescription)")
            if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("          underlying: \(underlying)")
            }
            if let response = error.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] {
                print("          API response: \(response)")
            }
            return nil
        }
    }
}
