import SwiftUI

struct CreditCardsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedCard: CreditCardInstance?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Child.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("My Credit Cards")
                                .font(AppTheme.Child.titleFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)

                            Text("Swipe to see all your cards")
                                .font(AppTheme.Child.bodyFont)
                                .foregroundStyle(AppTheme.Child.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Child.screenPadding)
                        .padding(.top, 10)
                        
                        // Card Carousel
                        TabView {
                            ForEach(appState.state.cards) { card in
                                CreditCardDetailView(card: card)
                                    .padding(.horizontal, 10)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 240)
                        
                        // Apply for New Card Button
                        Button(action: {
                            // TODO: Show card application
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Apply for New Card")
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
                        .padding(.horizontal, AppTheme.Child.screenPadding)

                        // Card Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Card Benefits")
                                .font(AppTheme.Child.headlineFont)
                                .foregroundStyle(AppTheme.Child.textPrimary)

                            ForEach(appState.state.cards) { card in
                                CardInfoRow(card: card)
                            }
                        }
                        .padding(AppTheme.Child.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Child.cornerRadius)
                                .fill(AppTheme.Child.cardBackground.opacity(0.4))
                        )
                        .padding(.horizontal, AppTheme.Child.screenPadding)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Credit Cards")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CreditCardDetailView: View {
    let card: CreditCardInstance

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.company)
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(card.productName)
                        .font(AppTheme.Child.titleFont)
                        .foregroundStyle(.white)
                }

                Spacer()

                // Tier Badge
                HStack(spacing: 4) {
                    Image(systemName: card.tierIcon)
                    Text(card.tierLabel)
                        .font(AppTheme.Child.captionFont.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
            }

            Spacer()

            // Card Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limit")
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.limitFormatted)
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Used")
                        .font(AppTheme.Child.captionFont)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.balanceCents.asCurrency)
                        .font(AppTheme.Child.headlineFont)
                        .foregroundStyle(.white)
                }

                Spacer()
            }

            // Utilization Bar
            ProgressView(value: card.utilization, total: 1.0) {
                Text("\(Int(card.utilization * 100))% Used")
                    .font(AppTheme.Child.captionFont.weight(.bold))
                    .foregroundStyle(.white)
            }
            .tint(AppTheme.Child.success)
            .background(Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            LinearGradient(colors: card.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct CardInfoRow: View {
    let card: CreditCardInstance

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.productName)
                    .font(AppTheme.Child.headlineFont)
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Text("\(card.company) • \(card.tierLabel)")
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 12) {
                    InfoBadge(label: "APR", value: card.aprFormatted)
                    InfoBadge(label: "Cashback", value: card.rewardFormatted)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct InfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
            Text(value)
                .font(AppTheme.Child.captionFont.weight(.bold))
                .foregroundStyle(AppTheme.Child.accent)
        }
    }
}

