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
        content
            .background(Color.appSurfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

struct GlassBarBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
    }
}

extension View {
    func glassButtonStyleIfAvailable() -> some View {
        modifier(GlassButtonStyleIfAvailable())
    }

    func glassLikeBackground() -> some View {
        modifier(GlassLikeBackground())
    }

    func glassBarBackground() -> some View {
        modifier(GlassBarBackground())
    }

    func glow(_ color: Color = .appAccent, radius: CGFloat = 12, opacity: Double = 0.4) -> some View {
        shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}
