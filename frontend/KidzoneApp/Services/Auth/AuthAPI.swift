import Foundation

enum AuthAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(String)
    case decoding(Error)
    case network(Error)

    /// User-friendly message for connection/backend issues
    private static let backendUnavailableMessage = "Can't reach the server. Start the backend in Terminal:\n\ncd FitKid/backend\nnpm run dev\n\n(Server runs on port 3001.)"

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Auth endpoint is misconfigured."
        case .invalidResponse: return "Received an unexpected response from the server."
        case .unauthorized: return "Your session is not authorized."
        case .server(let message):
            if message.contains("Cannot POST") || message.contains("<!DOCTYPE") || message.contains("404") {
                return Self.backendUnavailableMessage
            }
            return message
        case .decoding: return "Unable to read the server response."
        case .network(let error):
            let ns = error as NSError
            // Connection refused (POSIX 61) or URLSession "cannot connect to host"
            if ns.domain == NSPOSIXErrorDomain && ns.code == 61 { return Self.backendUnavailableMessage }
            if ns.domain == NSURLErrorDomain && (ns.code == NSURLErrorCannotConnectToHost || ns.code == -1022) { // -1022 = connection refused
                return Self.backendUnavailableMessage
            }
            if error.localizedDescription.lowercased().contains("refused") {
                return Self.backendUnavailableMessage
            }
            return error.localizedDescription
        }
    }
}

// Handles token exchange with the backend (e.g., Supabase edge function or BFF).
final class AuthAPI {
    static let shared = AuthAPI()

    private let decoder = JSONDecoder()
    private let session: URLSession
    private let authBaseURLString: String
    private let onboardBaseURLString: String

    init(
        authBaseURLString: String = "http://localhost:3001/api/auth", // change here if hitting a device: e.g., http://YOUR-MAC-IP:3001/api/auth
        onboardBaseURLString: String = "http://localhost:3001/api/onboard",
        session: URLSession = .shared
    ) {
        self.authBaseURLString = authBaseURLString
        self.onboardBaseURLString = onboardBaseURLString
        self.session = session
    }

    func exchangeAppleToken(idToken: String, nonce: String) async throws -> AuthSessionResponse {
        guard let url = URL(string: "\(authBaseURLString)/apple") else {
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
                    return try decoder.decode(AuthSessionResponse.self, from: data)
                } catch let decodingError {
                    // Log the actual response for debugging
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to convert response to string"
                    print("❌ Failed to decode Apple response: \(decodingError)")
                    print("📄 Response body: \(responseString)")
                    throw AuthAPIError.server("Invalid response format: \(responseString)")
                }
            case 401:
                // Try to extract the actual error message from the response
                if let errorMessage = String(data: data, encoding: .utf8), !errorMessage.isEmpty {
                    throw AuthAPIError.server(errorMessage)
                }
                throw AuthAPIError.unauthorized
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Unexpected status code \(httpResponse.statusCode): \(message)")
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }

    func exchangeGoogleToken(idToken: String) async throws -> AuthSessionResponse {
        guard let url = URL(string: "\(authBaseURLString)/google") else {
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
                    return try decoder.decode(AuthSessionResponse.self, from: data)
                } catch let decodingError {
                    // Log the actual response for debugging
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to convert response to string"
                    print("❌ Failed to decode Google response: \(decodingError)")
                    print("📄 Response body: \(responseString)")
                    print("📄 Status code: \(httpResponse.statusCode)")
                    throw AuthAPIError.server("Invalid response format: \(responseString)")
                }
            case 401:
                // Try to extract the actual error message from the response
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unauthorized"
                print("❌ 401 Unauthorized: \(errorMessage)")
                throw AuthAPIError.server(errorMessage)
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Unexpected status code \(httpResponse.statusCode): \(message)")
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }

    // Onboarding
    func onboardParent(familyName: String, username: String, accessToken: String) async throws -> User {
        guard let url = URL(string: "\(onboardBaseURLString)/parent") else {
            throw AuthAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = ["familyName": familyName, "username": username]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            let wrapper = try decoder.decode(OnboardResponse.self, from: data)
            return wrapper.user
        case 401:
            throw AuthAPIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthAPIError.server(message)
        }
    }

    func onboardChild(familyId: String, username: String, accessToken: String) async throws -> User {
        guard let url = URL(string: "\(onboardBaseURLString)/child") else {
            throw AuthAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = ["familyId": familyId, "username": username]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            let wrapper = try decoder.decode(OnboardResponse.self, from: data)
            return wrapper.user
        case 401:
            throw AuthAPIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthAPIError.server(message)
        }
    }

    // Email/Password Authentication
    func signInWithEmail(email: String, password: String) async throws -> AuthSessionResponse {
        guard let url = URL(string: "\(authBaseURLString)/email") else {
            throw AuthAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "email": email,
            "password": password
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
                    return try decoder.decode(AuthSessionResponse.self, from: data)
                } catch let decodingError {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to convert response to string"
                    print("❌ Failed to decode email sign-in response: \(decodingError)")
                    print("📄 Response body: \(responseString)")
                    throw AuthAPIError.server("Invalid response format: \(responseString)")
                }
            case 401:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Invalid email or password"
                throw AuthAPIError.server(errorMessage)
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> AuthSessionResponse {
        guard let url = URL(string: "\(authBaseURLString)/email/signup") else {
            throw AuthAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                do {
                    return try decoder.decode(AuthSessionResponse.self, from: data)
                } catch let decodingError {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to convert response to string"
                    print("❌ Failed to decode email sign-up response: \(decodingError)")
                    print("📄 Response body: \(responseString)")
                    throw AuthAPIError.server("Invalid response format: \(responseString)")
                }
            case 400, 409:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Email already exists or invalid data"
                throw AuthAPIError.server(errorMessage)
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthAPIError.server(message)
            }
        } catch {
            throw AuthAPIError.network(error)
        }
    }

    // Family members
    func fetchFamilyMembers(accessToken: String) async throws -> [User] {
        guard let url = URL(string: "\(authBaseURLString)/family/members") else {
            throw AuthAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            struct MembersWrapper: Codable { let members: [User] }
            let decoded = try decoder.decode(MembersWrapper.self, from: data)
            return decoded.members
        case 401:
            throw AuthAPIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthAPIError.server(message)
        }
    }
}

private struct OnboardResponse: Codable {
    let user: User
}
