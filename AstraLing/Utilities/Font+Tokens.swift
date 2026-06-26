//
//  Font+Tokens.swift
//  AstraLing
//
//  Created by Rasya Devan on 26/06/26.
//

import SwiftUI

extension Font {
    enum Size: CGFloat {
        case s12 = 12, s14 = 14, s16 = 16, s18 = 18, s20 = 20, s22 = 22,
             s24 = 24, s26 = 26, s28 = 28, s30 = 30, s32 = 32, s34 = 34,
             s36 = 36, s40 = 40
    }

    static func app(_ size: Size, weight: Font.Weight = .regular) -> Font {
        .system(size: size.rawValue, weight: weight)
    }
}
