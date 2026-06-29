//
//  RekapViewModel.swift
//  AstraLing
//
//  Created by Rasya Devan on 30/06/26.
//

import SwiftUI
import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

struct AreaStat: Identifiable {
    let id: String
    let name: String
    let count: Int
    let fraction: CGFloat
    let percent: String
}

@MainActor
final class RekapViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var pings: [Ping] = []
    @Published var areaStats: [AreaStat] = []
    @Published var periodDays: Int = 7

    private let db = Firestore.firestore()
    private var txnListener: ListenerRegistration?
    private var pingsListener: ListenerRegistration?
    private var geocodeCache: [String: String] = [:]
    private var areaComputeTask: Task<Void, Never>?

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        txnListener = db.collection("transactions")
            .whereField("merchantUid", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                self.transactions = snapshot?.documents.compactMap {
                    try? $0.data(as: Transaction.self)
                } ?? []
                self.scheduleAreaCompute()
            }
        pingsListener = db.collection("pings")
            .whereField("merchantUid", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                self.pings = snapshot?.documents.compactMap {
                    try? $0.data(as: Ping.self)
                } ?? []
                self.scheduleAreaCompute()
            }
    }

    func stopListening() {
        txnListener?.remove()
        pingsListener?.remove()
        txnListener = nil
        pingsListener = nil
    }

    func setPeriod(_ days: Int) {
        periodDays = days
        scheduleAreaCompute()
    }

    var busiestHourLabel: String {
        let payments = filteredPayments(days: periodDays)
        guard !payments.isEmpty else { return "Belum ada data" }
        let cal = Calendar.current
        let hours = payments.compactMap { $0.createdAt.map { cal.component(.hour, from: $0.dateValue()) } }
        guard !hours.isEmpty else { return "Belum ada data" }
        let counts = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
        guard let peak = counts.max(by: { $0.value < $1.value })?.key else { return "Belum ada data" }
        return String(format: "Pukul %02d.00 – %02d.00", peak, peak + 1)
    }

    var insightPrefix: String {
        let payments = filteredPayments(days: periodDays)
        guard !payments.isEmpty else { return "Belum ada data" }
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "id_ID")
        fmt.dateFormat = "EEEE"
        let weekdays = payments.compactMap { $0.createdAt.map { fmt.string(from: $0.dateValue()) } }
        let topDay = Dictionary(grouping: weekdays, by: { $0 }).mapValues(\.count)
            .max(by: { $0.value < $1.value })?.key ?? ""
        let hours = payments.compactMap { $0.createdAt.map { cal.component(.hour, from: $0.dateValue()) } }
        let peakHour = Dictionary(grouping: hours, by: { $0 }).mapValues(\.count)
            .max(by: { $0.value < $1.value })?.key ?? 0
        return "\(topDay.capitalized), jam \(String(format: "%02d.00", peakHour))"
    }

    var insightSuffix: String {
        let payments = filteredPayments(days: periodDays)
        guard !payments.isEmpty else { return " yang cukup untuk ditampilkan." }
        let areaName = areaStats.first?.name ?? "area sekitar"
        return " area \(areaName) sering ramai, pertimbangkan lewat sana."
    }

    var newCustomerCount: Int {
        let cal = Calendar.current
        let now = Date()
        let allPayments = transactions.filter { $0.type == .payment && $0.status == .success }
        let grouped = Dictionary(grouping: allPayments) { $0.customerUid ?? "" }
        return grouped.filter { uid, txns in
            guard !uid.isEmpty else { return false }
            guard let earliest = txns.compactMap({ $0.createdAt?.dateValue() }).min() else { return false }
            return cal.isDate(earliest, equalTo: now, toGranularity: .month)
        }.count
    }

    var loyalCustomerCount: Int {
        let cal = Calendar.current
        let now = Date()
        let allPayments = transactions.filter { $0.type == .payment && $0.status == .success }
        let grouped = Dictionary(grouping: allPayments) { $0.customerUid ?? "" }
        return grouped.filter { uid, txns in
            guard !uid.isEmpty else { return false }
            guard let earliest = txns.compactMap({ $0.createdAt?.dateValue() }).min() else { return false }
            return !cal.isDate(earliest, equalTo: now, toGranularity: .month)
        }.count
    }

    private func scheduleAreaCompute() {
        areaComputeTask?.cancel()
        areaComputeTask = Task {
            await computeAreaStats()
        }
    }

    private func computeAreaStats() async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -periodDays, to: Date()) ?? .distantPast
        let windowPings = pings.filter {
            ($0.createdAt?.dateValue() ?? .distantPast) >= cutoff
        }
        guard !windowPings.isEmpty else {
            areaStats = []
            return
        }

        var clusters: [String: [Ping]] = [:]
        for ping in windowPings {
            let prefix = Geohash.encode(
                latitude: ping.customerLocation.latitude,
                longitude: ping.customerLocation.longitude,
                length: 6
            )
            clusters[prefix, default: []].append(ping)
        }

        let top3 = clusters.sorted { $0.value.count > $1.value.count }.prefix(3)
        let total = top3.reduce(0) { $0 + $1.value.count }
        guard total > 0 else {
            areaStats = []
            return
        }

        var results: [AreaStat] = []
        for (prefix, group) in top3 {
            if Task.isCancelled { return }
            let name: String
            if let cached = geocodeCache[prefix] {
                name = cached
            } else {
                let lat = group.map { $0.customerLocation.latitude }.reduce(0, +) / Double(group.count)
                let lon = group.map { $0.customerLocation.longitude }.reduce(0, +) / Double(group.count)
                let loc = CLLocation(latitude: lat, longitude: lon)
                if let placemarks = try? await CLGeocoder().reverseGeocodeLocation(loc),
                   let placemark = placemarks.first {
                    name = placemark.subLocality ?? placemark.thoroughfare ?? placemark.locality ?? "Area sekitar"
                } else {
                    name = "Area sekitar"
                }
                geocodeCache[prefix] = name
            }
            let fraction = CGFloat(group.count) / CGFloat(total)
            let percent = "\(Int(fraction * 100))%"
            results.append(AreaStat(id: prefix, name: name, count: group.count, fraction: fraction, percent: percent))
        }

        if !Task.isCancelled {
            areaStats = results.sorted { $0.count > $1.count }
        }
    }

    private func filteredPayments(days: Int) -> [Transaction] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return transactions.filter {
            $0.type == .payment &&
            $0.status == .success &&
            ($0.createdAt?.dateValue() ?? .distantPast) >= cutoff
        }
    }
}
