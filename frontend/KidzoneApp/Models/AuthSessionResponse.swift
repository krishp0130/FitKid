import Foundation

struct AuthSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let status: AuthStatus
    let user: User?
}

enum AuthStatus: String, Codable {
    case existing = "EXISTING_USER"
    case needsOnboarding = "NEEDS_ONBOARDING"
}
