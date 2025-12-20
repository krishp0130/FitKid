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

struct Chore: Identifiable, Codable {
    var id: String
    var title: String
    var detail: String
    var reward: Double // dollars
    var status: ChoreStatus
    var assigneeId: String?
    var assigneeName: String?
    var dueDate: String?
    var recurrenceType: String?
    var recurrenceConfig: String?

    var rewardFormatted: String { reward.asCurrency }
    
    var isRecurring: Bool {
        guard let recurrenceType = recurrenceType else { return false }
        return recurrenceType != "NONE" && !recurrenceType.isEmpty
    }
    
    var recurrenceLabel: String {
        switch recurrenceType {
        case "DAILY": return "Daily"
        case "WEEKLY": return "Weekly"
        case "MONTHLY": return "Monthly"
        default: return "One-time"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case detail
        case reward
        case rewardCents // tolerate legacy key
        case status
        case assigneeId
        case assigneeName
        case dueDate
        case recurrenceType
        case recurrenceConfig
    }

    init(id: String, title: String, detail: String, reward: Double, status: ChoreStatus, assigneeId: String?, assigneeName: String?, dueDate: String?, recurrenceType: String? = nil, recurrenceConfig: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.reward = reward
        self.status = status
        self.assigneeId = assigneeId
        self.assigneeName = assigneeName
        self.dueDate = dueDate
        self.recurrenceType = recurrenceType
        self.recurrenceConfig = recurrenceConfig
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.detail = (try? container.decode(String.self, forKey: .detail)) ?? ""
        // Be tolerant of numbers or strings for reward dollars
        if let dollars = try? container.decode(Double.self, forKey: .reward) {
            self.reward = dollars
        } else if let rewardString = try? container.decode(String.self, forKey: .reward), let dollars = Double(rewardString) {
            self.reward = dollars
        } else if let cents = try? container.decode(Int.self, forKey: .rewardCents) {
            self.reward = Double(cents) / 100.0
        } else if let centsString = try? container.decode(String.self, forKey: .rewardCents), let cents = Double(centsString) {
            self.reward = cents / 100.0
        } else {
            self.reward = 0
        }
        self.status = (try? container.decode(ChoreStatus.self, forKey: .status)) ?? .assigned
        self.assigneeId = try? container.decode(String.self, forKey: .assigneeId)
        self.assigneeName = try? container.decode(String.self, forKey: .assigneeName)
        self.dueDate = try? container.decode(String.self, forKey: .dueDate)
        self.recurrenceType = try? container.decode(String.self, forKey: .recurrenceType)
        self.recurrenceConfig = try? container.decode(String.self, forKey: .recurrenceConfig)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(detail, forKey: .detail)
        try container.encode(reward, forKey: .reward)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(assigneeId, forKey: .assigneeId)
        try container.encodeIfPresent(assigneeName, forKey: .assigneeName)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(recurrenceType, forKey: .recurrenceType)
        try container.encodeIfPresent(recurrenceConfig, forKey: .recurrenceConfig)
    }
}

enum ChoreStatus: String, Codable {
    case assigned = "ASSIGNED"
    case pendingApproval = "PENDING_APPROVAL"
    case completed = "COMPLETED"
    case rejected = "REJECTED"

    var label: String {
        switch self {
        case .assigned: return "Assigned"
        case .pendingApproval: return "Pending"
        case .completed: return "Completed"
        case .rejected: return "Rejected"
        }
    }
}

enum ChoreSegment: String, CaseIterable, Identifiable {
    case active
    case completed

    var id: String { rawValue }
}

struct ChorePreset: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let rewardDollars: Double
    let recurrenceType: String
    let suggestedDueDay: Int?
    
    var rewardFormatted: String { rewardDollars.asCurrency }
    
    var recurrenceLabel: String {
        switch recurrenceType {
        case "DAILY": return "Daily"
        case "WEEKLY": return "Weekly"
        case "MONTHLY": return "Monthly"
        default: return "One-time"
        }
    }
}

struct MarketplaceItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let priceCents: Int
    let tagline: String
    let description: String
    let isDigital: Bool
    
    var priceFormatted: String { priceCents.asCurrency }
}

struct Stock: Identifiable, Codable {
    let id = UUID()
    let ticker: String
    let company: String
    let value: Double
    let change: Double
    
    var valueFormatted: String { value.asCurrency }
    var changeFormatted: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))"
    }
    var changePercent: String {
        let percent = (change / value) * 100
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percent))%"
    }
}

struct ParentSettings: Codable {
    let salesTax: Double
    let penaltyPoints: Int
    let graceDays: Int
    let cashbackBonus: Double
    let deviceMinimumScore: Int
    let dailyHourCap: Int
}
