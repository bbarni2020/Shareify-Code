//
//  PlatformColors.swift
//  Shareify Code
//


import SwiftUI

extension Color {
    // App primary accent: #1E293B
    static var appAccent: Color { Color(red: 0x1E/255.0, green: 0x29/255.0, blue: 0x3B/255.0) }

    static var appWindowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }

    static var appUnderPageBackground: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    static var appControlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    static var appTextBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
}
