//
//  Color+Tokens.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

extension Color {
    enum Token {
        static let accent      = Color(hex: "#EEE809")

        static let black       = Color(hex: "#1A1A1A")
        static let white       = Color(hex: "#FCFCFC")
        static let darkGrey    = Color(hex: "#757575")
        static let systemGrey  = Color(hex: "#8E8E93")
        static let medGrey     = Color(hex: "#C7C7C7")
        static let lightGrey   = Color(hex: "#F0F0F0")

        static let greenLight  = Color(hex: "#E7F6EF")
        static let greenDark   = Color(hex: "#127A4B")
        static let redLight    = Color(hex: "#FFF0F0")
        static let redDark     = Color(hex: "#D90000")

        static let dataYellow  = Color(hex: "#FFC370")
        static let dataPink    = Color(hex: "#EA85A3")
        static let dataPurple  = Color(hex: "#8A6EAF")
        static let dataTeal    = Color(hex: "#44A5C2")

        static let blue25      = Color(hex: "#F6FBFF")
        static let blue50      = Color(hex: "#EDF6FF")
        static let blue100     = Color(hex: "#D6E9FF")
        static let blue300     = Color(hex: "#83C2FF")
        static let blue500     = Color(hex: "#1E7CFF")
        static let blue600     = Color(hex: "#065EFF")
        static let blue700     = Color(hex: "#0045E5")

        static let shadowBlueGrey   = Color(hex: "#D0D6E2")
        static let gradBlueTop      = Color(hex: "#4078F0")
        static let gradBlueBottom   = Color(hex: "#2E59CC")
        static let navActive        = Color(hex: "#708FD6")
        static let headerName       = Color(hex: "#B3CCF2")
        static let headerTagline    = Color(hex: "#BACCF2")
        static let headerLink       = Color(hex: "#9CB8EB")
        static let promoTitle       = Color(hex: "#F7BF99")
        static let promoSubtitle    = Color(hex: "#F5AB7A")
        static let promoButtonText  = Color(hex: "#F0AB7A")
        static let promoButtonBg    = Color(hex: "#FCF2EB")
        static let promoButtonBorder = Color(hex: "#FADEC2")
        static let promoGradStart   = Color(hex: "#FA8C40")
        static let promoGradEnd     = Color(hex: "#F77326")
        static let pointsBadge      = Color(hex: "#872EFF")
    }
}

extension Color {
    static let appPrimary        = Token.blue700
    static let appPrimaryPressed = Token.blue600
    static let appAccent         = Token.accent
    static let appTint           = Token.blue500

    static let appBackground     = Token.white
    static let appSurface        = Token.white
    static let appSurfaceMuted   = Token.lightGrey
    static let appSurfaceBlue    = Token.blue50

    static let appTextPrimary    = Token.black
    static let appTextSecondary  = Token.darkGrey
    static let appTextTertiary   = Token.systemGrey
    static let appTextOnPrimary  = Token.white

    static let appBorder         = Token.medGrey
    static let appDivider        = Token.lightGrey

    static let appSuccess        = Token.greenDark
    static let appSuccessBg      = Token.greenLight
    static let appError          = Token.redDark
    static let appErrorBg        = Token.redLight
}
