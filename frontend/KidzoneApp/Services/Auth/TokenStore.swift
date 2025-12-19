import Foundation
import Security

protocol TokenStoring {
    func save(session: AuthSession) throws
    func load() -> AuthSession?
    func clear()
}

enum TokenStoreError: LocalizedError {
    case encodingFailed
    case unhandledStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Could not encode session data."
        case .unhandledStatus(let status): return "Keychain error (\(status))."
        }
    }
}

// Persists session tokens securely in the Keychain.
final class KeychainTokenStore: TokenStoring {
    private let service: String
    private let account = "kidzone-auth-session"

    init(service: String) {
        self.service = service
    }

    func save(session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Remove existing
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw TokenStoreError.unhandledStatus(status) }
    }

    func load() -> AuthSession? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
