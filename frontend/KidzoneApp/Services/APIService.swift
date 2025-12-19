import Foundation

// MARK: - API Service for future backend integration
class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api" // Will be configurable
    
    private init() {}
    
    // Generic request method - ready for backend integration
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        // TODO: Implement actual HTTP requests
        // For now, this is a placeholder structure
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Add body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // TODO: Perform actual request
        throw APIError.notImplemented
    }
}

enum APIError: Error {
    case invalidURL
    case notImplemented
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case serverError(String)
}

