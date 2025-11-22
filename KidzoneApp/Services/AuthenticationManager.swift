import Foundation
import Combine

enum AuthProvider: String {
    case google = "google"
    case microsoft = "microsoft"
    case facebook = "facebook"
    case email = "email"
}

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case invalidCredentials
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .emailAlreadyExists:
            return "This email is already registered. Please log in instead."
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock storage for checking duplicate emails (in production, use backend)
    private var registeredEmails: Set<String> = []
    
    // In production, this would be stored securely (Keychain)
    var authToken: String?
    
    init() {
        // Check if user is already logged in (from Keychain/local storage)
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        // TODO: Check Keychain for stored token
        // For now, no auto-login
    }
    
    // MARK: - Email Authentication
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        // Validate email format
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Check for duplicate email
        if registeredEmails.contains(email.lowercased()) {
            throw AuthError.emailAlreadyExists
        }
        
        // Validate password
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // TODO: Hash password before storing
        // TODO: API call to backend to create account
        
        // Mock: Add to registered emails
        registeredEmails.insert(email.lowercased())
        
        // Mock: Create user
            let user = User(
                id: UUID().uuidString,
                username: username,
                email: email,
                role: .none, // Will be set during role selection
                familyId: "",
                currentCreditScore: 300,
                parentCode: nil
            )
        
        authToken = "mock_token_\(UUID().uuidString)"
        currentUser = user
        isAuthenticated = true
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Validate email format
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // TODO: API call to backend to authenticate
        // For now, check if email exists in our mock storage
        
        // Mock: Check credentials
        // In production, this would be an API call
        if registeredEmails.contains(email.lowercased()) {
            // User exists - mock successful login
            let user = User(
                id: UUID().uuidString,
                username: email.components(separatedBy: "@").first ?? "User",
                email: email,
                role: .child,
                familyId: "",
                currentCreditScore: 300,
                parentCode: nil
            )
            
            authToken = "mock_token_\(UUID().uuidString)"
            currentUser = user
            isAuthenticated = true
            
            return user
        } else {
            throw AuthError.invalidCredentials
        }
    }
    
    func checkEmailExists(_ email: String) async -> Bool {
        // TODO: API call to backend
        return registeredEmails.contains(email.lowercased())
    }
    
    // MARK: - OAuth Authentication
    
    func signIn(with provider: AuthProvider, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement real OAuth flow with SDKs
        // For now, simulate OAuth flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // Mock successful OAuth authentication
            let mockUser = User(
                id: UUID().uuidString,
                username: provider.rawValue.capitalized + " User",
                email: "\(provider.rawValue)@example.com",
                role: .none, // Will be set during role selection
                familyId: "",
                currentCreditScore: 300,
                parentCode: nil
            )
            
            // Check if email already exists (prevent duplicates)
            let emailKey = mockUser.email?.lowercased() ?? ""
            if !self.registeredEmails.contains(emailKey) {
                self.registeredEmails.insert(emailKey)
            }
            
            self.currentUser = mockUser
            self.authToken = "mock_token_\(UUID().uuidString)"
            self.isAuthenticated = true
            
            completion(.success(mockUser))
        }
    }
    
    func signOut() {
        currentUser = nil
        authToken = nil
        isAuthenticated = false
        // TODO: Clear Keychain
    }
    
    func updateUserRole(_ role: UserRole, parentCode: String? = nil) {
        guard var user = currentUser else { return }
        user.role = role
        user.parentCode = parentCode
        currentUser = user
    }
    
    func validateParentCode(_ code: String) -> Bool {
        // Mock validation - In production, validate against backend
        return code.count >= 6 && code.count <= 8
    }
    
    // MARK: - Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // For future backend integration
    var authTokenHeader: [String: String]? {
        guard let token = authToken else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
}
