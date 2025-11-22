import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.parentGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Family Overview
                        familyOverviewCard
                        
                        // Pending Approvals
                        pendingApprovalsCard
                        
                        // Recent Activity
                        recentActivityCard
                        
                        // Quick Stats
                        quickStatsGrid
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authManager.currentUser {
                Text("Hello, \(user.username)")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                
                Text("Monitor your family's financial progress")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var familyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family Overview")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            // Mock family members
            ForEach([User.mockChild]) { member in
                FamilyMemberRow(member: member)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    private var pendingApprovalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Approvals")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(appState.state.chores.filter { $0.status == .pending }.count)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.kidzoneWarning)
            }
            
            ForEach(appState.state.chores.filter { $0.status == .pending }) { chore in
                PendingChoreRow(chore: chore)
            }
            
            if appState.state.chores.filter({ $0.status == .pending }).isEmpty {
                Text("No pending approvals")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            Text("Activity feed will appear here")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
    
    private var quickStatsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickStatCard(title: "Total Chores", value: "\(appState.state.chores.count)", icon: "list.clipboard.fill", color: Color.kidzoneBlue)
                QuickStatCard(title: "Avg Score", value: "\(appState.state.creditScore)", icon: "chart.line.uptrend.xyaxis", color: Color.kidzoneGreen)
            }
        }
    }
}

struct FamilyMemberRow: View {
    let member: User
    
    var body: some View {
        HStack {
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.username.prefix(1).uppercased())
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.username)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Text("Credit Score: \(member.currentCreditScore)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PendingChoreRow: View {
    let chore: Chore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(chore.detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(chore.rewardFormatted)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.kidzoneYellow)
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.kidzoneSuccess)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.kidzoneDanger)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
        )
    }
}

