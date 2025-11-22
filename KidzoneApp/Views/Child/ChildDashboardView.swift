import SwiftUI

struct ChildDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kidzone")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authManager.currentUser {
                Text("Hey \(user.username)! 👋")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                
                Text("Let's make money moves today! 💰")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
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
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    HStack(spacing: 12) {
                        Text("\(appState.state.creditScore)")
                            .font(.system(size: 56, design: .rounded).weight(.heavy))
                            .foregroundStyle(.white)
                        
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
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Wallet Balance Card
    private var walletBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Money")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(appState.state.walletBalanceFormatted)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.kidzoneYellow)
            }
            
            Spacer()
            
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.kidzoneYellow)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                QuickActionButton(icon: "checkmark.circle.fill", label: "Do Chores", color: Color.kidzoneGreen) {
                    // Navigate to chores
                }
                
                QuickActionButton(icon: "cart.fill", label: "Shop", color: Color.kidzoneOrange) {
                    // Navigate to marketplace
                }
                
                QuickActionButton(icon: "creditcard.fill", label: "My Cards", color: Color.kidzonePink) {
                    // Navigate to cards
                }
            }
        }
    }
    
    // MARK: - Chores Preview
    private var choresPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Chores")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                NavigationLink(destination: ChoresView()) {
                    Text("See All")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.kidzoneBlue)
                }
            }
            
            ForEach(Array(appState.state.chores.prefix(2))) { chore in
                ChoreRow(chore: chore)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    // MARK: - Marketplace Preview
    private var marketplacePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Rewards")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                NavigationLink(destination: MarketplaceView()) {
                    Text("Shop All")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.kidzoneBlue)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    // MARK: - Device Hours Card
    private var deviceHoursCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.kidzoneOrange)
                
                Text("Device Hours")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Time")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(appState.state.deviceHours.formatted())
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.kidzoneOrange)
                }
                
                Spacer()
                
                // Health indicator
                VStack(spacing: 4) {
                    Text("Health")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Circle()
                        .fill(appState.state.deviceHealth > 0.7 ? Color.kidzoneGreen : Color.kidzoneWarning)
                        .frame(width: 20, height: 20)
                }
            }
            
            ProgressView(value: appState.state.deviceHealth, total: 1.0)
                .tint(Color.kidzoneGreen)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("Keep your credit score high to unlock more screen time! 🎮")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
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
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
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
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            
            Text(item.name)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
            
            Text(item.priceFormatted)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.kidzoneYellow)
        }
        .frame(width: 140, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
        )
    }
}

