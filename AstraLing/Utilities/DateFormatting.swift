//
//  DateFormatting.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import Foundation

extension Date {
    var dayLabelID: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, dd MMMM yyyy"
        f.locale = Locale(identifier: "id_ID")
        return f.string(from: self)
    }

    var timeLabelID: String {
        let f = DateFormatter()
        f.dateFormat = "HH.mm"
        return f.string(from: self)
    }
}
