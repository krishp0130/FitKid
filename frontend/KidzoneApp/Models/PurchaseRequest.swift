import Foundation

enum PurchaseRequestStatus: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }

    var colorName: String {
        switch self {
        case .pending: return "warning"
        case .approved: return "success"
        case .rejected, .cancelled: return "danger"
        }
    }
}

struct PurchaseRequest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let url: String?
    let imageUrl: String?
    let price: Double
    let priceCents: Int
    let paymentMethod: String?
    let cardId: String?
    let cardName: String?
    let status: PurchaseRequestStatus
    let requesterId: String
    let requesterName: String?
    let createdAt: String
    let decidedAt: String?

    var priceFormatted: String { price.asCurrency }

    enum CodingKeys: String, CodingKey {
        case id, title, description, url, imageUrl, price, priceCents, status, requesterId, requesterName, createdAt, decidedAt
        case paymentMethod
        case cardId
        case cardName
        case priceCentsLegacy = "price_cents"
    }

    init(id: String, title: String, description: String?, url: String?, imageUrl: String?, price: Double, priceCents: Int, paymentMethod: String?, cardId: String?, cardName: String?, status: PurchaseRequestStatus, requesterId: String, requesterName: String?, createdAt: String, decidedAt: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.imageUrl = imageUrl
        self.price = price
        self.priceCents = priceCents
        self.paymentMethod = paymentMethod
        self.cardId = cardId
        self.cardName = cardName
        self.status = status
        self.requesterId = requesterId
        self.requesterName = requesterName
        self.createdAt = createdAt
        self.decidedAt = decidedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try? container.decode(String.self, forKey: .description)
        self.url = try? container.decode(String.self, forKey: .url)
        self.imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        if let price = try? container.decode(Double.self, forKey: .price) {
            self.price = price
            self.priceCents = Int(round(price * 100))
        } else if let cents = try? container.decode(Int.self, forKey: .priceCents) {
            self.priceCents = cents
            self.price = Double(cents) / 100.0
        } else if let legacyCents = try? container.decode(Int.self, forKey: .priceCentsLegacy) {
            self.priceCents = legacyCents
            self.price = Double(legacyCents) / 100.0
        } else {
            self.price = 0
            self.priceCents = 0
        }
        self.paymentMethod = try? container.decode(String.self, forKey: .paymentMethod)
        self.cardId = try? container.decode(String.self, forKey: .cardId)
        self.cardName = try? container.decode(String.self, forKey: .cardName)
        self.status = (try? container.decode(PurchaseRequestStatus.self, forKey: .status)) ?? .pending
        self.requesterId = (try? container.decode(String.self, forKey: .requesterId)) ?? ""
        self.requesterName = try? container.decode(String.self, forKey: .requesterName)
        self.createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        self.decidedAt = try? container.decode(String.self, forKey: .decidedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(url, forKey: .url)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(price, forKey: .price)
        try container.encode(priceCents, forKey: .priceCents)
        try container.encode(paymentMethod, forKey: .paymentMethod)
        try container.encode(cardId, forKey: .cardId)
        try container.encode(cardName, forKey: .cardName)
        try container.encode(status, forKey: .status)
        try container.encode(requesterId, forKey: .requesterId)
        try container.encode(requesterName, forKey: .requesterName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(decidedAt, forKey: .decidedAt)
    }
}
