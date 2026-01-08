import SwiftUI

struct EnhancedCreditCardsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedCard: CreditCard?
    @State private var showPaymentSheet = false
    @State private var showApplySheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Credit Score Section
                        if let score = appState.creditScore {
                            CreditScoreCard(score: score)
                        }
                        
                        // Cards Section
                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppTheme.Child.captionFont)
                                .foregroundStyle(AppTheme.Child.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if appState.creditCards.isEmpty {
                            emptyStateView
                        } else {
                            VStack(spacing: 16) {
                                Text("My Credit Cards")
                                    .font(AppTheme.Child.titleFont)
                                    .foregroundStyle(AppTheme.Child.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Card Carousel
                                TabView {
                                    ForEach(appState.creditCards) { card in
                                        CreditCardView(card: card) {
                                            selectedCard = card
                                            showPaymentSheet = true
                                        }
                                        .padding(.horizontal, 10)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .always))
                                .frame(height: 280)
                            }
                        }
                        
                        // Apply for New Card Button
                        Button(action: { showApplySheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(appState.creditCards.isEmpty ? "Apply for Your First Card" : "Apply for New Card")
                                    .font(AppTheme.Child.headlineFont)
                            }
                            .foregroundStyle(AppTheme.Child.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                    .fill(AppTheme.Child.cardBackground.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                            .stroke(AppTheme.Child.primary, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(AppTheme.Child.screenPadding)
                }
            }
            .navigationTitle("Credit Cards")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadCreditData()
            }
            .sheet(item: $selectedCard) { card in
                PaymentSheetView(card: card)
            }
            .sheet(isPresented: $showApplySheet) {
                ApplyCardView()
                    .environmentObject(appState)
                    .environmentObject(authManager)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Child.textSecondary.opacity(0.5))
            
            Text("No Credit Cards Yet")
                .font(AppTheme.Child.titleFont)
                .foregroundStyle(AppTheme.Child.textPrimary)
            
            Text("Apply for your first card to start building credit!")
                .font(AppTheme.Child.bodyFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func loadCreditData() async {
        guard let token = authManager.session?.accessToken else { return }
        isLoading = true
        async let cardsTask = appState.fetchCreditCards(accessToken: token, force: false)
        async let scoreTask = appState.fetchCreditScore(accessToken: token)
        _ = await (cardsTask, scoreTask)
        isLoading = false
    }
}

// MARK: - Credit Score Card

struct CreditScoreCard: View {
    let score: CreditScore
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credit Score")
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(AppTheme.Child.textSecondary)
                    
                    Text("\(score.creditScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(score.color)
                    
                    Text(score.grade)
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                        .foregroundStyle(score.color)
                }
                
                Spacer()
                
                // Score Meter
                ZStack {
                    Circle()
                        .stroke(AppTheme.Child.textSecondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score.creditScore - 300) / 550)
                        .stroke(score.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(score.creditScore)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(score.color)
                        Text("850")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Child.textSecondary)
                    }
                }
            }
            
            // Score Factors
            VStack(spacing: 8) {
                ScoreFactorRow(label: "Payment History", score: score.factors.paymentHistory, weight: "40%")
                ScoreFactorRow(label: "Utilization", score: score.factors.utilization, weight: "30%")
                ScoreFactorRow(label: "Credit Age", score: score.factors.creditAge, weight: "20%")
                ScoreFactorRow(label: "Credit Mix", score: score.factors.creditMix, weight: "10%")
            }
        }
        .padding(AppTheme.Child.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                .fill(AppTheme.Child.cardBackground.opacity(0.8))
        )
    }
}

struct ScoreFactorRow: View {
    let label: String
    let score: Int
    let weight: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
            
            Text(weight)
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary.opacity(0.6))
            
            Spacer()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Child.textSecondary.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor(score))
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                }
            }
            .frame(width: 80, height: 8)
            
            Text("\(score)")
                .font(AppTheme.Child.captionFont.weight(.semibold))
                .foregroundStyle(scoreColor(score))
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .blue }
        if score >= 40 { return .orange }
        return .red
    }
}

