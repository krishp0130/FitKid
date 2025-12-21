import Foundation
import Combine

class AppStateViewModel: ObservableObject {
    @Published var state = AppState.mock
    @Published var isLoading = false
    @Published var choreError: String?
    @Published var walletError: String?

    private let choreAPI = ChoreAPI.shared
    private let moneyAPI = MoneyAPI.shared
    private var lastChoresFetch: Date?
    private var lastWalletFetch: Date?

    func loadMockData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }

    // MARK: - Chores (API)
    @MainActor
    func setChores(_ chores: [Chore]) {
        state.chores = chores
    }

    func fetchChores(accessToken: String, force: Bool = false) async {
        let freshnessWindow: TimeInterval = 0.5 // Reduced from 10 to 0.5 seconds for real-time updates
        if !force, let last = lastChoresFetch, Date().timeIntervalSince(last) < freshnessWindow {
            return
        }
        do {
            let chores = try await choreAPI.fetchChores(accessToken: accessToken)
            await MainActor.run {
                self.state.chores = chores
                self.choreError = nil
                self.lastChoresFetch = Date()
            }
            await refreshWallet(accessToken: accessToken, force: force)
        } catch {
            await MainActor.run {
                self.choreError = error.localizedDescription
            }
        }
    }

    func createChore(accessToken: String, assigneeId: String, title: String, detail: String, rewardDollars: Double, dueDateISO: String?, recurrenceType: String?) async throws {
        let chore = try await choreAPI.createChore(accessToken: accessToken, assigneeId: assigneeId, title: title, detail: detail, rewardDollars: rewardDollars, dueDateISO: dueDateISO, recurrenceType: recurrenceType)
        await MainActor.run {
            self.state.chores.insert(chore, at: 0)
            self.lastChoresFetch = Date()
        }
        await refreshWallet(accessToken: accessToken, force: true)
    }

    func submitChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.submitChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
                self.lastChoresFetch = Date()
            }
        }
        await refreshWallet(accessToken: accessToken, force: true)
    }

    func approveChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.approveChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
                self.lastChoresFetch = Date()
            }
        }
        await refreshWallet(accessToken: accessToken, force: true)
    }

    func rejectChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.rejectChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
                self.lastChoresFetch = Date()
            }
        }
        await refreshWallet(accessToken: accessToken, force: true)
    }
    
    func updateChore(accessToken: String, choreId: String, title: String?, detail: String?, rewardDollars: Double?, dueDateISO: String?, recurrenceType: String?) async throws {
        let updated = try await choreAPI.updateChore(accessToken: accessToken, choreId: choreId, title: title, detail: detail, rewardDollars: rewardDollars, dueDateISO: dueDateISO, recurrenceType: recurrenceType)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
                self.lastChoresFetch = Date()
            }
        }
        await refreshWallet(accessToken: accessToken, force: true)
    }

    func fetchPresets(accessToken: String) async throws -> [ChorePreset] {
        return try await choreAPI.fetchPresets(accessToken: accessToken)
    }

    // MARK: - Wallet
    func refreshWallet(accessToken: String, force: Bool = false) async {
        let freshnessWindow: TimeInterval = 0.5 // Reduced from 10 to 0.5 seconds for real-time updates
        if !force, let last = lastWalletFetch, Date().timeIntervalSince(last) < freshnessWindow {
            return
        }
        do {
            let balance = try await moneyAPI.fetchWalletBalance(accessToken: accessToken)
            await MainActor.run {
                self.state.walletBalanceCents = balance
                self.walletError = nil
                self.lastWalletFetch = Date()
            }
        } catch {
            await MainActor.run {
                self.walletError = error.localizedDescription
            }
        }
    }

    // MARK: - Future
    func loadUserData() async { }
    func purchaseItem(_ itemId: UUID, paymentMethod: PaymentMethod) async { }
}

enum PaymentMethod {
    case wallet
    case credit
}
