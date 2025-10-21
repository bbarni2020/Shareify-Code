import SwiftUI

extension Color {
    static var appBackground: Color { Color(hex: 0x0A0A0C) }
    static var appSurface: Color { Color(hex: 0x131316) }
    static var appSurfaceElevated: Color { Color(hex: 0x1A1A1E) }
    static var appSurfaceHover: Color { Color(hex: 0x1F1F24) }
    
    static var appAccent: Color { Color(hex: 0x1E293B) }
    static var appAccentHover: Color { Color(hex: 0x334155) }
    static var appAccentMuted: Color { Color(hex: 0x0F172A) }
    
    static var appTextPrimary: Color { Color(hex: 0xF5F5F7) }
    static var appTextSecondary: Color { Color(hex: 0x9CA3AF) }
    static var appTextTertiary: Color { Color(hex: 0x6B7280) }
    
    static var appBorder: Color { Color.white.opacity(0.08) }
    static var appBorderSubtle: Color { Color.white.opacity(0.04) }
    static var appDivider: Color { Color.white.opacity(0.06) }
    
    static var highlightGlow: Color { Color(hex: 0x8B5CF6).opacity(0.3) }
    static var appCodeBackground: Color { Color(hex: 0x0F0F12) }
    
    static var successColor: Color { Color(hex: 0x10B981) }
    static var warningColor: Color { Color(hex: 0xF59E0B) }
    static var errorColor: Color { Color(hex: 0xEF4444) }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
