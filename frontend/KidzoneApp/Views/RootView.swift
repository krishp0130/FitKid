import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.onboardingRequired {
                // Show onboarding first if required
                OnboardingView()
            } else if authManager.isAuthenticated {
                // User is authenticated
                if let user = authManager.currentUser {
                    MainTabView(user: user)
                } else {
                    // Authenticated but no user - shouldn't happen, but show welcome
                    WelcomeView()
                }
            } else {
                // Not authenticated - show welcome/login
                WelcomeView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.onboardingRequired)
    }
}
