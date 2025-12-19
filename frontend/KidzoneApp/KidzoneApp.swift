import SwiftUI

@main
struct KidzoneApp: App {
    // Google iOS client ID
    private let googleClientID = "816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel.apps.googleusercontent.com"
    @StateObject private var authManager = AuthenticationManager(
        googleClientID: "816594540066-8a0ee3cei8rcgp4ch4980mp2fb29itel.apps.googleusercontent.com"
    )
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
        }
    }
}
