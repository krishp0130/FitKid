import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser {
                    if user.role == .none {
                        // User logged in but hasn't selected role yet
                        RoleSelectionView()
                    } else {
                        MainTabView(user: user)
                    }
                } else {
                    RoleSelectionView()
                }
            } else {
                WelcomeView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authManager.isAuthenticated)
    }
}
