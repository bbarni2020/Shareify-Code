//
//  GlassCompatibility.swift
//  Shareify Code
//


import SwiftUI

struct GlassButtonStyleIfAvailable: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if swift(>=6.0)
        if #available(iOS 18.0, macOS 15.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.borderless)
        }
        #else
        content.buttonStyle(.borderless)
        #endif
    }
}

struct GlassLikeBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            content.background(.ultraThinMaterial)
        } else {
            content.background(Color.appUnderPageBackground)
        }
    }
}

extension View {
    func glassButtonStyleIfAvailable() -> some View {
        modifier(GlassButtonStyleIfAvailable())
    }

    func glassLikeBackground() -> some View {
        modifier(GlassLikeBackground())
    }
}
