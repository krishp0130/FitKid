import Foundation

enum PurchaseRequestAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case decoding(Error)
    case server(String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request endpoint."
        case .unauthorized: return "Unauthorized. Please sign in again."
        case .decoding: return "Unable to read requests."
        case .server(let msg): return msg
        case .network(let err): return err.localizedDescription
        }
    }
}

final class PurchaseRequestAPI {
    static let shared = PurchaseRequestAPI()
    private let session: URLSession
    private let baseURLString: String
    private let decoder = JSONDecoder()

    init(baseURLString: String = "http://localhost:3000/api/requests", session: URLSession = .shared) {
        self.baseURLString = baseURLString
        self.session = session
    }

    func fetchRequests(accessToken: String) async throws -> [PurchaseRequest] {
        guard let url = URL(string: baseURLString) else { throw PurchaseRequestAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PurchaseRequestAPIError.invalidURL }
        switch http.statusCode {
        case 200:
            struct Wrapper: Codable { let requests: [PurchaseRequest] }
            do { return try decoder.decode(Wrapper.self, from: data).requests } catch { throw PurchaseRequestAPIError.decoding(error) }
        case 401: throw PurchaseRequestAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PurchaseRequestAPIError.server(msg)
        }
    }

    func createRequest(accessToken: String, title: String, description: String?, url: String?, imageUrl: String?, price: Double) async throws -> PurchaseRequest {
        guard let endpoint = URL(string: baseURLString) else { throw PurchaseRequestAPIError.invalidURL }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any?] = [
            "title": title,
            "description": description,
            "url": url,
            "imageUrl": imageUrl,
            "price": price
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PurchaseRequestAPIError.invalidURL }
        switch http.statusCode {
        case 200, 201:
            struct Wrapper: Codable { let request: PurchaseRequest }
            do { return try decoder.decode(Wrapper.self, from: data).request } catch { throw PurchaseRequestAPIError.decoding(error) }
        case 401: throw PurchaseRequestAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PurchaseRequestAPIError.server(msg)
        }
    }

    func updateStatus(accessToken: String, id: String, action: String) async throws -> PurchaseRequest {
        guard let url = URL(string: "\(baseURLString)/\(id)/\(action)") else { throw PurchaseRequestAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PurchaseRequestAPIError.invalidURL }
        switch http.statusCode {
        case 200:
            struct Wrapper: Codable { let request: PurchaseRequest }
            do { return try decoder.decode(Wrapper.self, from: data).request } catch { throw PurchaseRequestAPIError.decoding(error) }
        case 401: throw PurchaseRequestAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PurchaseRequestAPIError.server(msg)
        }
    }

    func approve(accessToken: String, id: String) async throws -> PurchaseRequest {
        try await updateStatus(accessToken: accessToken, id: id, action: "approve")
    }

    func reject(accessToken: String, id: String) async throws -> PurchaseRequest {
        try await updateStatus(accessToken: accessToken, id: id, action: "reject")
    }
}
