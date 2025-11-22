import SwiftUI

struct ChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedChore: Chore?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                if appState.state.chores.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(appState.state.chores) { chore in
                                ChoreCard(chore: chore) {
                                    selectedChore = chore
                                }
                            }
                        }
                        .padding(20)
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
                .foregroundStyle(.white.opacity(0.5))
            
            Text("No chores yet!")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            
            Text("Your parent will assign chores soon")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct ChoreCard: View {
    let chore: Chore
    let action: () -> Void
    
    var statusColor: Color {
        switch chore.status {
        case .pending: return Color.kidzoneWarning
        case .approved: return Color.kidzoneSuccess
        case .overdue: return Color.kidzoneDanger
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
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(chore.detail)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(chore.rewardFormatted)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.kidzoneYellow)
                    
                    Text(chore.status.label)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.3))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
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
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.kidzoneSuccess)
                        
                        Text(chore.title)
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .foregroundStyle(.white)
                        
                        Text(chore.detail)
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
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
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    Capsule()
                                        .fill(Color.kidzoneSuccess)
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
                    .foregroundStyle(.white)
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
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            
            Text(amount)
                .font(.system(size: 48, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.kidzoneYellow)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.15))
        )
    }
}

