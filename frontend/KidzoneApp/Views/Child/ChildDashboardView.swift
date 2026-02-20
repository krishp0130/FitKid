import SwiftUI

struct ChildDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    /// When set, quick action buttons switch to this tab index (e.g. from MainTabView). Chores=1, Cards=2, Shop=3.
    var onSelectTab: ((Int) -> Void)? = nil

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Credit Score Card (Large & Prominent)
                        creditScoreCard

                        // Wallet Balance
                        walletBalanceCard

                        // Quick Actions
                        quickActionsSection

                        // Chores Preview
                        choresPreview

                        // Marketplace Preview
                        marketplacePreview

                        // Device Hours
                        deviceHoursCard
                    }
                    .padding(.horizontal, AppTheme.Child.screenPadding)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard let token = authManager.session?.accessToken else { return }
                await appState.fetchCreditScore(accessToken: token)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kidzone")
                        .font(AppTheme.Child.headlineFont.weight(.heavy))
                        .foregroundStyle(AppTheme.Child.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authManager.currentUser {
                Text("Hey \(user.username)! 👋")
                    .font(AppTheme.Child.titleFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Text("Let's make money moves today! 💰")
                    .font(AppTheme.Child.headlineFont.weight(.medium))
                    .foregroundStyle(AppTheme.Child.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
    
    // MARK: - Credit Score Card
    private var creditScoreCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credit Score")
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(appState.state.creditScore)")
                            .font(.system(size: 56, design: .rounded).weight(.heavy))
                            .foregroundStyle(AppTheme.Child.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        ScoreBadge(score: appState.state.creditScore)
                    }
                }

                Spacer()

                // Animated Circular Gauge
                CircularGauge(value: Double(appState.state.creditScore), maxValue: 850)
                    .frame(width: 120, height: 120)
            }

            // Stats Row
            HStack(spacing: 16) {
                MetricPill(label: "Credit Line", value: appState.state.creditLineFormatted)
                MetricPill(label: "Used", value: appState.state.utilization)
                MetricPill(label: "Wallet", value: appState.state.walletBalanceFormatted)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                        .stroke(AppTheme.Child.primary.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Wallet Balance Card
    private var walletBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Money")
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)

                Text(appState.state.walletBalanceFormatted)
                    .font(AppTheme.Child.titleFont.weight(.bold))
                    .foregroundStyle(AppTheme.Child.accent)
            }

            Spacer()

            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Child.accent)
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)

            HStack(spacing: 12) {
                QuickActionButton(icon: "checkmark.circle.fill", label: "Do Chores", color: AppTheme.Child.success) {
                    onSelectTab?(1) // Chores tab
                }

                QuickActionButton(icon: "cart.fill", label: "Shop", color: AppTheme.Child.secondary) {
                    onSelectTab?(3) // Shop tab
                }

                QuickActionButton(icon: "creditcard.fill", label: "My Cards", color: AppTheme.Child.primary) {
                    onSelectTab?(2) // Cards tab
                }
            }
        }
    }
    
    // MARK: - Chores Preview
    private var choresPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Chores")
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Spacer()

                NavigationLink(destination: ChoresView()) {
                    Text("See All")
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.Child.primary)
                }
            }

            ForEach(Array(appState.state.chores.prefix(2))) { chore in
                ChoreRow(chore: chore)
            }
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }

    // MARK: - Marketplace Preview
    private var marketplacePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Rewards")
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Spacer()

                NavigationLink(destination: MarketplaceView()) {
                    Text("Shop All")
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.Child.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(appState.state.marketItems.prefix(3))) { item in
                        MarketplacePreviewCard(item: item)
                    }
                }
            }
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }

    // MARK: - Device Hours Card
    private var deviceHoursCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.Child.accent)

                Text("Device Hours")
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Time")
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)

                    Text(appState.state.deviceHours.formatted())
                        .font(AppTheme.Child.titleFont.weight(.bold))
                        .foregroundStyle(AppTheme.Child.accent)
                }

                Spacer()

                // Health indicator
                VStack(spacing: 4) {
                    Text("Health")
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)

                    Circle()
                        .fill(appState.state.deviceHealth > 0.7 ? AppTheme.Child.success : AppTheme.Child.warning)
                        .frame(width: 20, height: 20)
                }
            }

            ProgressView(value: appState.state.deviceHealth, total: 1.0)
                .tint(AppTheme.Child.success)
                .background(AppTheme.Child.textSecondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Keep your credit score high to unlock more screen time! 🎮")
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)

                Text(label)
                    .font(AppTheme.Child.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.Child.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Child.cardBackground.opacity(0.4))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Marketplace Preview Card
struct MarketplacePreviewCard: View {
    let item: MarketplaceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.tagline)
                .font(AppTheme.Child.captionFont.weight(.bold))
                .foregroundStyle(AppTheme.Child.textSecondary)

            Text(item.name)
                .font(AppTheme.Child.headlineFont)
                .foregroundStyle(AppTheme.Child.textPrimary)
                .lineLimit(2)

            Spacer()

            Text(item.priceFormatted)
                .font(AppTheme.Child.headlineFont.weight(.bold))
                .foregroundStyle(AppTheme.Child.accent)
        }
        .frame(width: 140, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }
}
