import SwiftUI

struct ParentApprovalsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    
    var pendingChores: [Chore] {
        appState.state.chores.filter { $0.status == .pending }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.parentGradient
                    .ignoresSafeArea()
                
                if pendingChores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text("All caught up!")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(pendingChores) { chore in
                                ApprovalCard(chore: chore)
                            }
                        }
                        .padding(20)
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
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(chore.detail)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            HStack {
                Text("Reward: \(chore.rewardFormatted)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.kidzoneYellow)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Approve
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.kidzoneSuccess)
                    )
                }
                
                Button(action: {
                    // TODO: Reject
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.kidzoneDanger)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
        )
    }
}

