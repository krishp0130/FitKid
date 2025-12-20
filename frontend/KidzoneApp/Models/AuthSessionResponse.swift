import Foundation

struct AuthSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let status: AuthStatus?
    let user: User?
    
    // Computed property to get status with fallback
    var effectiveStatus: AuthStatus {
        // If status is provided, use it
        if let status = status {
            return status
        }
        // If user exists, they're an existing user
        if user != nil {
            return .existing
        }
        // Otherwise, needs onboarding
        return .needsOnboarding
    }
}

enum AuthStatus: String, Codable {
    case existing = "EXISTING_USER"
    case needsOnboarding = "NEEDS_ONBOARDING"
}
