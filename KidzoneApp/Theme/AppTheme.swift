import SwiftUI

// MARK: - Kid-Friendly Color Palette (Ages 7-13)
extension Color {
    // Primary colors - bright and energetic
    static let kidzoneBlue = Color(red: 0.20, green: 0.60, blue: 1.0)
    static let kidzonePurple = Color(red: 0.65, green: 0.30, blue: 1.0)
    static let kidzonePink = Color(red: 1.0, green: 0.40, blue: 0.70)
    
    // Accent colors - fun and playful
    static let kidzoneGreen = Color(red: 0.20, green: 0.90, blue: 0.50)
    static let kidzoneOrange = Color(red: 1.0, green: 0.60, blue: 0.20)
    static let kidzoneYellow = Color(red: 1.0, green: 0.85, blue: 0.20)
    
    // Background colors
    static let kidzoneDark = Color(red: 0.10, green: 0.12, blue: 0.20)
    static let kidzoneDarkBlue = Color(red: 0.15, green: 0.18, blue: 0.28)
    
    // Status colors
    static let kidzoneSuccess = Color(red: 0.20, green: 0.85, blue: 0.40)
    static let kidzoneWarning = Color(red: 1.0, green: 0.70, blue: 0.20)
    static let kidzoneDanger = Color(red: 1.0, green: 0.35, blue: 0.35)
    
    // Legacy colors (for compatibility)
    static let nightBlue = Color(red: 16/255, green: 28/255, blue: 54/255)
    static let spacePurple = Color(red: 66/255, green: 44/255, blue: 101/255)
    static let sunrise = Color(red: 255/255, green: 131/255, blue: 96/255)
    static let emerald = Color(red: 54/255, green: 193/255, blue: 149/255)
    static let skyBlue = Color(red: 89/255, green: 196/255, blue: 255/255)
    static let amber = Color(red: 255/255, green: 199/255, blue: 94/255)
}

// MARK: - Theme Configuration
struct AppTheme {
    static let primaryGradient = LinearGradient(
        colors: [Color.kidzoneBlue, Color.kidzonePurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let childGradient = LinearGradient(
        colors: [Color.kidzoneBlue, Color.kidzonePink, Color.kidzonePurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let parentGradient = LinearGradient(
        colors: [Color.kidzoneDarkBlue, .spacePurple, .nightBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
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

