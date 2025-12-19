import SwiftUI

// MARK: - Parent Portal Colors (Professional Fintech Aesthetic)
extension Color {
    // Parent Primary Colors - Deep, trustworthy, professional
    static let parentNavy = Color(red: 10/255, green: 25/255, blue: 41/255)           // #0A1929 - Deep navy
    static let parentDarkBlue = Color(red: 27/255, green: 42/255, blue: 65/255)      // #1B2A41 - Slate blue
    static let parentCharcoal = Color(red: 26/255, green: 29/255, blue: 35/255)      // #1A1D23 - Charcoal
    static let parentAccent = Color(red: 0/255, green: 102/255, blue: 255/255)       // #0066FF - Electric blue
    static let parentSuccess = Color(red: 16/255, green: 185/255, blue: 129/255)     // #10B981 - Emerald
    static let parentWarning = Color(red: 251/255, green: 191/255, blue: 36/255)     // #FBBF24 - Amber
    static let parentDanger = Color(red: 239/255, green: 68/255, blue: 68/255)       // #EF4444 - Red
    static let parentTextPrimary = Color.white
    static let parentTextSecondary = Color(red: 156/255, green: 163/255, blue: 175/255) // #9CA3AF - Gray
    static let parentCardBg = Color(red: 31/255, green: 41/255, blue: 55/255)        // #1F2937 - Card background
}

// MARK: - Child Portal Colors (Engaging, Educational, Age 7-13)
extension Color {
    // Child Primary Colors - Engaging but mature, trust-building
    static let childTeal = Color(red: 20/255, green: 184/255, blue: 166/255)         // #14B8A6 - Ocean teal
    static let childBlue = Color(red: 59/255, green: 130/255, blue: 246/255)         // #3B82F6 - Sky blue
    static let childGreen = Color(red: 34/255, green: 197/255, blue: 94/255)         // #22C55E - Growth green
    static let childYellow = Color(red: 252/255, green: 211/255, blue: 77/255)       // #FCD34D - Sunshine
    static let childPurple = Color(red: 139/255, green: 92/255, blue: 246/255)       // #8B5CF6 - Soft purple

    // Child Background Colors
    static let childDarkBlue = Color(red: 30/255, green: 41/255, blue: 59/255)       // #1E293B - Soft dark blue
    static let childDarkTeal = Color(red: 19/255, green: 78/255, blue: 74/255)       // #134E4A - Deep teal
    static let childCardBg = Color(red: 51/255, green: 65/255, blue: 85/255)         // #334155 - Card background

    // Child Status Colors
    static let childSuccess = Color(red: 74/255, green: 222/255, blue: 128/255)      // #4ADE80 - Bright green
    static let childWarning = Color(red: 251/255, green: 191/255, blue: 36/255)      // #FBBF24 - Amber
    static let childDanger = Color(red: 248/255, green: 113/255, blue: 113/255)      // #F87171 - Soft red

    // Child Text Colors
    static let childTextPrimary = Color.white
    static let childTextSecondary = Color(red: 203/255, green: 213/255, blue: 225/255) // #CBD5E1 - Light gray
}

// MARK: - Legacy Compatibility (Deprecated - will be removed)
extension Color {
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneBlue = Color.childBlue
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzonePurple = Color.childPurple
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzonePink = Color(red: 1.0, green: 0.40, blue: 0.70)
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneGreen = Color.childGreen
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneOrange = Color(red: 1.0, green: 0.60, blue: 0.20)
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneYellow = Color.childYellow
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneDark = Color.parentNavy
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneDarkBlue = Color.parentDarkBlue
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneSuccess = Color.childSuccess
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneWarning = Color.childWarning
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let kidzoneDanger = Color.childDanger
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let nightBlue = Color.parentNavy
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let spacePurple = Color(red: 66/255, green: 44/255, blue: 101/255)
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let sunrise = Color(red: 255/255, green: 131/255, blue: 96/255)
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let emerald = Color.parentSuccess
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let skyBlue = Color.childBlue
    @available(*, deprecated, message: "Use parent/child specific colors instead")
    static let amber = Color.parentWarning
}

// MARK: - Theme Configuration
struct AppTheme {
    // MARK: - Parent Theme (Professional Fintech)
    struct Parent {
        // Gradients - Subtle and professional
        static let backgroundGradient = LinearGradient(
            colors: [Color.parentNavy, Color.parentDarkBlue, Color.parentCharcoal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardGradient = LinearGradient(
            colors: [Color.parentCardBg.opacity(0.8), Color.parentCardBg.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accentGradient = LinearGradient(
            colors: [Color.parentAccent, Color.parentAccent.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Typography - Professional, clean
        static let titleFont = Font.system(.largeTitle, design: .default).weight(.bold)
        static let headlineFont = Font.system(.headline, design: .default).weight(.semibold)
        static let bodyFont = Font.system(.body, design: .default)
        static let captionFont = Font.system(.caption, design: .default).weight(.medium)

        // Colors
        static let primary = Color.parentAccent
        static let success = Color.parentSuccess
        static let warning = Color.parentWarning
        static let danger = Color.parentDanger
        static let textPrimary = Color.parentTextPrimary
        static let textSecondary = Color.parentTextSecondary
        static let cardBackground = Color.parentCardBg

        // Spacing
        static let cardPadding: CGFloat = 20
        static let screenPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Child Theme (Engaging & Educational)
    struct Child {
        // Gradients - Vibrant but mature
        static let backgroundGradient = LinearGradient(
            colors: [Color.childDarkBlue, Color.childDarkTeal, Color.childDarkBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardGradient = LinearGradient(
            colors: [Color.childCardBg.opacity(0.6), Color.childCardBg.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let primaryGradient = LinearGradient(
            colors: [Color.childTeal, Color.childBlue],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let successGradient = LinearGradient(
            colors: [Color.childGreen, Color.childTeal],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Typography - Friendly but not childish
        static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let headlineFont = Font.system(.headline, design: .rounded).weight(.bold)
        static let bodyFont = Font.system(.body, design: .rounded)
        static let captionFont = Font.system(.caption, design: .rounded)

        // Colors
        static let primary = Color.childTeal
        static let secondary = Color.childBlue
        static let accent = Color.childYellow
        static let success = Color.childSuccess
        static let warning = Color.childWarning
        static let danger = Color.childDanger
        static let textPrimary = Color.childTextPrimary
        static let textSecondary = Color.childTextSecondary
        static let cardBackground = Color.childCardBg

        // Spacing
        static let cardPadding: CGFloat = 20
        static let screenPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 20
    }

    // MARK: - Legacy Support (Deprecated)
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child instead")
    static let primaryGradient = LinearGradient(
        colors: [Color.childBlue, Color.childPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @available(*, deprecated, message: "Use AppTheme.Child.backgroundGradient instead")
    static let childGradient = LinearGradient(
        colors: [Color.childTeal, Color.childBlue, Color.childPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @available(*, deprecated, message: "Use AppTheme.Parent.backgroundGradient instead")
    static let parentGradient = LinearGradient(
        colors: [Color.parentNavy, Color.parentDarkBlue, Color.parentCharcoal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child typography instead")
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child typography instead")
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.bold)
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child typography instead")
    static let bodyFont = Font.system(.body, design: .rounded)
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child typography instead")
    static let captionFont = Font.system(.caption, design: .rounded)

    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child spacing instead")
    static let cardPadding: CGFloat = 20
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child spacing instead")
    static let screenPadding: CGFloat = 20
    @available(*, deprecated, message: "Use AppTheme.Parent or AppTheme.Child spacing instead")
    static let cardSpacing: CGFloat = 16
}

