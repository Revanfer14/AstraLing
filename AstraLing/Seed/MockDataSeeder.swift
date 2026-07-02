//
//  MockDataSeeder.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MockDataSeeder {

    static let password = "Astra123!"

    private let db = Firestore.firestore()

    private struct SeededAccount {
        let uid: String
        let name: String
    }

    func seedAll() async {
        print("""

        [Seeder] ══════════════════════════════════════
        [Seeder]   AstraLing — Seeding mock accounts
        [Seeder]   Password (all accounts): \(MockDataSeeder.password)
        [Seeder] ══════════════════════════════════════
        """)

        let merchants = await seedMerchants()
        let customers = await seedCustomers(merchantIds: merchants.map { $0.uid })
        await seedPings(customers: customers, merchants: merchants)
        await seedChats(customers: customers, merchants: merchants)
        await seedTransactions(customers: customers, merchants: merchants)

        try? Auth.auth().signOut()

        print("""

        [Seeder] ══════════════════════════════════════
        [Seeder]   Done! Sign in with any account above.
        [Seeder]   Password: \(MockDataSeeder.password)
        [Seeder] ══════════════════════════════════════
        """)
    }

    private struct MerchantSeed {
        let email, name, category, description: String
        let lat, lng: Double
        let balance, astraPoints: Int
        let menu: [(name: String, price: Int, category: MenuCategory)]
    }

    private func seedMerchants() async -> [SeededAccount] {
        let seeds: [MerchantSeed] = [
            MerchantSeed(
                email: "merchant1@astraling.test",
                name: "Warung Bakso Pak Haji",
                category: "bakso",
                description: "Bakso segar dibuat tiap hari, kuah gurih khas Malang.",
                lat: -6.2088, lng: 106.8456,
                balance: 2_500_000, astraPoints: 150,
                menu: [
                    ("Bakso Biasa", 15_000, .makanan),
                    ("Bakso Urat", 18_000, .makanan),
                    ("Bakso Malang Komplit", 22_000, .makanan),
                    ("Es Teh Manis", 5_000, .minuman)
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
                    ("Manis Coklat", 35_000, .makanan),
                    ("Manis Keju", 35_000, .makanan),
                    ("Manis Coklat Keju", 40_000, .makanan),
                    ("Telur Kornet", 40_000, .makanan)
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
                    ("Batagor Kuah", 12_000, .makanan),
                    ("Batagor Kering", 12_000, .makanan),
                    ("Cimol Original", 8_000, .camilan),
                    ("Cimol Pedas", 8_000, .camilan)
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
                    ("Cilok Original", 5_000, .camilan),
                    ("Cilok Isi Telur", 7_000, .camilan),
                    ("Cilok Jumbo", 10_000, .camilan)
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
                    ("Soto Betawi Biasa", 25_000, .makanan),
                    ("Soto Betawi Spesial", 32_000, .paket),
                    ("Es Jeruk", 7_000, .minuman),
                    ("Kerupuk", 3_000, .camilan)
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
                    ("Cakwe Polos", 5_000, .camilan),
                    ("Cakwe Isi Udang", 8_000, .camilan),
                    ("Odading", 6_000, .camilan),
                    ("Kopi Susu", 10_000, .minuman)
                ]
            )
        ]

        var merchantAccounts: [SeededAccount] = []
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
                qrPayload: "astraling://pay/\(uid)"
            )

            do {
                try db.collection("users").document(uid).setData(from: user)
                try db.collection("merchants").document(uid).setData(from: merchant)

                let presence: [String: Any] = [
                    "merchantUid": uid,
                    "name": seed.name,
                    "category": seed.category,
                    "isVisible": true,
                    "location": geo,
                    "geohash": Geohash.encode(latitude: seed.lat, longitude: seed.lng),
                    "locationUpdatedAt": now
                ]
                try await db.collection("merchants").document(uid)
                    .collection("presence").document("live")
                    .setData(presence)

                let menuRef = db.collection("merchants").document(uid).collection("menu")
                for (order, item) in seed.menu.enumerated() {
                    let menuItem = MenuItem(name: item.name, price: item.price, order: order, category: item.category)
                    _ = try menuRef.addDocument(from: menuItem)
                }

                merchantAccounts.append(SeededAccount(uid: uid, name: seed.name))
                print("[Seeder] ✓ Merchant \(i + 1): \(seed.name)  (\(seed.email))")
            } catch {
                print("[Seeder] ✗ Failed writing merchant '\(seed.name)': \(error)")
            }
        }
        return merchantAccounts
    }

    private struct CustomerSeed {
        let email, name: String
        let lat, lng: Double
        let balance, astraPoints: Int
        let favoriteIndices: [Int]
    }

    private func seedCustomers(merchantIds: [String]) async -> [SeededAccount] {
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

        var customerAccounts: [SeededAccount] = []
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
                customerAccounts.append(SeededAccount(uid: uid, name: seed.name))
                print("[Seeder] ✓ Customer \(i + 1): \(seed.name)  (\(seed.email))")
            } catch {
                print("[Seeder] ✗ Failed writing customer '\(seed.name)': \(error)")
            }
        }
        return customerAccounts
    }

    private func seedPings(customers: [SeededAccount], merchants: [SeededAccount]) async {
        guard customers.count >= 3, merchants.count >= 2 else { return }
        let now = Date()

        let pings: [Ping] = [
            Ping(
                customerUid: customers[0].uid,
                merchantUid: merchants[0].uid,
                customerName: customers[0].name,
                customerLocation: GeoPoint(latitude: -6.2097, longitude: 106.8458),
                interestedItems: ["Bakso Urat", "Bakso Malang Komplit"],
                note: "Tolong jangan terlalu pedas ya",
                status: .active,
                updatedAt: Timestamp(date: now)
            ),
            Ping(
                customerUid: customers[1].uid,
                merchantUid: merchants[0].uid,
                customerName: customers[1].name,
                customerLocation: GeoPoint(latitude: -6.2120, longitude: 106.8435),
                interestedItems: ["Bakso Biasa"],
                status: .onTheWay,
                updatedAt: Timestamp(date: now)
            ),
            Ping(
                customerUid: customers[2].uid,
                merchantUid: merchants[1].uid,
                customerName: customers[2].name,
                customerLocation: GeoPoint(latitude: -6.2065, longitude: 106.8472),
                interestedItems: ["Manis Coklat Keju", "Telur Kornet"],
                note: "Minta tidak terlalu manis",
                status: .active,
                updatedAt: Timestamp(date: now)
            )
        ]

        for ping in pings {
            do {
                _ = try db.collection("pings").addDocument(from: ping)
                let merchantName = merchants.first(where: { $0.uid == ping.merchantUid })?.name ?? ping.merchantUid
                print("[Seeder] ✓ Ping: \(ping.customerName) → \(merchantName) (\(ping.status.rawValue))")
            } catch {
                print("[Seeder] ✗ Failed writing ping: \(error)")
            }
        }
    }

    private func seedChats(customers: [SeededAccount], merchants: [SeededAccount]) async {
        guard customers.count >= 2, merchants.count >= 2 else { return }
        let now = Date()

        struct ChatSeed {
            let customer: SeededAccount
            let merchant: SeededAccount
            let messages: [(text: String, role: SenderRole)]
        }

        let chatSeeds: [ChatSeed] = [
            ChatSeed(
                customer: customers[0],
                merchant: merchants[0],
                messages: [
                    ("Halo, saya lagi di sekitar sini, bisa kesini?", .customer),
                    ("Siap! Saya sedang jalan ke arah sana, 5 menit lagi", .merchant),
                    ("Oke, saya tunggu di depan minimarket ya", .customer),
                    ("Sudah dekat, sebentar lagi!", .merchant)
                ]
            ),
            ChatSeed(
                customer: customers[1],
                merchant: merchants[1],
                messages: [
                    ("Masih ada Martabak Manis Coklat Keju?", .customer),
                    ("Ada! Mau pesan berapa kotak?", .merchant),
                    ("1 kotak saja, saya OTW", .customer)
                ]
            )
        ]

        for seed in chatSeeds {
            let chatId = "\(seed.customer.uid)_\(seed.merchant.uid)"
            let lastMsg = seed.messages[seed.messages.count - 1]
            let lastMsgAt = Timestamp(date: now)

            let chat = Chat(
                customerUid: seed.customer.uid,
                merchantUid: seed.merchant.uid,
                participantUids: [seed.customer.uid, seed.merchant.uid],
                customerName: seed.customer.name,
                merchantName: seed.merchant.name,
                lastMessage: lastMsg.text,
                lastMessageAt: lastMsgAt
            )

            do {
                try db.collection("chats").document(chatId).setData(from: chat)

                let messagesRef = db.collection("chats").document(chatId).collection("messages")
                let total = seed.messages.count
                for (i, msg) in seed.messages.enumerated() {
                    let senderUid = msg.role == .customer ? seed.customer.uid : seed.merchant.uid
                    let offset = Double(i - total) * 60.0
                    let msgTimestamp = Timestamp(date: Date(timeIntervalSinceNow: offset))
                    let chatMessage = ChatMessage(
                        senderUid: senderUid,
                        senderRole: msg.role,
                        text: msg.text,
                        createdAt: msgTimestamp
                    )
                    _ = try messagesRef.addDocument(from: chatMessage)
                }

                print("[Seeder] ✓ Chat: \(seed.customer.name) ↔ \(seed.merchant.name) (\(total) pesan)")
            } catch {
                print("[Seeder] ✗ Failed writing chat '\(chatId)': \(error)")
            }
        }
    }

    private func seedTransactions(customers: [SeededAccount], merchants: [SeededAccount]) async {
        guard customers.count >= 3, merchants.count >= 2 else { return }
        let now = Date()
        let calendar = Calendar.current

        func hoursAgo(_ h: Int) -> Timestamp {
            Timestamp(date: calendar.date(byAdding: .hour, value: -h, to: now) ?? now)
        }

        let txns: [(txn: Transaction, label: String)] = [
            (
                Transaction(
                    type: .payment,
                    displayId: "#QR260624-0001",
                    customerUid: customers[0].uid,
                    merchantUid: merchants[0].uid,
                    customerName: customers[0].name,
                    amount: 22_000,
                    method: "QRIS AstraPay",
                    status: .success,
                    createdAt: hoursAgo(3)
                ),
                "\(customers[0].name) → \(merchants[0].name)"
            ),
            (
                Transaction(
                    type: .payment,
                    displayId: "#QR260624-0002",
                    customerUid: customers[1].uid,
                    merchantUid: merchants[0].uid,
                    customerName: customers[1].name,
                    amount: 15_000,
                    method: "QRIS AstraPay",
                    status: .success,
                    createdAt: hoursAgo(2)
                ),
                "\(customers[1].name) → \(merchants[0].name)"
            ),
            (
                Transaction(
                    type: .payment,
                    displayId: "#QR260624-0003",
                    customerUid: customers[2].uid,
                    merchantUid: merchants[1].uid,
                    customerName: customers[2].name,
                    amount: 40_000,
                    method: "QRIS AstraPay",
                    status: .success,
                    createdAt: hoursAgo(1)
                ),
                "\(customers[2].name) → \(merchants[1].name)"
            ),
            (
                Transaction(
                    type: .transfer,
                    displayId: "#TF260624-0001",
                    merchantUid: merchants[0].uid,
                    amount: 500_000,
                    method: "Transfer Bank",
                    status: .success,
                    createdAt: hoursAgo(0)
                ),
                "Transfer saldo \(merchants[0].name)"
            )
        ]

        for (txn, label) in txns {
            do {
                _ = try db.collection("transactions").addDocument(from: txn)
                print("[Seeder] ✓ Transaksi: \(label) — \(txn.displayId)")
            } catch {
                print("[Seeder] ✗ Failed writing transaksi '\(txn.displayId)': \(error)")
            }
        }
    }

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
