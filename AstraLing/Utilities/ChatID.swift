//
//  ChatID.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

enum ChatID {
    static func make(customerUid: String, merchantUid: String) -> String {
        "\(customerUid)_\(merchantUid)"
    }
}
