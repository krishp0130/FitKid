import Foundation

enum AuthAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(String)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Auth endpoint is misconfigured."
        case .invalidResponse: return "Received an unexpected response from the server."
        case .unauthorized: return "Your session is not authorized."
        case .server(let message): return message
        case .decoding: return "Unable to read the server response."
        case .network(let error): return error.localizedDescription
        }
    }
}

// Handles token exchange with the backend (e.g., Supabase edge function or BFF).
final class AuthAPI {
    static let shared = AuthAPI()

    private let decoder = JSONDecoder()
    private let session: URLSession
    private let baseURLString: String

    init(
        baseURLString: String = "http://localhost:3000/api/auth", // change here if hitting a device: e.g., http://YOUR-MAC-IP:3000/api/auth
        session: URLSession = .shared
    ) {
        self.baseURLString = baseURLString
        self.session = session
    }

    func exchangeAppleToken(idToken: String, nonce: String) async throws -> AuthSession {
        guard let url = URL(string: "\(baseURLString)/apple") else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "idToken": idToken,
            "nonce": nonce
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    return try decoder.decode(AuthSession.self, from: data)
                } catch {
                    throw AuthAPIError.decoding(error)
                }
            case 401:
                throw AuthAPIError.unauthorized
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }

    func exchangeGoogleToken(idToken: String) async throws -> AuthSession {
        guard let url = URL(string: "\(baseURLString)/google") else {
            throw AuthAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["idToken": idToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    return try decoder.decode(AuthSession.self, from: data)
                } catch {
                    throw AuthAPIError.decoding(error)
                }
            case 401:
                throw AuthAPIError.unauthorized
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }
}
