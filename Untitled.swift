import SwiftUI

@main
struct KidzoneFinanceApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView(state: .mock)
        }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @State var state: AppState
    @State private var showsParentPanel = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [.nightBlue, .spacePurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    creditScore
                    cardCarousel
                    chores
                    marketplace
                    paperTrading
                    deviceHours
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            parentButton
        }
        .sheet(isPresented: $showsParentPanel) {
            ParentPanelView(settings: state.parentSettings)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kidzone")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)

            Text("Credit, chores, and rewards in one loop.")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.top, 36)
    }

    private var creditScore: some View {
        SectionCard(title: "Credit Score", subtitle: "Unlock better cards and perks") {
            HStack(spacing: 16) {
                CircularGauge(value: Double(state.creditScore), maxValue: 850)
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("\(state.creditScore)")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        ScoreBadge(score: state.creditScore)
                    }

                    Text("Pay on time, keep balances low, and watch privileges grow.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 12) {
                        MetricPill(label: "Credit Line", value: state.creditLineFormatted)
                        MetricPill(label: "Utilization", value: state.utilization)
                    }
                }
            }
        }
    }

    private var cardCarousel: some View {
        SectionCard(title: "Card Tiers", subtitle: "Qualify based on your score") {
            TabView {
                ForEach(state.cards) { card in
                    CreditCardView(card: card)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 210)
        }
    }

    private var chores: some View {
        SectionCard(title: "Chores Marketplace", subtitle: "Complete tasks to earn") {
            VStack(spacing: 12) {
                ForEach(state.chores) { chore in
                    ChoreRow(chore: chore)
                }
            }
        }
    }

    private var marketplace: some View {
        SectionCard(title: "Rewards & Marketplace", subtitle: "Tax auto-applied at checkout") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(state.marketItems) { item in
                    MarketplaceTile(item: item, taxRate: state.parentSettings.salesTax)
                }
            }
        }
    }

    private var paperTrading: some View {
        SectionCard(title: "Paper Trading", subtitle: "Practice investing risk-free") {
            VStack(spacing: 10) {
                ForEach(state.stocks) { stock in
                    StockRow(stock: stock)
                }
            }
        }
    }

    private var deviceHours: some View {
        SectionCard(title: "Device Hours", subtitle: "Screen time tied to financial health") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Available", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.white)
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                    Text(state.deviceHours.formatted())
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(.emerald)
                }

                ProgressView(value: state.deviceHealth, total: 1.0)
                    .tint(.emerald)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Good standing keeps access. Late payments or high debt can pause gaming time.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var parentButton: some View {
        Button {
            showsParentPanel = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                Text("Parent Controls")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .padding(.leading, 20)
        .padding(.top, 12)
        .tint(.white)
    }
}

// MARK: - Components

struct SectionCard<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }

            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CircularGauge: View {
    var value: Double
    var maxValue: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: value / maxValue)
                .stroke(AngularGradient(colors: [.emerald, .skyBlue, .sunrise], center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("Score")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(String(Int(value)))
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}

struct ScoreBadge: View {
    var score: Int

    var label: String {
        switch score {
        case ..<580: return "Risky"
        case 580..<670: return "Building"
        case 670..<740: return "Strong"
        case 740..<800: return "Prime"
        default: return "Elite"
        }
    }

    var color: Color {
        switch score {
        case ..<580: return .sunrise
        case 580..<670: return .amber
        case 670..<740: return .skyBlue
        case 740..<800: return .emerald
        default: return .purple
        }
    }

    var body: some View {
        Text(label.uppercased())
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.65))
            .clipShape(Capsule())
    }
}

struct MetricPill: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }
}

struct CreditCardView: View {
    var card: CreditCardInstance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                Label(card.tierLabel, systemImage: card.tierIcon)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limit")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.limitFormatted)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("APR")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.aprFormatted)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cashback")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(card.rewardFormatted)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                }
            }

            ProgressView(value: card.utilization, total: 1.0) {
                Text("Utilization \(Int(card.utilization * 100))%")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .tint(.emerald)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: card.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: card.gradient.first?.opacity(0.35) ?? .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }
}

struct ChoreRow: View {
    var chore: Chore

