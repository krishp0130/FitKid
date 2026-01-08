import Foundation
import SwiftUI

@MainActor
final class RequestsViewModel: ObservableObject {
    @Published var requests: [PurchaseRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = PurchaseRequestAPI.shared
    private var lastFetch: Date?
    private let freshnessWindow: TimeInterval = 1 // seconds for near-real-time updates

    func load(accessToken: String, force: Bool = false, showLoading: Bool = true) async {
        if !force, let lastFetch, Date().timeIntervalSince(lastFetch) < freshnessWindow {
            return
        }
        if isLoading && !force { return }
        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }
        errorMessage = nil
        do {
            let data = try await api.fetchRequests(accessToken: accessToken)
            requests = data
            lastFetch = Date()
        } catch is CancellationError {
            // ignore
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            // ignore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approve(accessToken: String, id: String) async {
        do {
            let updated = try await api.approve(accessToken: accessToken, id: id)
            if let idx = requests.firstIndex(where: { $0.id == id }) {
                requests[idx] = updated
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func reject(accessToken: String, id: String) async {
        do {
            let updated = try await api.reject(accessToken: accessToken, id: id)
            if let idx = requests.firstIndex(where: { $0.id == id }) {
                requests[idx] = updated
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
