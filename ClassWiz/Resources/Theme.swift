// Theme.swift
// ClassWiz - Design System
//
// Centralized design tokens for colors, typography, spacing, and styles.

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Brand
    static let cwPrimary      = Color("CWPrimary",      bundle: nil)
    static let cwSecondary    = Color("CWSecondary",    bundle: nil)
    static let cwAccent       = Color("CWAccent",       bundle: nil)

    // Surfaces
    static let cwBackground   = Color("CWBackground",   bundle: nil)
    static let cwSurface      = Color("CWSurface",      bundle: nil)
    static let cwSurfaceSecondary = Color("CWSurfaceSecondary", bundle: nil)

    // Text
    static let cwTextPrimary   = Color("CWTextPrimary",   bundle: nil)
    static let cwTextSecondary = Color("CWTextSecondary", bundle: nil)

    // Risk / Status
    static let cwSafe     = Color(red: 0.20, green: 0.78, blue: 0.35)   // ≥80 %
    static let cwWarning  = Color(red: 1.00, green: 0.76, blue: 0.03)   // 75–79 %
    static let cwCritical = Color(red: 0.94, green: 0.27, blue: 0.27)   // <75 %

    // Utility
    static let cwDivider  = Color.gray.opacity(0.18)

    // Fallback adaptive colors (used if asset catalog colors aren't configured)
    static let cwPrimaryFallback = Color(light: Color(hex: "4F46E5"), dark: Color(hex: "818CF8"))
    static let cwSecondaryFallback = Color(light: Color(hex: "7C3AED"), dark: Color(hex: "A78BFA"))
    static let cwAccentFallback = Color(light: Color(hex: "2563EB"), dark: Color(hex: "60A5FA"))
    static let cwBackgroundFallback = Color(light: Color(hex: "F8FAFC"), dark: Color(hex: "0F172A"))
    static let cwSurfaceFallback = Color(light: .white, dark: Color(hex: "1E293B"))
    static let cwSurfaceSecondaryFallback = Color(light: Color(hex: "F1F5F9"), dark: Color(hex: "334155"))
    static let cwTextPrimaryFallback = Color(light: Color(hex: "0F172A"), dark: Color(hex: "F8FAFC"))
    static let cwTextSecondaryFallback = Color(light: Color(hex: "64748B"), dark: Color(hex: "94A3B8"))
}

// MARK: - Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(dark)
            : UIColor(light)
        })
    }
}

// MARK: - App Theme (centralized tokens)

enum AppTheme {
    // MARK: Colors (use fallback adaptive colors)
    static let primary           = Color.cwPrimaryFallback
    static let secondary         = Color.cwSecondaryFallback
    static let accent            = Color.cwAccentFallback
    static let background        = Color.cwBackgroundFallback
    static let surface           = Color.cwSurfaceFallback
    static let surfaceSecondary  = Color.cwSurfaceSecondaryFallback
    static let textPrimary       = Color.cwTextPrimaryFallback
    static let textSecondary     = Color.cwTextSecondaryFallback
    static let safe              = Color.cwSafe
    static let warning           = Color.cwWarning
    static let critical          = Color.cwCritical
    static let divider           = Color.cwDivider

    // MARK: Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [background, surface],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [surface, surfaceSecondary.opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48
    
    // MARK: Corner Radius
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24
    static let cornerRadiusFull: CGFloat = 100

    // MARK: Shadows
    static func cardShadow() -> some View {
        Color.black.opacity(0.06)
    }

    // MARK: Animation
    static let defaultAnimation: Animation = .spring(response: 0.38, dampingFraction: 0.78)
    static let quickAnimation: Animation   = .spring(response: 0.24, dampingFraction: 0.86)
    static let bouncyAnimation: Animation  = .spring(response: 0.45, dampingFraction: 0.65)
}

// MARK: - Custom Button Styles

struct CWPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView().tint(.white).scaleEffect(0.85)
            }
            configuration.label
                .opacity(isLoading ? 0.7 : 1)
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                    .fill(AppTheme.primaryGradient)
                // inner highlight
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
            }
        )
        .shadow(color: AppTheme.primary.opacity(configuration.isPressed ? 0.15 : 0.35), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 5)
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(AppTheme.quickAnimation, value: configuration.isPressed)
    }
}

struct CWSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                    .fill(AppTheme.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                            .stroke(AppTheme.primary.opacity(0.4), lineWidth: 1.5)
                    )
            )
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.quickAnimation, value: configuration.isPressed)
    }
}

// MARK: - Card Modifier

struct CWCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.spacingLG)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLG)
                    .fill(AppTheme.surface)
                    .shadow(color: AppTheme.primary.opacity(0.08), radius: 15, x: 0, y: 8)
            )
    }
}

extension View {
    func cwCard() -> some View {
        modifier(CWCardModifier())
    }

    func cwSectionHeader() -> some View {
        self
            .font(.title3.weight(.semibold))
            .foregroundColor(AppTheme.textPrimary)
    }
}
