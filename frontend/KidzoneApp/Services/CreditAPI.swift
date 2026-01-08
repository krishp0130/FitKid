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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
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
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let message = parseServerMessage(from: data) {
                throw CreditAPIError.serverMessage(message)
            }
            throw CreditAPIError.httpError(httpResponse.statusCode)
        }
    }

    private func parseServerMessage(from data: Data) -> String? {
        if data.isEmpty { return nil }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String, !message.isEmpty {
                return message
            }
            if let error = json["error"] as? String, !error.isEmpty {
                return error
            }
        }
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }
}

enum CreditAPIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError
    case serverMessage(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "We couldn't reach the server. Please try again."
        case .httpError(let code):
            switch code {
            case 400:
                return "Something looks off. Please try again."
            case 401:
                return "Please sign in again to continue."
            case 403:
                return "You don't have permission to do that."
            case 404:
                return "We couldn't find what you were looking for."
            case 409:
                return "That request conflicts with your account right now."
            case 429:
                return "Too many attempts. Please try again later."
            default:
                return "Something went wrong. Please try again."
            }
        case .decodingError:
            return "We couldn't read the server response. Please try again."
        case .serverMessage(let msg):
            return msg
        }
    }
}