// MARK: - Credit Card View

struct CreditCardView: View {
    let card: CreditCard
    let onPayment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Tier
            HStack {
                Image(systemName: card.tier.icon)
                    .font(.title2)
                Text(card.tierConfig.name)
                    .font(AppTheme.Child.headlineFont)
                Spacer()
                if card.isPending {
                    Text("Pending")
                        .font(AppTheme.Child.captionFont)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange))
                }
            }
            .foregroundStyle(.white)
            
            Spacer()
            
            // Balance & Limit
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(.white.opacity(0.8))
                Text(card.balanceFormatted)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("of \(card.limitFormatted) limit")
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            // Utilization Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: geo.size.width * CGFloat(card.utilization) / 100)
                }
            }
            .frame(height: 6)
            
            // APR & Rewards
            HStack {
                VStack(alignment: .leading) {
                    Text("APR")
                        .font(AppTheme.Child.captionFont)
                    Text(card.aprFormatted)
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Rewards")
                        .font(AppTheme.Child.captionFont)
                    Text(card.rewardsFormatted)
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            
            // Payment Button
            if card.isActive && card.balance > 0 {
                Button(action: onPayment) {
                    Text("Make Payment")
                        .font(AppTheme.Child.bodyFont.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                        )
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: card.tier.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - Payment Sheet

struct PaymentSheetView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    let card: CreditCard
    
    @State private var paymentAmount: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.cardName)
                            .font(.headline)
                        Text("Current Balance: \(card.balanceFormatted)")
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                        Text("Available: \(card.availableCreditFormatted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Payment Amount") {
                    TextField("Amount", text: $paymentAmount)
                        .keyboardType(.decimalPad)
                    
                    Button("Pay Full Balance") {
                        paymentAmount = String(format: "%.2f", card.balance)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button("Make Payment") {
                        Task { await makePayment() }
                    }
                    .disabled(isProcessing || paymentAmount.isEmpty)
                }
            }
            .navigationTitle("Make Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func makePayment() async {
        guard let amount = Double(paymentAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard amount <= card.balance else {
            errorMessage = "Payment cannot exceed balance"
            return
        }
        
        guard let token = authManager.session?.accessToken else { return }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            try await appState.makePayment(accessToken: token, cardId: card.id, amount: amount)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
        }
    }
}

// MARK: - Apply Card View

struct ApplyCardView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isApplying = false
    @State private var errorMessage: String?
    @State private var selectedTier: CreditTier = .starter
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Apply for Credit Card")
                    .font(.title.bold())
                
                Text("Based on your credit score, you'll automatically be assigned the best tier you qualify for!")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                
                Picker("Preferred Tier", selection: $selectedTier) {
                    ForEach(CreditTier.allCases, id: \.self) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }
                .pickerStyle(.segmented)
                
                // Show tier info
                VStack(alignment: .leading, spacing: 16) {
                    TierInfoRow(tier: .starter)
                    TierInfoRow(tier: .builder)
                    TierInfoRow(tier: .strong)
                    TierInfoRow(tier: .elite)
                }
                .padding()
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                Button(action: { Task { await applyForCard() } }) {
                    if isApplying {
                        ProgressView()
                    } else {
                        Text("Submit Application")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isApplying)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func applyForCard() async {
        guard let token = authManager.session?.accessToken else { return }
        
        isApplying = true
        errorMessage = nil
        
        do {
            try await appState.applyForCreditCard(accessToken: token, tier: selectedTier)
            await appState.fetchCreditCards(accessToken: token, force: true)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isApplying = false
        }
    }
}

struct TierInfoRow: View {
    let tier: CreditTier
    
    var config: TierConfig {
        CreditTier.config(for: tier)
    }
    
    var body: some View {
        HStack {
            Image(systemName: tier.icon)
                .foregroundStyle(tier.gradientColors[0])
            VStack(alignment: .leading) {
                Text(tier.displayName)
                    .font(.headline)
                Text("\(config.limit.asCurrency) limit • \(String(format: "%.1f", config.apr))% APR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(config.minScore)-\(config.maxScore)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
    }
}