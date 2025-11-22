import Foundation
import Combine

enum AuthProvider: String {
    case google = "google"
    case microsoft = "microsoft"
    case facebook = "facebook"
    case email = "email"
}

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // In production, this would be stored securely (Keychain)
    private var authToken: String?
    
    init() {
        // Check if user is already logged in (from Keychain/local storage)
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        // TODO: Check Keychain for stored token
        // For now, set to mock user for testing
        // currentUser = User.mockChild
        // isAuthenticated = currentUser != nil
    }
    
    func signIn(with provider: AuthProvider, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Simulate OAuth flow - In production, use real OAuth SDKs
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            
            // Mock successful authentication
            let mockUser = User(
                id: UUID().uuidString,
                username: provider.rawValue.capitalized + " User",
                email: "\(provider.rawValue)@example.com",
                role: .child, // Will be set during role selection
                familyId: "",
                currentCreditScore: 300,
                parentCode: nil
            )
            
            self?.currentUser = mockUser
            self?.authToken = "mock_token_\(UUID().uuidString)"
            self?.isAuthenticated = true
            
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
    
    // For future backend integration
    var authTokenHeader: [String: String]? {
        guard let token = authToken else { return nil }
        return ["Authorization": "Bearer \(token)"]
    }
}

