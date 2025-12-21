import SwiftUI
import UIKit

struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var familyMembers: [User] = []
    @State private var isLoadingMembers = false
    @State private var memberError: String?
    @State private var lastFamilyFetch: Date?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Family Code
                        familyCodeCard

                        // Family Overview
                        familyOverviewCard

                        // Pending Approvals
                        pendingApprovalsCard

                        // Recent Activity
                        recentActivityCard

                        // Quick Stats
                        quickStatsGrid
                    }
                    .padding(AppTheme.Parent.screenPadding)
                }
                .refreshable {
                    await refreshDashboard(force: true, showLoading: true)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await refreshDashboard(force: false, showLoading: true)
            }
            .onAppear {
                Task {
                    await refreshDashboard(force: false, showLoading: false)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AuthenticationManager.onboardingCompletedNotification)) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshDashboard"))) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoreCreated"))) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoreUpdated"))) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FamilyUpdated"))) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authManager.currentUser {
                Text("Hello, \(user.username)")
                    .font(AppTheme.Parent.titleFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)

                Text("Monitor your family's financial progress")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var familyCodeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family Code")
                .font(AppTheme.Parent.headlineFont)
                .foregroundStyle(AppTheme.Parent.textPrimary)
            if let familyId = authManager.currentUser?.familyId {
                HStack {
                    Text(familyId)
                        .font(AppTheme.Parent.bodyFont.monospaced().weight(.semibold))
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = familyId
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(AppTheme.Parent.captionFont.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Parent.primary)
                }
                Text("Share this code with your kids so they can join your family.")
                    .font(AppTheme.Parent.captionFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
            } else {
                Text("Family code unavailable")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
            }
        }
        .padding(AppTheme.Parent.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var familyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Family Overview")
                .font(AppTheme.Parent.headlineFont)
                .foregroundStyle(AppTheme.Parent.textPrimary)

            if isLoadingMembers {
                ProgressView()
                    .tint(AppTheme.Parent.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let memberError {
                Text(memberError)
                    .font(AppTheme.Parent.captionFont)
                    .foregroundStyle(AppTheme.Parent.danger)
            } else if familyMembers.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                        .font(.system(size: 24, weight: .semibold))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No children yet")
                            .font(AppTheme.Parent.headlineFont)
                            .foregroundStyle(AppTheme.Parent.textPrimary)
                        Text("Share the family code so your kids can join.")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(familyMembers) { member in
                    FamilyMemberRow(member: member)
                }
            }
        }
        .padding(AppTheme.Parent.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var pendingApprovalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Approvals")
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)

                Spacer()

                Text("\(pendingChores.count)")
                    .font(AppTheme.Parent.titleFont.weight(.bold))
                    .foregroundStyle(AppTheme.Parent.warning)
            }

            ForEach(pendingChores) { chore in
                PendingChoreRow(chore: chore, onDecision: { action in
                    Task {
                        guard let token = authManager.session?.accessToken else { return }
                        do {
                            switch action {
                            case .approve:
                                try await appState.approveChore(accessToken: token, choreId: chore.id)
                            case .reject:
                                try await appState.rejectChore(accessToken: token, choreId: chore.id)
                            }
                            // Refresh dashboard after decision
                            await refreshDashboard(force: true, showLoading: false)
                        } catch {
                            print("Error handling chore decision: \(error)")
                        }
                    }
                })
            }

            if pendingChores.isEmpty {
                Text("No pending approvals")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(AppTheme.Parent.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(AppTheme.Parent.headlineFont)
                .foregroundStyle(AppTheme.Parent.textPrimary)

            Text("Activity feed will appear here")
                .font(AppTheme.Parent.bodyFont)
                .foregroundStyle(AppTheme.Parent.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
        .padding(AppTheme.Parent.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var quickStatsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickStatCard(title: "Total Chores", value: "\(appState.state.chores.count)", icon: "list.clipboard.fill", color: AppTheme.Parent.primary)
                QuickStatCard(title: "Avg Score", value: "\(appState.state.creditScore)", icon: "chart.line.uptrend.xyaxis", color: AppTheme.Parent.success)
            }
        }
    }

    // MARK: - Data
    private func refreshDashboard(force: Bool, showLoading: Bool) async {
        guard let token = authManager.session?.accessToken else { return }
        
        // Refresh both family members and chores in parallel
        async let membersTask = loadFamilyMembers(force: force, showLoading: showLoading)
        async let choresTask = appState.fetchChores(accessToken: token, force: force)
        
        await membersTask
        await choresTask
    }
    
    private func loadFamilyMembers(force: Bool = false, showLoading: Bool = true) async {
        guard let token = authManager.session?.accessToken else { return }
        let freshnessWindow: TimeInterval = 10
        if !force, let last = lastFamilyFetch, Date().timeIntervalSince(last) < freshnessWindow {
            return
        }
        if isLoadingMembers && !force { return }
        if showLoading { isLoadingMembers = true }
        memberError = nil
        defer { if showLoading { isLoadingMembers = false } }
        do {
            let members = try await AuthAPI.shared.fetchFamilyMembers(accessToken: token)
            await MainActor.run {
                self.familyMembers = members
                self.lastFamilyFetch = Date()
            }
        } catch is CancellationError {
            // ignore pull-to-refresh cancellations
        } catch let urlError as URLError where urlError.code == .cancelled {
            // ignore URLSession cancellations (refresh gesture ended)
        } catch {
            await MainActor.run {
                self.memberError = error.localizedDescription
            }
        }
    }
}

private extension ParentDashboardView {
    var pendingChores: [Chore] {
        appState.state.chores.filter { $0.status == .pendingApproval }
    }
}

struct FamilyMemberRow: View {
    let member: User

    var body: some View {
        HStack {
            Circle()
                .fill(AppTheme.Parent.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.username.prefix(1).uppercased())
                        .font(AppTheme.Parent.headlineFont)
                        .foregroundStyle(AppTheme.Parent.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.username)
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)

                Text("Credit Score: \(member.currentCreditScore)")
                    .font(AppTheme.Parent.captionFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PendingChoreRow: View {
    let chore: Chore
    var onDecision: ((ApprovalAction) -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(AppTheme.Parent.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.Parent.textPrimary)

                Text(chore.detail)
                    .font(AppTheme.Parent.captionFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                
                if let assigneeName = chore.assigneeName {
                    Text("From: \(assigneeName)")
                        .font(AppTheme.Parent.captionFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(chore.rewardFormatted)
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.success)

                HStack(spacing: 8) {
                    Button(action: {
                        onDecision?(.approve)
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.Parent.success)
                    }

                    Button(action: {
                        onDecision?(.reject)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.Parent.danger)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Parent.cardBackground.opacity(0.3))
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
                .font(AppTheme.Parent.titleFont)
                .foregroundStyle(AppTheme.Parent.textPrimary)

            Text(title)
                .font(AppTheme.Parent.captionFont)
                .foregroundStyle(AppTheme.Parent.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
