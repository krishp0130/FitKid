import Foundation
import Combine
import GoogleSignIn

enum AuthProvider: String {
    case google = "google"
    case apple = "apple"
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
    static let onboardingCompletedNotification = Notification.Name("AuthOnboardingCompleted")

    @Published var currentUser: User?
    @Published var session: AuthSession?
    @Published var onboardingRequired = false
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authAPI = AuthAPI.shared
    private let tokenStore: TokenStoring = KeychainTokenStore(service: "com.kidzone.auth")
    private var googleSignInService: GoogleSignInService?
    private let appleSignInService = AppleSignInService()

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
        let response = try await authAPI.exchangeGoogleToken(idToken: googleResult.idToken)
        handleAuthResponse(response)
        guard let user = response.user else { throw AuthError.invalidCredentials }
        return user
    }

    // MARK: - Apple
    func signInWithApple() async throws -> User {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let appleResult = try await appleSignInService.signIn()
        let response = try await authAPI.exchangeAppleToken(idToken: appleResult.identityToken, nonce: appleResult.nonce)
        handleAuthResponse(response)
        guard let user = response.user else { throw AuthError.invalidCredentials }
        return user
    }

    // MARK: - Entry point for UI
    func signIn(with provider: AuthProvider, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                let user: User
                switch provider {
                case .google:
                    user = try await signInWithGoogle()
                case .apple:
                    user = try await signInWithApple()
                }
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func onboardParent(familyName: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let token = session?.accessToken else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        Task {
            do {
                let user = try await authAPI.onboardParent(familyName: familyName, username: username, accessToken: token)
                completeOnboarding(with: user)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func onboardChild(familyId: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let token = session?.accessToken else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        Task {
            do {
                let user = try await authAPI.onboardChild(familyId: familyId, username: username, accessToken: token)
                completeOnboarding(with: user)
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
        onboardingRequired = false
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
        onboardingRequired = false
    }

    var authTokenHeader: [String: String]? {
        guard let token = session?.accessToken else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }

    // MARK: - Helpers
    private func handleAuthResponse(_ response: AuthSessionResponse) {
        switch response.status {
        case .existing:
            if let user = response.user {
                currentUser = user
            }
            let session = AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken, user: response.user ?? currentUser ?? User.mockChild)
            self.session = session
            try? tokenStore.save(session: session)
            isAuthenticated = true
            onboardingRequired = false
        case .needsOnboarding:
            // Store tokens so we can call onboarding endpoints
            let session = AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken, user: response.user ?? User.mockChild)
            self.session = session
            try? tokenStore.save(session: session)
            onboardingRequired = true
            isAuthenticated = false
        }
    }

    private func completeOnboarding(with user: User) {
        currentUser = user
        var updatedSession = session ?? AuthSession(accessToken: "", refreshToken: "", user: user)
        updatedSession = AuthSession(accessToken: updatedSession.accessToken, refreshToken: updatedSession.refreshToken, user: user)
        session = updatedSession
        try? tokenStore.save(session: updatedSession)
        onboardingRequired = false
        isAuthenticated = true
        NotificationCenter.default.post(name: Self.onboardingCompletedNotification, object: nil)
    }
}
