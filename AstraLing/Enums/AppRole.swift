//
//  AppRole.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 19/06/26.
//

enum AppRole: String, Codable, CaseIterable {
    case customer = "customer"
    case merchant = "merchant"

    init?(normalizing raw: String) {
        self.init(rawValue: raw.lowercased())
    }
}
