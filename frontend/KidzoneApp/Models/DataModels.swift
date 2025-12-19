import Foundation
import SwiftUI

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
    var status: ChoreStatus

    var rewardFormatted: String { rewardCents.asCurrency }

    enum ChoreStatus {
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

struct FamilyMember: Identifiable {
    let id: String
    var username: String
    var email: String?
    var role: UserRole
    var currentCreditScore: Int
}

