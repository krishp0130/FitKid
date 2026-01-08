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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(AppTheme.Parent.headlineFont)
                        .foregroundStyle(AppTheme.Parent.textPrimary)
                    if let method = request.paymentMethod {
                        HStack(spacing: 6) {
                            Label(methodLabel(method), systemImage: methodIcon(method))
                                .labelStyle(.titleAndIcon)
                                .font(AppTheme.Parent.captionFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                            if let card = request.cardName {
                                Text("• \(card)")
                                    .font(AppTheme.Parent.captionFont)
                                    .foregroundStyle(AppTheme.Parent.textSecondary)
                            }
                        }
                    }
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
            
            if let method = request.paymentMethod {
                HStack(spacing: 6) {
                    Text("Payment:")
                        .font(AppTheme.Parent.captionFont)
                        .foregroundStyle(AppTheme.Parent.textSecondary)
                    Text(methodLabel(method))
                        .font(AppTheme.Parent.captionFont.weight(.semibold))
                        .foregroundStyle(AppTheme.Parent.textPrimary)
                    if let card = request.cardName {
                        Text("• \(card)")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
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
