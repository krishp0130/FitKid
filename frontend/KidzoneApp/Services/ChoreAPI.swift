import Foundation

enum ChoreAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case decoding(Error)
    case server(String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid chore endpoint."
        case .unauthorized: return "Unauthorized. Please sign in again."
        case .decoding: return "Unable to read chores data."
        case .server(let msg): return msg
        case .network(let err): return err.localizedDescription
        }
    }
}

final class ChoreAPI {
    static let shared = ChoreAPI()
    private let session: URLSession
    private let baseURLString: String
    private let decoder = JSONDecoder()

    init(baseURLString: String = "http://localhost:3000/api/chores", session: URLSession = .shared) {
        self.baseURLString = baseURLString
        self.session = session
    }

    func fetchChores(accessToken: String) async throws -> [Chore] {
        guard let url = URL(string: baseURLString) else { throw ChoreAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChoreAPIError.invalidURL }
        switch http.statusCode {
        case 200:
            struct Wrapper: Codable { let chores: [Chore] }
            do { return try decoder.decode(Wrapper.self, from: data).chores } catch { throw ChoreAPIError.decoding(error) }
        case 401: throw ChoreAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChoreAPIError.server(msg)
        }
    }

    func createChore(accessToken: String, assigneeId: String, title: String, detail: String, rewardDollars: Double, dueDateISO: String?) async throws -> Chore {
        guard let url = URL(string: baseURLString) else { throw ChoreAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "assigneeId": assigneeId,
            "title": title,
            "description": detail,
            "reward": rewardDollars,
            "dueDate": dueDateISO as Any
        ].compactMapValues { $0 }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChoreAPIError.invalidURL }
        switch http.statusCode {
        case 200, 201:
            struct Wrapper: Codable { let chore: Chore }
            do { return try decoder.decode(Wrapper.self, from: data).chore } catch { throw ChoreAPIError.decoding(error) }
        case 401: throw ChoreAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChoreAPIError.server(msg)
        }
    }

    func submitChore(accessToken: String, choreId: String) async throws -> Chore {
        try await updateStatus(accessToken: accessToken, choreId: choreId, action: "submit")
    }

    func approveChore(accessToken: String, choreId: String) async throws -> Chore {
        try await updateStatus(accessToken: accessToken, choreId: choreId, action: "approve")
    }

    func rejectChore(accessToken: String, choreId: String) async throws -> Chore {
        try await updateStatus(accessToken: accessToken, choreId: choreId, action: "reject")
    }

    private func updateStatus(accessToken: String, choreId: String, action: String) async throws -> Chore {
        guard let url = URL(string: "\(baseURLString)/\(choreId)/\(action)") else { throw ChoreAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChoreAPIError.invalidURL }
        switch http.statusCode {
        case 200:
            struct Wrapper: Codable { let chore: Chore }
            do { return try decoder.decode(Wrapper.self, from: data).chore } catch { throw ChoreAPIError.decoding(error) }
        case 401: throw ChoreAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChoreAPIError.server(msg)
        }
    }
}
