import Foundation
import Combine
import GoogleSignIn

enum AuthProvider: String {
    case google = "google"
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "We could not verify your sign-in credentials."
        case .notImplemented: return "This sign-in option is not available yet."
        }
    }
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var session: AuthSession?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authAPI = AuthAPI.shared
    private let tokenStore: TokenStoring = KeychainTokenStore(service: "com.kidzone.auth")
    private var googleSignInService: GoogleSignInService?

    // Temporary storage for user data before role selection
    private var pendingUser: User?

    init(googleClientID: String = "") {
        if !googleClientID.isEmpty {
            self.googleSignInService = GoogleSignInService(clientID: googleClientID)
        }
        restoreSession()
    }

    // MARK: - Google
    func signInWithGoogle() async throws -> User {
        guard let googleSignInService = googleSignInService else {
            throw AuthError.invalidCredentials
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let googleResult = try await googleSignInService.signIn()
        let newSession = try await authAPI.exchangeGoogleToken(idToken: googleResult.idToken)

        try tokenStore.save(session: newSession)

        session = newSession
        currentUser = newSession.user
        isAuthenticated = true

        return newSession.user
    }

    // MARK: - Entry point for UI
    func signIn(with provider: AuthProvider, completion: @escaping (Result<User, Error>) -> Void) {
        guard provider == .google else {
            completion(.failure(AuthError.notImplemented))
            return
        }

        Task {
            do {
                let user = try await signInWithGoogle()
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signOut() {
        currentUser = nil
        pendingUser = nil
        session = nil
        isAuthenticated = false
        tokenStore.clear()
        GIDSignIn.sharedInstance.signOut()
    }

    func updateUserRole(_ role: UserRole, parentCode: String? = nil) {
        guard var user = currentUser ?? pendingUser else { return }
        user.role = role
        user.parentCode = parentCode

        currentUser = user
        pendingUser = nil
    }

    func validateParentCode(_ code: String) -> Bool {
        // Replace with backend validation if you want server-side verification.
        return code.count >= 6 && code.count <= 8
    }

    // MARK: - Private
    private func restoreSession() {
        guard let stored = tokenStore.load() else { return }
        session = stored
        currentUser = stored.user
        isAuthenticated = true
    }

    var authTokenHeader: [String: String]? {
        guard let token = session?.accessToken else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
}
