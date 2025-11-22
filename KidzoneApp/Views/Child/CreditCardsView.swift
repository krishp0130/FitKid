import SwiftUI

struct CreditCardsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedCard: CreditCardInstance?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.childGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("My Credit Cards")
                                .font(.system(.title, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                            
                            Text("Swipe to see all your cards")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
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
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        
                        // Card Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Card Benefits")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                            
                            ForEach(appState.state.cards) { card in
                                CardInfoRow(card: card)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
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
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(card.productName)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Tier Badge
                HStack(spacing: 4) {
                    Image(systemName: card.tierIcon)
                    Text(card.tierLabel)
                        .font(.system(.caption, design: .rounded).weight(.bold))
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
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.limitFormatted)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Used")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.balanceCents.asCurrency)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            
            // Utilization Bar
            ProgressView(value: card.utilization, total: 1.0) {
                Text("\(Int(card.utilization * 100))% Used")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }
            .tint(Color.kidzoneGreen)
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
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Text("\(card.company) • \(card.tierLabel)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
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
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Color.kidzoneYellow)
        }
    }
}

