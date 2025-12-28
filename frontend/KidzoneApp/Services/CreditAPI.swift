import Foundation

class CreditAPI {
    static let shared = CreditAPI()
    private let baseURL = "http://localhost:3000"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - Credit Score
    
    func getCreditScore(accessToken: String) async throws -> CreditScore {
        let url = URL(string: "\(baseURL)/api/credit/score")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(CreditScore.self, from: data)
    }
    
    // MARK: - Credit Cards
    
    func getCreditCards(accessToken: String) async throws -> [CreditCard] {
        let url = URL(string: "\(baseURL)/api/credit/cards")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        let result = try decoder.decode(CreditCardsResponse.self, from: data)
        return result.cards
    }
    
    func applyForCreditCard(accessToken: String, requestedTier: CreditTier? = nil) async throws -> CreditCard {
        let url = URL(string: "\(baseURL)/api/credit/apply")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let tier = requestedTier {
            let body = ["requestedTier": tier.rawValue]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        struct ApplyResponse: Codable {
            let card: CreditCard
            let message: String
        }
        let result = try decoder.decode(ApplyResponse.self, from: data)
        return result.card
    }
    
    // MARK: - Transactions
    
    func makePurchase(accessToken: String, cardId: String, amountDollars: Double, description: String, merchant: String?) async throws {
        let url = URL(string: "\(baseURL)/api/credit/purchase")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "cardId": cardId,
            "amountCents": Int(amountDollars * 100),
            "description": description,
            "merchant": merchant ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
    }
    
    func makePayment(accessToken: String, cardId: String, amountDollars: Double) async throws {
        let url = URL(string: "\(baseURL)/api/credit/payment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "cardId": cardId,
            "amountCents": Int(amountDollars * 100)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
    }
    
    func getTransactions(accessToken: String, cardId: String) async throws -> [CreditTransaction] {
        let url = URL(string: "\(baseURL)/api/credit/transactions/\(cardId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        let result = try decoder.decode(CreditTransactionsResponse.self, from: data)
        return result.transactions
    }
    
    // MARK: - Tier Management
    
    func checkUpgradeEligibility(accessToken: String, cardId: String) async throws -> UpgradeEligibilityResponse {
        let url = URL(string: "\(baseURL)/api/credit/upgrade/\(cardId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(UpgradeEligibilityResponse.self, from: data)
    }
    
    func upgradeTier(accessToken: String, cardId: String) async throws -> CreditCard {
        let url = URL(string: "\(baseURL)/api/credit/upgrade/\(cardId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
        
        struct UpgradeResponse: Codable {
            let card: CreditCard
            let message: String
        }
        let result = try decoder.decode(UpgradeResponse.self, from: data)
        return result.card
    }
    
    // MARK: - Parent Controls
    
    func approveCard(accessToken: String, cardId: String) async throws {
        let url = URL(string: "\(baseURL)/api/credit/approve/\(cardId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
    }
}

enum CreditAPIError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}


