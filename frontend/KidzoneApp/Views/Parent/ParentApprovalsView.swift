import SwiftUI

struct ParentApprovalsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var requestsVM = RequestsViewModel()
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Approvals")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await load(force: false)
            }
            .refreshable {
                await load(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FamilyUpdated"))) { _ in
                Task { await load(force: true) }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if requestsVM.isLoading && requestsVM.requests.isEmpty {
            ProgressView()
                .tint(AppTheme.Parent.primary)
        } else if let error = requestsVM.errorMessage {
            VStack(spacing: 12) {
                Text(error)
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.danger)
                Button("Retry") { Task { await load(force: true) } }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Parent.primary)
            }
        } else if requestsVM.requests.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "cart")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.Parent.textSecondary.opacity(0.5))
                Text("No requests yet")
                    .font(AppTheme.Parent.titleFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)
                Text("Kids can request items and they will appear here for approval.")
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        } else {
            List {
                ForEach(requestsVM.requests) { request in
                    RequestRow(request: request) { action in
                        Task { await handle(action: action, for: request) }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .applyScrollContentBackgroundHidden()
            .background(Color.clear)
        }
    }

    private func load(force: Bool) async {
        guard let token = authManager.session?.accessToken else { return }
        await requestsVM.load(accessToken: token, force: force, showLoading: true)
    }

    private func handle(action: ApprovalAction, for request: PurchaseRequest) async {
        guard let token = authManager.session?.accessToken else { return }
        switch action {
        case .approve:
            await requestsVM.approve(accessToken: token, id: request.id)
        case .reject:
            await requestsVM.reject(accessToken: token, id: request.id)
        }
        await load(force: true)
    }
}

// MARK: - Compatibility Helpers

private extension View {
    @ViewBuilder
    func applyScrollContentBackgroundHidden() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

struct RequestRow: View {
    let request: PurchaseRequest
    var onDecision: ((ApprovalAction) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(AppTheme.Parent.headlineFont)
                        .foregroundStyle(AppTheme.Parent.textPrimary)
                    if let requester = request.requesterName {
                        Text("From: \(requester)")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)
                    }
                    if let desc = request.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text(request.priceFormatted)
                    .font(AppTheme.Parent.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.Parent.success)
            }

            HStack {
                statusBadge
                Spacer()
                if request.status == .pending {
                    HStack(spacing: 12) {
                        Button {
                            onDecision?(.reject)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.Parent.danger)
                                .font(.system(size: 22))
                        }
                        Button {
                            onDecision?(.approve)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.Parent.success)
                                .font(.system(size: 22))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
        )
    }

    private var statusBadge: some View {
        Text(request.status.label)
            .font(AppTheme.Parent.captionFont.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(colorForStatus.opacity(0.15))
            )
            .foregroundStyle(colorForStatus)
    }

    private var colorForStatus: Color {
        switch request.status {
        case .pending: return AppTheme.Parent.warning
        case .approved: return AppTheme.Parent.success
        case .rejected, .cancelled: return AppTheme.Parent.danger
        }
    }
}
