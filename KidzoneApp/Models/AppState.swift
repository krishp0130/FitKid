import Foundation

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
    var walletBalanceCents: Int

    var creditLineFormatted: String { creditLineCents.asCurrency }
    var walletBalanceFormatted: String { walletBalanceCents.asCurrency }
    
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
        parentSettings: .init(salesTax: 0.08, penaltyPoints: 25, graceDays: 3, cashbackBonus: 0.02, deviceMinimumScore: 650, dailyHourCap: 3),
        walletBalanceCents: 5000
    )
}

