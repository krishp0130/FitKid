import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedItem: MarketplaceItem?
    @State private var showPurchaseSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(appState.state.marketItems) { item in
                            MarketplaceItemCard(item: item) {
                                selectedItem = item
                                showPurchaseSheet = true
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedItem) { item in
                PurchaseView(item: item)
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
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
                
                Text(item.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                HStack {
                    Text(item.priceFormatted)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.kidzoneYellow)
                    
                    Spacer()
                    
                    if item.isDigital {
                        Image(systemName: "iphone")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(16)
            .frame(height: 180)
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

struct PurchaseView: View {
    let item: MarketplaceItem
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedPayment: PaymentMethod = .wallet
    @State private var showConfirm = false
    
    var taxAmount: Int {
        Int(Double(item.priceCents) * appState.state.parentSettings.salesTax)
    }
    
    var totalAmount: Int {
        item.priceCents + taxAmount
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Item Image/Icon
                        Image(systemName: item.isDigital ? "iphone" : "gift.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.kidzoneYellow)
                        
                        // Item Info
                        VStack(spacing: 8) {
                            Text(item.name)
                                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                            
                            Text(item.description)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Pricing
                        VStack(spacing: 12) {
                            PriceRow(label: "Price", amount: item.priceCents.asCurrency)
                            PriceRow(label: "Tax (\(Int(appState.state.parentSettings.salesTax * 100))%)", amount: taxAmount.asCurrency)
                            
                            Divider()
                                .background(.white.opacity(0.3))
                            
                            PriceRow(label: "Total", amount: totalAmount.asCurrency, isTotal: true)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                        )
                        
                        // Payment Method
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Method")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(.white)
                            
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
                        
                        // Buy Button
                        Button(action: {
                            showConfirm = true
                        }) {
                            HStack {
                                Text("Buy Now")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                Image(systemName: "arrow.right.circle.fill")
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
                    .foregroundStyle(.white)
                }
            }
            .alert("Confirm Purchase?", isPresented: $showConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Buy!") {
                    // TODO: Process purchase
                    dismiss()
                }
            } message: {
                Text("You're about to spend \(totalAmount.asCurrency) on \(item.name)")
            }
        }
    }
}

struct PriceRow: View {
    let label: String
    let amount: String
    var isTotal = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(isTotal ? .headline : .body, design: .rounded))
                .foregroundStyle(.white.opacity(isTotal ? 1.0 : 0.8))
            
            Spacer()
            
            Text(amount)
                .font(.system(isTotal ? .title2 : .headline, design: .rounded).weight(.bold))
                .foregroundStyle(isTotal ? Color.kidzoneYellow : .white)
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
                    .foregroundStyle(isSelected ? Color.kidzoneYellow : .white.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method == .wallet ? "Wallet" : "Credit Card")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(balance)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.kidzoneYellow)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.kidzoneYellow : .white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

