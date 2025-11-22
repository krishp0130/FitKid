import SwiftUI

struct ChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedChore: Chore?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                if appState.state.chores.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Child.cardSpacing) {
                            ForEach(appState.state.chores) { chore in
                                ChoreCard(chore: chore) {
                                    selectedChore = chore
                                }
                            }
                        }
                        .padding(AppTheme.Child.screenPadding)
                    }
                }
            }
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedChore) { chore in
                ChoreDetailView(chore: chore)
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
        }
    }
}

struct ChoreCard: View {
    let chore: Chore
    let action: () -> Void

    var statusColor: Color {
        switch chore.status {
        case .pending: return AppTheme.Child.warning
        case .approved: return AppTheme.Child.success
        case .overdue: return AppTheme.Child.danger
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
    @State private var showCompletionAlert = false

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

                        if chore.status == .pending {
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
                    // TODO: Complete chore
                    dismiss()
                }
            } message: {
                Text("Once you mark this complete, your parent will need to approve it before you get paid.")
            }
        }
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

