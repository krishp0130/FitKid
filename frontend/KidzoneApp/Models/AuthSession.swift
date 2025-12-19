import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}
