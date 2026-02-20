import Foundation

enum MoneyAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case decoding(Error)
    case server(String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid wallet endpoint."
        case .unauthorized: return "Unauthorized."
        case .decoding: return "Unable to read wallet data."
        case .server(let msg): return msg
        case .network(let err): return err.localizedDescription
        }
    }
}

final class MoneyAPI {
    static let shared = MoneyAPI()
    private let baseURLString: String
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(baseURLString: String = "http://localhost:3001/api/wallet", session: URLSession = .shared) {
        self.baseURLString = baseURLString
        self.session = session
    }

    func fetchWalletBalance(accessToken: String) async throws -> Int {
        guard let url = URL(string: baseURLString) else { throw MoneyAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MoneyAPIError.invalidURL }
        switch http.statusCode {
        case 200:
            struct Wrapper: Codable { let balanceCents: Int }
            do { return try decoder.decode(Wrapper.self, from: data).balanceCents } catch { throw MoneyAPIError.decoding(error) }
        case 401: throw MoneyAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MoneyAPIError.server(msg)
        }
    }
}
