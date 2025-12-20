import SwiftUI

struct ParentApprovalsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.Parent.textSecondary.opacity(0.5))
                    Text("Requests coming soon")
                        .font(AppTheme.Parent.titleFont)
                        .foregroundStyle(AppTheme.Parent.textPrimary)
                    Text("This tab will list purchase requests for approval.")
                        .font(AppTheme.Parent.bodyFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Approvals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