    var statusColor: Color {
        switch chore.status {
        case .pending: return .amber
        case .approved: return .emerald
        case .overdue: return .sunrise
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                Text(chore.detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(chore.rewardFormatted)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.emerald)
                Text(chore.status.label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MarketplaceTile: View {
    var item: MarketplaceItem
    var taxRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(item.tagline)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(item.description)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))

            HStack {
                Text(item.priceFormatted)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.emerald)

                Spacer()

                Text("Tax \(Int(taxRate * 100))%")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StockRow: View {
    var stock: Stock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.ticker)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                Text(stock.company)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.valueFormatted)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.emerald)
                Label(stock.changeText, systemImage: stock.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(stock.change >= 0 ? .emerald : .sunrise)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ParentPanelView: View {
    var settings: ParentSettings

    var body: some View {
        NavigationView {
            Form {
                Section("Credit Rules") {
                    LabeledContent("Penalty", value: "\(settings.penaltyPoints) pts")
                    LabeledContent("Grace Period", value: "\(settings.graceDays) days")
                }

                Section("Taxes & Rewards") {
                    LabeledContent("Sales Tax", value: "\(Int(settings.salesTax * 100))%")
                    LabeledContent("Cashback Boost", value: "\(Int(settings.cashbackBonus * 100))%")
                }

                Section("Device Hours") {
                    LabeledContent("Score Required", value: "\(settings.deviceMinimumScore)")
                    LabeledContent("Daily Cap", value: "\(settings.dailyHourCap) hrs")
                }
            }
            .navigationTitle("Parent Controls")
        }
    }
}

// MARK: - Models

struct AppState {
    var creditScore: Int
    var cards: [CreditCardInstance]
    var chores: [Chore]
    var marketItems: [MarketplaceItem]
    var stocks: [Stock]
    var deviceHours: Double
    var creditLineCents: Int
    var balanceCents: Int
    var parentSettings: ParentSettings

    var creditLineFormatted: String { creditLineCents.asCurrency }
    var utilization: String {
        let ratio = Double(balanceCents) / Double(max(creditLineCents, 1))
        return "\(Int(ratio * 100))%"
    }

    var deviceHealth: Double {
        let scoreRatio = Double(creditScore) / 850.0
        let utilizationRatio = min(Double(balanceCents) / Double(max(creditLineCents, 1)), 1.0)
        return max(scoreRatio * 0.7 + (1 - utilizationRatio) * 0.3, 0)
    }

    static let mock = AppState(
        creditScore: 712,
        cards: [
            .init(company: "Galaxy Bank", productName: "Starter Orbit", tierLabel: "Tier 1", tierIcon: "sparkles", limitCents: 40000, apr: 0.199, rewards: 0.0, balanceCents: 9000, gradient: [.spacePurple, .nightBlue]),
            .init(company: "Future Finance", productName: "Reward Beam", tierLabel: "Tier 2", tierIcon: "arrow.triangle.branch", limitCents: 90000, apr: 0.129, rewards: 0.03, balanceCents: 18000, gradient: [.skyBlue, .emerald]),
            .init(company: "Nova Credit", productName: "Elite Nebula", tierLabel: "Tier 3", tierIcon: "crown.fill", limitCents: 150000, apr: 0.079, rewards: 0.05, balanceCents: 0, gradient: [.sunrise, .purple])
        ],
        chores: [
            .init(title: "Clean your desk", detail: "Tidy workspace before homework", rewardCents: 1200, status: .pending),
            .init(title: "Math practice", detail: "30 mins of Khan Academy", rewardCents: 1500, status: .approved),
            .init(title: "Laundry fold", detail: "Fold and put away clothes", rewardCents: 1000, status: .overdue)
        ],
        marketItems: [
            .init(name: "30m Device Hours", priceCents: 900, tagline: "Digital", description: "Unlock half an hour of games.", isDigital: true),
            .init(name: "Movie Night", priceCents: 2400, tagline: "Experience", description: "Pick one streaming movie.", isDigital: false),
            .init(name: "Lego Set", priceCents: 5200, tagline: "Physical", description: "Parent-approved pickup", isDigital: false),
            .init(name: "VIP Paper Trade", priceCents: 3000, tagline: "Premium", description: "Unlock big-ticket stocks instantly.", isDigital: true)
        ],
        stocks: [
            .init(ticker: "KIDZ", company: "Kidzone Index", value: 134.22, change: 2.3),
            .init(ticker: "GROW", company: "Growth Labs", value: 58.11, change: -1.8),
            .init(ticker: "STEM", company: "STEM Heroes", value: 92.40, change: 0.7)
        ],
        deviceHours: 2.5,
        creditLineCents: 90000,
        balanceCents: 18000,
        parentSettings: .init(salesTax: 0.08, penaltyPoints: 25, graceDays: 3, cashbackBonus: 0.02, deviceMinimumScore: 650, dailyHourCap: 3)
    )
}

struct CreditCardInstance: Identifiable {
    let id = UUID()
    var company: String
    var productName: String
    var tierLabel: String
    var tierIcon: String
    var limitCents: Int
    var apr: Double
    var rewards: Double
    var balanceCents: Int
    var gradient: [Color]

    var limitFormatted: String { limitCents.asCurrency }
    var aprFormatted: String { "\(Int(apr * 100))%" }
    var rewardFormatted: String { "\(Int(rewards * 100))%" }
    var utilization: Double { Double(balanceCents) / Double(max(limitCents, 1)) }
}

struct Chore: Identifiable {
    var id = UUID()
    var title: String
    var detail: String
    var rewardCents: Int
    var status: Status

    var rewardFormatted: String { rewardCents.asCurrency }

    enum Status {
        case pending, approved, overdue

        var label: String {
            switch self {
            case .pending: return "Pending"
            case .approved: return "Cleared"
            case .overdue: return "Overdue"
            }
        }
    }
}

struct MarketplaceItem: Identifiable {
    var id = UUID()
    var name: String
    var priceCents: Int
    var tagline: String
    var description: String
    var isDigital: Bool

    var priceFormatted: String { priceCents.asCurrency }
}

struct Stock: Identifiable {
    var id = UUID()
    var ticker: String
    var company: String
    var value: Double
    var change: Double

    var valueFormatted: String { "$\(String(format: "%.2f", value))" }
    var changeText: String { "\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%" }
}

struct ParentSettings {
    var salesTax: Double
    var penaltyPoints: Int
    var graceDays: Int
    var cashbackBonus: Double
    var deviceMinimumScore: Int
    var dailyHourCap: Int
}

// MARK: - Helpers

extension Int {
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self / 100)) ?? "$0"
    }
}

extension Double {
    func formatted() -> String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self)) hrs"
        }
        return "\(String(format: "%.1f", self)) hrs"
    }
}

extension Color {
    static let nightBlue = Color(red: 16/255, green: 28/255, blue: 54/255)
    static let spacePurple = Color(red: 66/255, green: 44/255, blue: 101/255)
    static let sunrise = Color(red: 255/255, green: 131/255, blue: 96/255)
    static let emerald = Color(red: 54/255, green: 193/255, blue: 149/255)
    static let skyBlue = Color(red: 89/255, green: 196/255, blue: 255/255)
    static let amber = Color(red: 255/255, green: 199/255, blue: 94/255)
}
