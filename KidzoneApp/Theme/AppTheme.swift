import SwiftUI

// MARK: - Blue/Green Color Palette with Glass Morphism
extension Color {
    // Primary colors - Blue/Green theme
    static let primaryBlue = Color(red: 0.20, green: 0.60, blue: 1.0)
    static let primaryGreen = Color(red: 0.20, green: 0.85, blue: 0.50)
    static let accentBlue = Color(red: 0.30, green: 0.70, blue: 1.0)
    static let accentGreen = Color(red: 0.25, green: 0.90, blue: 0.55)
    
    // Light mode colors
    static let lightBackground = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let lightCard = Color.white
    
    // Dark mode colors
    static let darkBackground = Color(red: 0.08, green: 0.12, blue: 0.20)
    static let darkCard = Color(red: 0.12, green: 0.18, blue: 0.28)
    
    // Glass morphism overlay
    static let glassOverlay = Color.white.opacity(0.1)
    static let glassOverlayDark = Color.black.opacity(0.2)
    
    // Status colors
    static let success = Color(red: 0.20, green: 0.85, blue: 0.40)
    static let warning = Color(red: 1.0, green: 0.70, blue: 0.20)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)
    static let info = Color(red: 0.30, green: 0.70, blue: 1.0)
    
    // Legacy compatibility
    static let kidzoneBlue = primaryBlue
    static let kidzoneGreen = primaryGreen
    static let kidzoneYellow = Color(red: 1.0, green: 0.85, blue: 0.20)
    static let kidzonePink = Color(red: 1.0, green: 0.40, blue: 0.70)
    static let kidzoneOrange = Color(red: 1.0, green: 0.60, blue: 0.20)
    static let kidzoneSuccess = success
    static let kidzoneWarning = warning
    static let kidzoneDanger = danger
}

// MARK: - Theme Configuration
struct AppTheme {
    // Blue/Green gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryBlue, Color.primaryGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var childGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryBlue, Color.accentBlue, Color.primaryGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var parentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryBlue.opacity(0.8), Color.primaryGreen.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Glass morphism effect
    static func glassBackground(isDark: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isDark ? Color.glassOverlayDark : Color.glassOverlay)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // Typography
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.bold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    
    // Spacing
    static let cardPadding: CGFloat = 20
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 16
}
