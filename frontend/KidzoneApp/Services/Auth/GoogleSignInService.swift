import Foundation
import UIKit
import GoogleSignIn

struct GoogleSignInResult {
    let idToken: String
}

@MainActor
final class GoogleSignInService {
    private let clientID: String

    init(clientID: String) {
        self.clientID = clientID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func signIn() async throws -> GoogleSignInResult {
        guard let presentingVC = topViewController() else {
            throw AuthError.invalidCredentials
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredentials
        }

        return GoogleSignInResult(idToken: idToken)
    }

    private func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        var controller = keyWindow?.rootViewController

        while let presented = controller?.presentedViewController {
            controller = presented
        }

        if let nav = controller as? UINavigationController {
            return nav.visibleViewController
        }

        if let tab = controller as? UITabBarController {
            return tab.selectedViewController ?? tab
        }

        return controller
    }
}
