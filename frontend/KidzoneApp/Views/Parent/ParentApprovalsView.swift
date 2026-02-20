import SwiftUI

struct ParentApprovalsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var requestsVM = RequestsViewModel()
    @State private var isRefreshing = false
    @State private var selectedSegment: ApprovalSegment = .pending

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
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Approvals", selection: $selectedSegment) {
                        Text("Active").tag(ApprovalSegment.pending)
                        Text("Approved").tag(ApprovalSegment.approved)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)

                    if requestsVM.requests.isEmpty {
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: AppTheme.Parent.cardSpacing) {
                            ForEach(filteredRequests) { request in
                                RequestRow(request: request) { action in
                                    Task { await handle(action: action, for: request) }
                                }
                            }

                            if filteredRequests.isEmpty {
                                Text(emptyMessage)
                                    .font(AppTheme.Parent.bodyFont)
                                    .foregroundStyle(AppTheme.Parent.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Parent.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.Parent.screenPadding)
            }
        }
    }

    private var filteredRequests: [PurchaseRequest] {
        switch selectedSegment {
        case .pending:
            return requestsVM.requests.filter { $0.status == .pending }
        case .approved:
            return requestsVM.requests.filter { $0.status == .approved }
        }
    }

    private var emptyMessage: String {
        switch selectedSegment {
        case .pending:
            return "No active requests right now."
        case .approved:
            return "No approved requests yet."
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

enum ApprovalSegment: String, CaseIterable, Identifiable {
    case pending
    case approved
    
    var id: String { rawValue }
}

struct RequestRow: View {
    let request: PurchaseRequest
    var onDecision: ((ApprovalAction) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(request.title)
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)
                    .lineLimit(1)

                if let requester = request.requesterName {
                    Text("From: \(requester)")
                        .font(AppTheme.Parent.captionFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                }

                if let desc = request.description, !desc.isEmpty {
                    Text(desc)
                        .font(AppTheme.Parent.bodyFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                Text(request.priceFormatted)
                    .font(AppTheme.Parent.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.Parent.success)

                statusBadge

                if request.status == .pending {
                    VStack(spacing: 8) {
                        Text("Needs Approval")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)

                        HStack(spacing: 8) {
                            Button {
                                onDecision?(.approve)
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.Parent.success)
                            }
                            .buttonStyle(.plain)
                            Button {
                                onDecision?(.reject)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.Parent.danger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .layoutPriority(1)
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

    private var statusBadge: some View {
        Text(request.status.label)
            .font(AppTheme.Parent.captionFont.weight(.semibold))
            .foregroundStyle(AppTheme.Parent.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.Parent.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.Parent.textSecondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    private func methodLabel(_ raw: String) -> String {
        switch raw {
        case "CREDIT": return "Credit Card"
        case "WALLET": return "Wallet"
        case "CREDIT_CARD_APPLICATION": return "Card Application"
        default: return raw
        }
    }

    private func methodIcon(_ raw: String) -> String {
        switch raw {
        case "CREDIT", "CREDIT_CARD_APPLICATION": return "creditcard.fill"
        case "WALLET": return "wallet.pass.fill"
        default: return "circle.fill"
        }
    }
}
