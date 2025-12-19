import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser {
                    MainTabView(user: user)
                } else {
                    RoleSelectionView()
                }
            } else if authManager.onboardingRequired {
                OnboardingView()
            } else {
                WelcomeView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.onboardingRequired)
    }
}
