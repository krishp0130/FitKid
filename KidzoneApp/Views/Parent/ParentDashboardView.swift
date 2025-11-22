import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient - adapts to dark/light mode
                if colorScheme == .dark {
                    LinearGradient(
                        colors: [Color.darkBackground, Color.primaryBlue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color.lightBackground, Color.primaryBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with theme toggle
                        headerSection
                        
                        // Whoop-style Analytics Cards
                        analyticsOverviewSection
                        
                        // Family Members (Whoop-style)
                        familyMembersSection
                        
                        // Financial Health Metrics
                        financialHealthMetrics
                        
                        // Activity Timeline
                        activityTimelineSection
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemeToggle()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if let user = authManager.currentUser {
                    Text("Hello, \(user.username)")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Family Financial Overview")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Analytics Overview (Whoop-style)
    private var analyticsOverviewSection: some View {
        VStack(spacing: 16) {
            // Main Score Card (Whoop-style)
            AnalyticsScoreCard(
                title: "Family Score",
                value: calculateFamilyScore(),
                maxValue: 100,
                color: .primaryBlue,
                icon: "chart.bar.fill"
            )
            
            // Metric Grid
            HStack(spacing: 12) {
                AnalyticsMetricCard(
                    title: "Credit Score",
                    value: "\(averageCreditScore())",
                    subtitle: "Family Avg",
                    color: .primaryGreen,
                    icon: "creditcard.fill"
                )
                
                AnalyticsMetricCard(
                    title: "Active Tasks",
                    value: "\(appState.state.chores.count)",
                    subtitle: "This Week",
                    color: .primaryBlue,
                    icon: "checkmark.circle.fill"
                )
            }
            
            HStack(spacing: 12) {
                AnalyticsMetricCard(
                    title: "Earnings",
                    value: formatCurrency(totalEarnings()),
                    subtitle: "This Month",
                    color: .primaryGreen,
                    icon: "dollarsign.circle.fill"
                )
                
                AnalyticsMetricCard(
                    title: "Pending",
                    value: "\(pendingApprovalsCount())",
                    subtitle: "Awaiting Review",
                    color: .warning,
                    icon: "clock.fill"
                )
            }
        }
    }
    
    // MARK: - Family Members Section (Whoop-style cards)
    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family Members")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            
            // Mock family members - in production, fetch from API
            ForEach([User.mockChild]) { member in
                FamilyMemberAnalyticsCard(member: member, colorScheme: colorScheme)
            }
        }
    }
    
    // MARK: - Financial Health Metrics
    private var financialHealthMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Health")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                HealthMetricRow(
                    label: "Credit Utilization",
                    value: "45%",
                    trend: .up,
                    color: .primaryGreen
                )
                
                HealthMetricRow(
                    label: "Payment History",
                    value: "100%",
                    trend: .neutral,
                    color: .primaryBlue
                )
                
                HealthMetricRow(
                    label: "Chore Completion",
                    value: "85%",
                    trend: .down,
                    color: .warning
                )
            }
            .padding(20)
            .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Activity Timeline
    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 0) {
                ActivityTimelineItem(
                    icon: "checkmark.circle.fill",
                    title: "Chore Completed",
                    subtitle: "Alex completed 'Clean Room'",
                    time: "2 hours ago",
                    color: .primaryGreen
                )
                
                Divider()
                    .background(.secondary.opacity(0.3))
                
                ActivityTimelineItem(
                    icon: "creditcard.fill",
                    title: "Credit Card Used",
                    subtitle: "$45.00 purchase",
                    time: "5 hours ago",
                    color: .primaryBlue
                )
                
                Divider()
                    .background(.secondary.opacity(0.3))
                
                ActivityTimelineItem(
                    icon: "dollarsign.circle.fill",
                    title: "Allowance Earned",
                    subtitle: "$12.00 added to wallet",
                    time: "1 day ago",
                    color: .primaryGreen
                )
            }
            .padding(20)
            .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                icon: "plus.circle.fill",
                label: "Add Chore",
                color: .primaryBlue,
                action: {}
            )
            
            QuickActionCard(
                icon: "chart.bar.fill",
                label: "View Reports",
                color: .primaryGreen,
                action: {}
            )
        }
    }
    
    // MARK: - Helper Functions
    private func calculateFamilyScore() -> Int {
        // Mock calculation - in production, calculate from all family members
        return 78
    }
    
    private func averageCreditScore() -> Int {
        // Mock - average of all children's credit scores
        return appState.state.creditScore
    }
    
    private func totalEarnings() -> Int {
        // Sum of all approved chore rewards
        return appState.state.chores
            .filter { $0.status == .approved }
            .reduce(0) { $0 + $1.rewardCents }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        return cents.asCurrency
    }
    
    private func pendingApprovalsCount() -> Int {
        return appState.state.chores.filter { $0.status == .pending }.count
    }
}

// MARK: - Analytics Score Card (Whoop-style)
struct AnalyticsScoreCard: View {
    let title: String
    let value: Int
    let maxValue: Int
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 56, design: .rounded).weight(.heavy))
                    .foregroundStyle(.primary)
                
                Text("/ \(maxValue)")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(24)
        .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Analytics Metric Card
struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Family Member Analytics Card (Whoop-style)
struct FamilyMemberAnalyticsCard: View {
    let member: User
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(member.username.prefix(1).uppercased())
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.username)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Credit Score: \(member.currentCreditScore)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Trend indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Color.primaryGreen)
                    Text("+12")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.primaryGreen)
                    Text("7 days")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Metrics Row
            HStack(spacing: 20) {
                MiniMetric(label: "Wallet", value: "$50.00")
                MiniMetric(label: "Chores", value: "8/10")
                MiniMetric(label: "Health", value: "Good")
            }
        }
        .padding(20)
        .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct MiniMetric: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Health Metric Row
struct HealthMetricRow: View {
    let label: String
    let value: String
    let trend: TrendDirection
    let color: Color
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Image(systemName: trend.icon)
                .foregroundStyle(color)
                .font(.system(.headline, design: .rounded))
        }
    }
}

// MARK: - Activity Timeline Item
struct ActivityTimelineItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(.headline, design: .rounded))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
