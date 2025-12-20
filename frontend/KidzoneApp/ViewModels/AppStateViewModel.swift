import Foundation
import Combine

class AppStateViewModel: ObservableObject {
    @Published var state = AppState.mock
    @Published var isLoading = false
    @Published var choreError: String?
    
    // For future API integration
    private let choreAPI = ChoreAPI.shared
    
    func loadMockData() {
        // Currently using mock data
        // TODO: Replace with API calls
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

    func fetchChores(accessToken: String) async {
        do {
            let chores = try await choreAPI.fetchChores(accessToken: accessToken)
            await MainActor.run {
                self.state.chores = chores
                self.choreError = nil
            }
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
        }
    }

    func submitChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.submitChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
            }
        }
    }

    func approveChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.approveChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
            }
        }
    }

    func rejectChore(accessToken: String, choreId: String) async throws {
        let updated = try await choreAPI.rejectChore(accessToken: accessToken, choreId: choreId)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
            }
        }
    }
    
    func updateChore(accessToken: String, choreId: String, title: String?, detail: String?, rewardDollars: Double?, dueDateISO: String?, recurrenceType: String?) async throws {
        let updated = try await choreAPI.updateChore(accessToken: accessToken, choreId: choreId, title: title, detail: detail, rewardDollars: rewardDollars, dueDateISO: dueDateISO, recurrenceType: recurrenceType)
        await MainActor.run {
            if let idx = self.state.chores.firstIndex(where: { $0.id == choreId }) {
                self.state.chores[idx] = updated
            }
        }
    }
    
    func fetchPresets(accessToken: String) async throws -> [ChorePreset] {
        return try await choreAPI.fetchPresets(accessToken: accessToken)
    }
    
    // MARK: - Future
    func loadUserData() async { }
    func purchaseItem(_ itemId: UUID, paymentMethod: PaymentMethod) async { }
}

enum PaymentMethod {
    case wallet
    case credit
}
