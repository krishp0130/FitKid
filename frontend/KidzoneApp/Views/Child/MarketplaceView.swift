import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedItem: MarketplaceItem?
    @State private var showPurchaseSheet = false
    @State private var showRequests = false

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AppTheme.Child.cardSpacing),
                        GridItem(.flexible(), spacing: AppTheme.Child.cardSpacing)
                    ], spacing: AppTheme.Child.cardSpacing) {
                        ForEach(appState.state.marketItems) { item in
                            MarketplaceItemCard(item: item) {
                                selectedItem = item
                                showPurchaseSheet = true
                            }
                        }
                    }
                    .padding(AppTheme.Child.screenPadding)
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showRequests = true
                    } label: {
                        Label("My Requests", systemImage: "list.bullet.rectangle")
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                PurchaseView(item: item)
            }
            .sheet(isPresented: $showRequests) {
                RequestHistoryView()
                    .environmentObject(appState)
            }
        }
    }
}

struct MarketplaceItemCard: View {
    let item: MarketplaceItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Tag
                Text(item.tagline)
                    .font(AppTheme.Child.captionFont.weight(.bold))
                    .foregroundStyle(AppTheme.Child.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Child.primary.opacity(0.3))
                    )

                Text(item.name)
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.description)
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack {
                    Text(item.priceFormatted)
                        .font(AppTheme.Child.headlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.Child.accent)

                    Spacer()

                    if item.isDigital {
                        Image(systemName: "iphone")
                            .foregroundStyle(AppTheme.Child.textSecondary)
                    }
                }
            }
            .padding(16)
            .frame(height: 180)
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

struct PurchaseView: View {
    let item: MarketplaceItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedPayment: PaymentMethod = .wallet
    @State private var showConfirm = false
    @State private var link: String = ""
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var showSuccess = false

    var taxAmount: Int {
        Int(Double(item.priceCents) * appState.state.parentSettings.salesTax)
    }

    var totalAmount: Int {
        item.priceCents + taxAmount
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Item Image/Icon
                        Image(systemName: item.isDigital ? "iphone" : "gift.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(AppTheme.Child.accent)

                        // Item Info
                        VStack(spacing: 8) {
                            Text(item.name)
                                .font(AppTheme.Child.titleFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)

                            Text(item.description)
                                .font(AppTheme.Child.bodyFont)
                                .foregroundStyle(AppTheme.Child.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Pricing
                        VStack(spacing: 12) {
                            PriceRow(label: "Price", amount: item.priceCents.asCurrency)
                            PriceRow(label: "Tax (\(Int(appState.state.parentSettings.salesTax * 100))%)", amount: taxAmount.asCurrency)

                            Divider()
                                .background(AppTheme.Child.textSecondary.opacity(0.3))

                            PriceRow(label: "Total", amount: totalAmount.asCurrency, isTotal: true)
                        }
                        .padding(AppTheme.Child.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                .fill(AppTheme.Child.cardBackground.opacity(0.4))
                        )

                        // Payment Method
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Method")
                                .font(AppTheme.Child.headlineFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)

                            PaymentMethodButton(
                                method: .wallet,
                                balance: appState.state.walletBalanceFormatted,
                                isSelected: selectedPayment == .wallet
                            ) {
                                selectedPayment = .wallet
                            }

                            PaymentMethodButton(
                                method: .credit,
                                balance: "\(appState.state.utilization) used",
                                isSelected: selectedPayment == .credit
                            ) {
                                selectedPayment = .credit
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Link (optional)")
                                .font(AppTheme.Child.headlineFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)
                            TextField("Paste Amazon link", text: $link)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                        .fill(AppTheme.Child.cardBackground.opacity(0.4))
                                )
                            Text("Notes to parent (optional)")
                                .font(AppTheme.Child.headlineFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)
                            TextField("Why do you want this?", text: $notes)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                        .fill(AppTheme.Child.cardBackground.opacity(0.4))
                                )
                        }

                        // Buy Button
                        Button(action: {
                            showConfirm = true
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(isSubmitting ? "Requesting..." : "Request Approval")
                                    .font(AppTheme.Child.headlineFont)
                                Image(systemName: "arrow.right.circle.fill")
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
                        .disabled(isSubmitting)
                        if let submitError {
                            Text(submitError)
                                .font(AppTheme.Child.captionFont)
                                .foregroundStyle(AppTheme.Child.danger)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Child.textPrimary)
                }
            }
            .alert("Confirm Purchase?", isPresented: $showConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Buy!") {
                    Task { await submitRequest() }
                }
            } message: {
                Text("You're about to request \(totalAmount.asCurrency) for \(item.name)")
            }
            .alert("Request sent!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("We sent this to your parent for approval.")
            }
        }
    }

    private func submitRequest() async {
        guard let token = authManager.session?.accessToken else {
            submitError = "Missing session. Please sign in again."
            return
        }
        isSubmitting = true
        submitError = nil
        do {
            _ = try await PurchaseRequestAPI.shared.createRequest(
                accessToken: token,
                title: item.name,
                description: notes.isEmpty ? item.description : notes,
                url: link.isEmpty ? nil : link,
                imageUrl: nil,
                price: Double(totalAmount) / 100.0
            )
            showSuccess = true
        } catch {
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }
}

struct PriceRow: View {
    let label: String
    let amount: String
    var isTotal = false

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? AppTheme.Child.headlineFont : AppTheme.Child.bodyFont)
                .foregroundStyle(isTotal ? AppTheme.Child.textPrimary : AppTheme.Child.textSecondary)

            Spacer()

            Text(amount)
                .font(isTotal ? AppTheme.Child.titleFont : AppTheme.Child.headlineFont)
                .foregroundStyle(isTotal ? AppTheme.Child.accent : AppTheme.Child.textPrimary)
        }
    }
}

struct PaymentMethodButton: View {
    let method: PaymentMethod
    let balance: String
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        method == .wallet ? "wallet.pass.fill" : "creditcard.fill"
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? AppTheme.Child.accent : AppTheme.Child.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method == .wallet ? "Wallet" : "Credit Card")
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(AppTheme.Child.textPrimary)

                    Text(balance)
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Child.accent)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                    .fill(isSelected ? AppTheme.Child.cardBackground.opacity(0.6) : AppTheme.Child.cardBackground.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                            .stroke(isSelected ? AppTheme.Child.accent : AppTheme.Child.textSecondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
