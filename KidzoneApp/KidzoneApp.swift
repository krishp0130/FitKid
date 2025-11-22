import SwiftUI

@main
struct KidzoneApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .preferredColorScheme(colorSchemeMode)
        }
    }
    
    private var colorSchemeMode: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil // System
        }
    }
}
