import Foundation
import SwiftUI

// MARK: - Credit Card Models

struct CreditCard: Identifiable, Codable {
    let id: String
    let cardName: String
    let tier: CreditTier
    let limit: Double
    let balance: Double
    let apr: Double
    let rewardsRate: Double
    let openedAt: String?
    let lastPaymentAt: String?
    let status: CreditCardStatus
    let utilization: Int
    
    var limitFormatted: String { limit.asCurrency }
    var balanceFormatted: String { balance.asCurrency }
    var aprFormatted: String { "\(Int(apr * 100))%" }
    var rewardsFormatted: String { "\(Int(rewardsRate * 100))%" }
    var availableCredit: Double { limit - balance }
    var availableCreditFormatted: String { availableCredit.asCurrency }
    
    var tierConfig: TierConfig {
        CreditTier.config(for: tier)
    }
    
    var isActive: Bool { status == .active }
    var isPending: Bool { status == .pendingApproval }
}

struct CardApplication: Identifiable, Codable {
    let id: String
    let cardName: String
    let tier: CreditTier
    let limit: Double
    let requesterName: String?
    let createdAt: String
    let status: CreditCardStatus

    var limitFormatted: String { limit.asCurrency }
}

enum CreditTier: String, Codable, CaseIterable {
    case starter = "STARTER"
    case builder = "BUILDER"
    case strong = "STRONG"
    case elite = "ELITE"
    
    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .builder: return "Builder"
        case .strong: return "Strong"
        case .elite: return "Elite"
        }
    }
    
    var icon: String {
        switch self {
        case .starter: return "sparkles"
        case .builder: return "arrow.up.right"
        case .strong: return "bolt.fill"
        case .elite: return "crown.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .starter: return [Color.purple, Color.blue]
        case .builder: return [Color.blue, Color.green]
        case .strong: return [Color.green, Color.orange]
        case .elite: return [Color.orange, Color.purple]
        }
    }
    
    static func config(for tier: CreditTier) -> TierConfig {
        switch tier {
        case .starter:
            return TierConfig(
                name: "Starter Card",
                minScore: 300,
                maxScore: 579,
                limit: 75,   // lower limits for kids
                apr: 19.9,
                rewards: 0,
                gradientColors: [Color.purple, Color.blue]
            )
        case .builder:
            return TierConfig(
                name: "Builder Card",
                minScore: 580,
                maxScore: 669,
                limit: 150,
                apr: 14.9,
                rewards: 1,
                gradientColors: [Color.blue, Color.green]
            )
        case .strong:
            return TierConfig(
                name: "Strong Card",
                minScore: 670,
                maxScore: 739,
                limit: 300,
                apr: 9.9,
                rewards: 2,
                gradientColors: [Color.green, Color.orange]
            )
        case .elite:
            return TierConfig(
                name: "Elite Card",
                minScore: 740,
                maxScore: 850,
                limit: 600,
                apr: 5.9,
                rewards: 3,
                gradientColors: [Color.orange, Color.purple]
            )
        }
    }
}

struct TierConfig {
    let name: String
    let minScore: Int
    let maxScore: Int
    let limit: Double
    let apr: Double
    let rewards: Double
    let gradientColors: [Color]
}

enum CreditCardStatus: String, Codable {
    case active = "ACTIVE"
    case frozen = "FROZEN"
    case closed = "CLOSED"
    case pendingApproval = "PENDING_APPROVAL"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .frozen: return "Frozen"
        case .closed: return "Closed"
        case .pendingApproval: return "Pending Approval"
        }
    }
}

// MARK: - Credit Score

struct CreditScore: Codable {
    let creditScore: Int
    let factors: CreditScoreFactors
    let explanation: CreditScoreExplanation
    
    var grade: String {
        switch creditScore {
        case 740...850: return "Excellent"
        case 670...739: return "Good"
        case 580...669: return "Fair"
        case 300...579: return "Building"
        default: return "New"
        }
    }
    
    var color: Color {
        switch creditScore {
        case 740...850: return .green
        case 670...739: return .blue
        case 580...669: return .orange
        default: return .purple
        }
    }
}

struct CreditScoreFactors: Codable {
    let paymentHistory: Int
    let utilization: Int
    let creditAge: Int
    let creditMix: Int
}

struct CreditScoreExplanation: Codable {
    let paymentHistory: String
    let utilization: String
    let creditAge: String
    let creditMix: String
}

// MARK: - Credit Transaction

struct CreditTransaction: Identifiable, Codable {
    let id: String
    let amount: Double
    let type: TransactionType
    let description: String
    let merchant: String?
    let date: String
    
    var amountFormatted: String { 
        let prefix = type == .payment ? "+" : "-"
        return "\(prefix)\(abs(amount).asCurrency)"
    }
    
    var icon: String {
        switch type {
        case .purchase: return "cart.fill"
        case .payment: return "arrow.down.circle.fill"
        case .interest: return "percent"
        case .fee: return "exclamationmark.triangle.fill"
        case .reward: return "star.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .purchase, .interest, .fee: return .red
        case .payment, .reward, .refund: return .green
        }
    }
}

enum TransactionType: String, Codable {
    case purchase = "PURCHASE"
    case payment = "PAYMENT"
    case interest = "INTEREST"
    case fee = "FEE"
    case reward = "REWARD"
    case refund = "REFUND"
}

// MARK: - API Response Models

struct CreditCardsResponse: Codable {
    let cards: [CreditCard]
}

struct CreditScoreResponse: Codable {
    let creditScore: Int
    let factors: CreditScoreFactors
    let explanation: CreditScoreExplanation
}

struct CreditTransactionsResponse: Codable {
    let transactions: [CreditTransaction]
}

struct UpgradeEligibilityResponse: Codable {
    let eligible: Bool
    let currentTier: CreditTier
    let newTier: CreditTier?
    let creditScore: Int
}
