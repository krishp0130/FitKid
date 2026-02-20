import Foundation
import Combine

class AppStateViewModel: ObservableObject {
    @Published var state = AppState.mock
    @Published var isLoading = false
    @Published var choreError: String?
    @Published var walletError: String?
    @Published var creditCards: [CreditCard] = []
    @Published var creditScore: CreditScore?
    @Published var creditError: String?
    @Published var scheduledAllowances: [ScheduledAllowance] = []

    private let choreAPI = ChoreAPI.shared
    private let moneyAPI = MoneyAPI.shared
    private let creditAPI = CreditAPI.shared
    private let allowanceAPI = AllowanceAPI()
    private var lastChoresFetch: Date?
    private var lastWalletFetch: Date?
    private var lastCreditFetch: Date?

    func loadMockData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }

    @MainActor
    func updateParentSettings(_ settings: ParentSettings) {
        state.parentSettings = settings
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
                self.objectWillChange.send()
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
                self.objectWillChange.send()
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

    // MARK: - Credit System
    func fetchCreditCards(accessToken: String, force: Bool = false) async {
        let freshnessWindow: TimeInterval = 0.5
        if !force, let last = lastCreditFetch, Date().timeIntervalSince(last) < freshnessWindow {
            return
        }
        do {
            let cards = try await creditAPI.getCreditCards(accessToken: accessToken)
            await MainActor.run {
                self.creditCards = cards
                self.creditError = nil
                self.lastCreditFetch = Date()
            }
        } catch {
            await MainActor.run {
                self.creditError = error.localizedDescription
            }
        }
    }
    
    func fetchCreditScore(accessToken: String) async {
        do {
            let score = try await creditAPI.getCreditScore(accessToken: accessToken)
            await MainActor.run {
                self.creditScore = score
                self.state.creditScore = score.creditScore
                self.creditError = nil
            }
        } catch {
            await MainActor.run {
                self.creditError = error.localizedDescription
            }
        }
    }
    
    func applyForCreditCard(accessToken: String, tier: CreditTier? = nil) async throws {
        let card = try await creditAPI.applyForCreditCard(accessToken: accessToken, requestedTier: tier)
        await MainActor.run {
            self.creditCards.insert(card, at: 0)
            self.lastCreditFetch = Date()
        }
        // Fetch latest state to ensure pending cards are synced (and visible to parent)
        await fetchCreditCards(accessToken: accessToken, force: true)
    }
    
    // MARK: - Allowance
    func createAllowance(accessToken: String, childId: String, amountCents: Int, frequency: String, customDays: Int?) async throws {
        try await allowanceAPI.createAllowance(accessToken: accessToken, childId: childId, amountCents: amountCents, frequency: frequency, customDays: customDays)
        await fetchAllowances(accessToken: accessToken)
    }

    func fetchAllowances(accessToken: String) async {
        do {
            let list = try await allowanceAPI.listAllowances(accessToken: accessToken)
            await MainActor.run { scheduledAllowances = list }
        } catch {
            await MainActor.run { scheduledAllowances = [] }
        }
    }

    func deleteAllowance(accessToken: String, allowanceId: String) async throws {
        try await allowanceAPI.deleteAllowance(accessToken: accessToken, allowanceId: allowanceId)
        await MainActor.run { scheduledAllowances.removeAll { $0.id == allowanceId } }
    }

    func makePayment(accessToken: String, cardId: String, amount: Double) async throws {
        try await creditAPI.makePayment(accessToken: accessToken, cardId: cardId, amountDollars: amount)
        await fetchCreditCards(accessToken: accessToken, force: true)
        await fetchCreditScore(accessToken: accessToken)
    }

    // MARK: - Future
    func loadUserData() async { }
    func purchaseItem(_ itemId: UUID, paymentMethod: PaymentMethod) async { }
}

enum PaymentMethod {
    case wallet
    case credit
}

// MARK: - Scheduled Allowance (for list display)
struct ScheduledAllowance: Identifiable, Codable {
    let id: String
    let childId: String
    let amountCents: Int
    let frequency: String
    let customIntervalDays: Int?
    let createdAt: String?

    var amountFormatted: String {
        let d = Double(amountCents) / 100.0
        return String(format: "$%.2f", d)
    }

    var frequencyLabel: String {
        switch frequency.uppercased() {
        case "WEEKLY": return "Weekly"
        case "MONTHLY": return "Monthly"
        case "CUSTOM":
            if let days = customIntervalDays { return "Every \(days) days" }
            return "Custom"
        default: return frequency
        }
    }
}

// MARK: - Allowance API (lightweight)
private final class AllowanceAPI {
    private let baseURLString = "http://localhost:3001/api/allowance"
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func listAllowances(accessToken: String) async throws -> [ScheduledAllowance] {
        guard let url = URL(string: baseURLString) else { throw AllowanceAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AllowanceAPIError.invalidURL }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw AllowanceAPIError.unauthorized }
            throw AllowanceAPIError.server(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        struct ListResponse: Codable { let allowances: [ScheduledAllowance] }
        let decoded = try decoder.decode(ListResponse.self, from: data)
        return decoded.allowances
    }

    func deleteAllowance(accessToken: String, allowanceId: String) async throws {
        guard let url = URL(string: "\(baseURLString)/\(allowanceId)") else { throw AllowanceAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AllowanceAPIError.invalidURL }
        guard http.statusCode == 204 || http.statusCode == 200 else {
            if http.statusCode == 401 { throw AllowanceAPIError.unauthorized }
            throw AllowanceAPIError.server("Delete failed")
        }
    }

    func createAllowance(accessToken: String, childId: String, amountCents: Int, frequency: String, customDays: Int?) async throws {
        guard let url = URL(string: baseURLString) else { throw AllowanceAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "childId": childId,
            "amountCents": amountCents,
            "frequency": frequency
        ]
        if let customDays { body["customIntervalDays"] = customDays }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AllowanceAPIError.invalidURL }
        
        switch http.statusCode {
        case 201:
            return
        case 401:
            throw AllowanceAPIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AllowanceAPIError.server(msg)
        }
    }
}

private enum AllowanceAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case server(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid allowance endpoint."
        case .unauthorized: return "Unauthorized. Please sign in again."
        case .server(let msg): return msg
        }
    }
}
