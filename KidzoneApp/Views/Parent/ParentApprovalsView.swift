import SwiftUI

struct ParentApprovalsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    
    var pendingChores: [Chore] {
        appState.state.chores.filter { $0.status == .pending }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                if pendingChores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppTheme.Parent.success.opacity(0.5))

                        Text("All caught up!")
                            .font(AppTheme.Parent.titleFont)
                            .foregroundStyle(AppTheme.Parent.textPrimary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Parent.cardSpacing) {
                            ForEach(pendingChores) { chore in
                                ApprovalCard(chore: chore)
                            }
                        }
                        .padding(AppTheme.Parent.screenPadding)
                    }
                }
            }
            .navigationTitle("Approvals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ApprovalCard: View {
    let chore: Chore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(chore.title)
                        .font(AppTheme.Parent.headlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.Parent.textPrimary)

                    Text(chore.detail)
                        .font(AppTheme.Parent.bodyFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                }

                Spacer()
            }

            HStack {
                Text("Reward: \(chore.rewardFormatted)")
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.success)

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Approve
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                            .font(AppTheme.Parent.bodyFont.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Parent.success)
                    )
                }

                Button(action: {
                    // TODO: Reject
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                            .font(AppTheme.Parent.bodyFont.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Parent.danger)
                    )
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
}

