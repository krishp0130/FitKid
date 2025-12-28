import SwiftUI
import UIKit

struct ParentDashboardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var requestsVM = RequestsViewModel()
    @State private var familyMembers: [User] = []
    @State private var isLoadingMembers = false
    @State private var memberError: String?
    @State private var lastFamilyFetch: Date?
    @State private var refreshTimer: Timer?
    @State private var showFamilyCodeCard = true
    
    private let familyCodeVisibilityDays: Double = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Family Code (shown only for the first few days)
                        if showFamilyCodeCard {
                            familyCodeCard
                        }

                        // Family Overview
                        familyOverviewCard

                        // Pending Approvals
                        pendingApprovalsCard

                        // Recent Activity
                        recentActivityCard

                        // Quick Stats
                        quickStatsGrid
                    }
                    .padding(.horizontal, AppTheme.Parent.screenPadding)
                    .padding(.bottom, AppTheme.Parent.screenPadding)
                    .padding(.top, 12) // tighter top spacing so header sits near the nav bar without a large gap
                }
                .refreshable {
                    await refreshDashboard(force: true, showLoading: true)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline) // avoid large-title offset that created blank space
            .task {
                await refreshDashboard(force: false, showLoading: true)
            }
            .onAppear {
                updateFamilyCodeVisibility()
                Task {
                    await refreshDashboard(force: false, showLoading: false)
                }
                // Auto-refresh every 1 second
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    Task {
                        await refreshDashboard(force: true, showLoading: false)
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: AuthenticationManager.onboardingCompletedNotification)) { _ in
                Task { await refreshDashboard(force: true, showLoading: false) }
            }
            .onChange(of: authManager.currentUser?.id) { _ in
                updateFamilyCodeVisibility()
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

                Text("\(pendingApprovalsTotal)")
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
                Text(pendingApprovalsTotal == 0 ? "No pending approvals" : "No pending chore approvals")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            
            if !pendingRequests.isEmpty {
                Divider()
                    .overlay(AppTheme.Parent.textSecondary.opacity(0.2))
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Purchase Requests")
                            .font(AppTheme.Parent.bodyFont.weight(.semibold))
                        Spacer()
                        Text("\(pendingRequests.count)")
                            .font(AppTheme.Parent.captionFont.weight(.bold))
                            .foregroundStyle(AppTheme.Parent.warning)
                    }
                    ForEach(pendingRequests.prefix(3)) { req in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(req.title)
                                    .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.Parent.textPrimary)
                                if let requester = req.requesterName {
                                    Text("From: \(requester)")
                                        .font(AppTheme.Parent.captionFont)
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }
                            Spacer()
                            Text(req.priceFormatted)
                                .font(AppTheme.Parent.bodyFont.weight(.bold))
                                .foregroundStyle(AppTheme.Parent.success)
                        }
                        .padding(10)
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
            
            if recentActivity.isEmpty {
                Text("No recent activity yet")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentActivity, id: \.id) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundStyle(item.color)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(item.color.opacity(0.12))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.Parent.textPrimary)
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(AppTheme.Parent.captionFont)
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                                Text(item.timeAgo)
                                    .font(AppTheme.Parent.captionFont)
                                    .foregroundStyle(AppTheme.Parent.textSecondary.opacity(0.8))
                            }
                            Spacer()
                            if let amount = item.trailing {
                                Text(amount)
                                    .font(AppTheme.Parent.bodyFont.weight(.bold))
                                    .foregroundStyle(item.color)
                            }
                        }
                        .padding(12)
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
        async let requestsTask = loadRequests(force: force, showLoading: showLoading)
        
        await membersTask
        await choresTask
        await requestsTask
    }
    
    private func loadRequests(force: Bool = false, showLoading: Bool = false) async {
        guard let token = authManager.session?.accessToken else { return }
        await requestsVM.load(accessToken: token, force: force, showLoading: showLoading)
    }
    
    // MARK: - Family Code Visibility
    private func updateFamilyCodeVisibility() {
        guard let userId = authManager.currentUser?.id else {
            showFamilyCodeCard = true
            return
        }
        let key = "familyCodeFirstSeen-\(userId)"
        let defaults = UserDefaults.standard
        let now = Date()
        if let firstSeen = defaults.object(forKey: key) as? Date {
            let days = now.timeIntervalSince(firstSeen) / (60 * 60 * 24)
            showFamilyCodeCard = days <= familyCodeVisibilityDays
        } else {
            defaults.set(now, forKey: key)
            showFamilyCodeCard = true
        }
    }
    
    private func loadFamilyMembers(force: Bool = false, showLoading: Bool = true) async {
        guard let token = authManager.session?.accessToken else { return }
        let freshnessWindow: TimeInterval = 0.5 // Reduced from 10 to 0.5 seconds for real-time updates
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

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let timeAgo: String
    let icon: String
    let color: Color
    let trailing: String?
}

private extension ParentDashboardView {
    var pendingChores: [Chore] {
        appState.state.chores.filter { $0.status == .pendingApproval }
    }
    
    var pendingRequests: [PurchaseRequest] {
        requestsVM.requests.filter { $0.status == .pending }
    }
    
    var pendingApprovalsTotal: Int {
        pendingChores.count + pendingRequests.count
    }
    
    var recentActivity: [ActivityItem] {
        let formatter = ISO8601DateFormatter()
        let items: [(Date, ActivityItem)] = requestsVM.requests.compactMap { req in
            let date = formatter.date(from: req.createdAt) ?? Date.distantPast
            let statusText = req.status.label
            let icon: String
            let color: Color
            switch req.status {
            case .pending:
                icon = "hourglass"
                color = AppTheme.Parent.warning
            case .approved:
                icon = "checkmark.circle.fill"
                color = AppTheme.Parent.success
            case .rejected, .cancelled:
                icon = "xmark.circle.fill"
                color = AppTheme.Parent.danger
            }
            let subtitle = req.requesterName.flatMap { "From: \($0)" }
            let item = ActivityItem(
                id: req.id,
                title: "\(statusText): \(req.title)",
                subtitle: subtitle,
                timeAgo: timeAgo(from: date),
                icon: icon,
                color: color,
                trailing: req.priceFormatted
            )
            return (date, item)
        }
        return items.sorted { $0.0 > $1.0 }.prefix(5).map { $0.1 }
    }
    
    func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        if seconds < 60 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(days)d ago"
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
