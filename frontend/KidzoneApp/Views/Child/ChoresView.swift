import SwiftUI

struct ChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedChore: Chore?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSegment: ChoreSegment = .active
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                if appState.state.chores.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Picker("Chores", selection: $selectedSegment) {
                                Text("Active").tag(ChoreSegment.active)
                                Text("Completed").tag(ChoreSegment.completed)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            VStack(spacing: AppTheme.Child.cardSpacing) {
                                ForEach(filteredChores) { chore in
                                    ChoreCard(chore: chore) {
                                        selectedChore = chore
                                    }
                                }
                                if filteredChores.isEmpty {
                                    Text("No chores in this section yet.")
                                        .font(AppTheme.Child.bodyFont)
                                        .foregroundStyle(AppTheme.Child.textSecondary)
                                }
                            }
                            .padding(AppTheme.Child.screenPadding)
                        }
                    }
                }
        }
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedChore) { chore in
                ChoreDetailView(chore: chore)
            }
            .task { await loadChores(force: false, showLoading: true) }
            .onAppear {
                // Auto-refresh every 1 second (silently in background)
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    Task {
                        await loadChores(force: false, showLoading: false)
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
            .refreshable { await loadChores(force: true, showLoading: false) }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoreUpdated"))) { _ in
                Task { await loadChores(force: true, showLoading: false) }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Child.textSecondary.opacity(0.5))

            Text("No chores yet!")
                .font(AppTheme.Child.titleFont)
                .foregroundStyle(AppTheme.Child.textPrimary)

            Text("Your parent will assign chores soon")
                .font(AppTheme.Child.bodyFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.danger)
            }
        }
    }

    private func loadChores(force: Bool = false, showLoading: Bool = false) async {
        guard let token = authManager.session?.accessToken else { return }
        if isLoading && showLoading { return }
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        defer { 
            if showLoading {
                isLoading = false
            }
        }
        await appState.fetchChores(accessToken: token, force: force)
        if let err = appState.choreError {
            errorMessage = err
        }
    }

    private var filteredChores: [Chore] {
        switch selectedSegment {
        case .active:
            return appState.state.chores.filter { $0.status == .assigned || $0.status == .pendingApproval }
        case .completed:
            return appState.state.chores.filter { $0.status == .completed || $0.status == .rejected }
        }
    }
}

struct ChoreCard: View {
    let chore: Chore
    let action: () -> Void

    var statusColor: Color {
        switch chore.status {
        case .assigned: return AppTheme.Child.warning
        case .pendingApproval: return AppTheme.Child.warning
        case .completed: return AppTheme.Child.success
        case .rejected: return AppTheme.Child.danger
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(chore.title)
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(AppTheme.Child.textPrimary)

                    Text(chore.detail)
                        .font(AppTheme.Child.bodyFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(chore.rewardFormatted)
                        .font(AppTheme.Child.headlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.Child.accent)

                    Text(chore.status.label)
                        .font(AppTheme.Child.captionFont.weight(.bold))
                        .foregroundStyle(AppTheme.Child.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.3))
                        )
                }
            }
            .padding(AppTheme.Child.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                    .fill(AppTheme.Child.cardBackground.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                            .stroke(AppTheme.Child.textSecondary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ChoreDetailView: View {
    let chore: Chore
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showCompletionAlert = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppTheme.Child.success)

                        Text(chore.title)
                            .font(AppTheme.Child.titleFont)
                            .foregroundStyle(AppTheme.Child.textPrimary)

                        Text(chore.detail)
                            .font(AppTheme.Child.headlineFont)
                            .foregroundStyle(AppTheme.Child.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    Spacer()

                    VStack(spacing: 20) {
                        RewardCard(amount: chore.rewardFormatted)

                        if chore.status == .assigned {
                            Button(action: {
                                showCompletionAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Complete")
                                        .font(AppTheme.Child.headlineFont)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Child.success)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Chore Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Child.textPrimary)
                }
            }
            .alert("Complete Chore?", isPresented: $showCompletionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Complete!") {
                    Task { await submitChore() }
                }
            } message: {
                Text("Once you mark this complete, your parent will need to approve it before you get paid.")
            }
        }
    }

    private func submitChore() async {
        guard let token = authManager.session?.accessToken else { return }
        if isSubmitting { return }
        isSubmitting = true
        errorMessage = nil
        do {
            try await appState.submitChore(accessToken: token, choreId: chore.id)
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("ChoreUpdated"), object: nil)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        isSubmitting = false
    }
}

struct RewardCard: View {
    let amount: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Reward")
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary)

            Text(amount)
                .font(.system(size: 48, design: .rounded).weight(.heavy))
                .foregroundStyle(AppTheme.Child.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.4))
        )
    }
}
