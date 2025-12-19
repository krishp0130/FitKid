import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
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
                                    .font(AppTheme.Child.headlineFont)
                            }
                            .foregroundStyle(AppTheme.Child.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                    .fill(AppTheme.Child.cardBackground.opacity(0.4))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(AppTheme.Child.screenPadding)
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
                        colors: [AppTheme.Child.primary, AppTheme.Child.secondary],
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
                    .font(AppTheme.Child.titleFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                if let email = user.email {
                    Text(email)
                        .font(AppTheme.Child.bodyFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)
                }
            }

            ScoreBadge(score: creditScore)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }
}

struct StatsSection: View {
    let state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)

            VStack(spacing: 12) {
                StatRow(label: "Wallet Balance", value: state.walletBalanceFormatted, icon: "wallet.pass.fill")
                StatRow(label: "Credit Line", value: state.creditLineFormatted, icon: "creditcard.fill")
                StatRow(label: "Device Hours", value: state.deviceHours.formatted(), icon: "clock.fill")
            }
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
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
                .foregroundStyle(AppTheme.Child.accent)
                .frame(width: 30)

            Text(label)
                .font(AppTheme.Child.bodyFont)
                .foregroundStyle(AppTheme.Child.textSecondary)

            Spacer()

            Text(value)
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)
        }
    }
}

struct AchievementsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements 🏆")
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(icon: "star.fill", title: "First Chore", unlocked: true)
                    AchievementBadge(icon: "creditcard.fill", title: "First Card", unlocked: true)
                    AchievementBadge(icon: "crown.fill", title: "Elite Score", unlocked: false)
                    AchievementBadge(icon: "trophy.fill", title: "Millionaire", unlocked: false)
                }
            }
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
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
                .foregroundStyle(unlocked ? AppTheme.Child.accent : AppTheme.Child.textSecondary.opacity(0.3))

            Text(title)
                .font(AppTheme.Child.captionFont.weight(.semibold))
                .foregroundStyle(unlocked ? AppTheme.Child.textPrimary : AppTheme.Child.textSecondary.opacity(0.5))
        }
        .frame(width: 80, height: 80)
        .background(
            Circle()
                .fill(unlocked ? AppTheme.Child.cardBackground.opacity(0.6) : AppTheme.Child.cardBackground.opacity(0.2))
        )
    }
}

struct SettingsSection: View {
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)

            SettingsButton(icon: "bell.fill", title: "Notifications", action: {})
            SettingsButton(icon: "lock.fill", title: "Privacy", action: {})
            SettingsButton(icon: "questionmark.circle.fill", title: "Help & Support", action: {})
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
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
                    .foregroundStyle(AppTheme.Child.primary)
                    .frame(width: 30)

                Text(title)
                    .font(AppTheme.Child.bodyFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.Child.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
