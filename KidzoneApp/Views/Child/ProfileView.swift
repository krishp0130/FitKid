import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        if let user = authManager.currentUser {
                            ProfileHeader(user: user, creditScore: appState.state.creditScore)
                        }
                        
                        // Stats Section
                        StatsSection(state: appState.state)
                        
                        // Achievements
                        AchievementsSection()
                        
                        // Settings
                        SettingsSection(showSettings: $showSettings)
                        
                        // Logout
                        Button(action: {
                            authManager.signOut()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                            }
                            .foregroundStyle(Color.kidzoneDanger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileHeader: View {
    let user: User
    let creditScore: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.kidzoneBlue, Color.kidzonePink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(user.username.prefix(1).uppercased())
                        .font(.system(size: 48, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                )
            
            VStack(spacing: 4) {
                Text(user.username)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                if let email = user.email {
                    Text(email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            ScoreBadge(score: creditScore)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.1))
        )
    }
}

struct StatsSection: View {
    let state: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
                StatRow(label: "Wallet Balance", value: state.walletBalanceFormatted, icon: "wallet.pass.fill")
                StatRow(label: "Credit Line", value: state.creditLineFormatted, icon: "creditcard.fill")
                StatRow(label: "Device Hours", value: state.deviceHours.formatted(), icon: "clock.fill")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.kidzoneYellow)
                .frame(width: 30)
            
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct AchievementsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements 🏆")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(icon: "star.fill", title: "First Chore", unlocked: true)
                    AchievementBadge(icon: "creditcard.fill", title: "First Card", unlocked: true)
                    AchievementBadge(icon: "crown.fill", title: "Elite Score", unlocked: false)
                    AchievementBadge(icon: "trophy.fill", title: "Millionaire", unlocked: false)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let unlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(unlocked ? Color.kidzoneYellow : .white.opacity(0.3))
            
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(unlocked ? .white : .white.opacity(0.5))
        }
        .frame(width: 80, height: 80)
        .background(
            Circle()
                .fill(unlocked ? .white.opacity(0.15) : .white.opacity(0.05))
        )
    }
}

struct SettingsSection: View {
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            SettingsButton(icon: "bell.fill", title: "Notifications", action: {})
            SettingsButton(icon: "lock.fill", title: "Privacy", action: {})
            SettingsButton(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.kidzoneBlue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

