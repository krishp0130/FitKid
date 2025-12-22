import SwiftUI

struct RequestHistoryView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var requestsVM = RequestsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("My Requests")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await load(force: false)
            }
            .refreshable {
                await load(force: true)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if requestsVM.isLoading && requestsVM.requests.isEmpty {
            ProgressView()
                .tint(AppTheme.Child.accent)
        } else if let error = requestsVM.errorMessage {
            VStack(spacing: 12) {
                Text(error)
                    .font(AppTheme.Child.bodyFont)
                    .foregroundStyle(AppTheme.Child.danger)
                Button("Retry") { Task { await load(force: true) } }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Child.accent)
            }
        } else if requestsVM.requests.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "cart")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.Child.textSecondary.opacity(0.6))
                Text("No requests yet")
                    .font(AppTheme.Child.titleFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)
                Text("Ask for items and track approvals here.")
                    .font(AppTheme.Child.bodyFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
            }
            .padding()
        } else {
            List {
                ForEach(requestsVM.requests) { request in
                    ChildRequestRow(request: request)
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
}

private struct ChildRequestRow: View {
    let request: PurchaseRequest

    var statusColor: Color {
        switch request.status {
        case .pending: return AppTheme.Child.warning
        case .approved: return AppTheme.Child.success
        case .rejected, .cancelled: return AppTheme.Child.danger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.title)
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)
                Spacer()
                Text(request.priceFormatted)
                    .font(AppTheme.Child.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.Child.accent)
            }
            if let desc = request.description, !desc.isEmpty {
                Text(desc)
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
                    .lineLimit(2)
            }
            HStack {
                Text(request.status.label)
                    .font(AppTheme.Child.captionFont.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
                    .foregroundStyle(statusColor)
                Spacer()
                if let url = request.url, let link = URL(string: url) {
                    Link("View", destination: link)
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(AppTheme.Child.accent)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Child.cardBackground.opacity(0.5))
        )
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
