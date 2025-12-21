import SwiftUI

struct ParentApprovalsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var refreshTimer: Timer?
    
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
            .onAppear {
                // Start auto-refresh timer (every 2 seconds)
                startAutoRefresh()
            }
            .onDisappear {
                // Stop timer when view disappears
                stopAutoRefresh()
            }
        }
    }
    
    private func startAutoRefresh() {
        // Stop existing timer if any
        stopAutoRefresh()
        
        // Create new timer that fires every 1 second
        // This view is currently a placeholder, but timer is ready for when it's implemented
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // TODO: Refresh approvals data when this view is implemented
            // Task {
            //     await refreshApprovals()
            // }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
