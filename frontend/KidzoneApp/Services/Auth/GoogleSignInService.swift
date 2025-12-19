import Foundation
import UIKit
import GoogleSignIn

struct GoogleSignInResult {
    let idToken: String
}

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

    private func topViewController(controller: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        if let nav = controller as? UINavigationController {
            return topViewController(controller: nav.visibleViewController)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(controller: selected)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
