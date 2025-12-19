import Foundation
import Combine

class AppStateViewModel: ObservableObject {
    @Published var state = AppState.mock
    @Published var isLoading = false
    
    // For future API integration
    private let apiService = APIService.shared
    
    func loadMockData() {
        // Currently using mock data
        // TODO: Replace with API calls
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }
    
    // MARK: - Future API Methods
    
    func loadUserData() async {
        // TODO: Fetch from API
        // await apiService.request(...)
    }
    
    func completeChore(_ choreId: UUID) async {
        // TODO: API call to complete chore
        // Update local state
    }
    
    func purchaseItem(_ itemId: UUID, paymentMethod: PaymentMethod) async {
        // TODO: API call to purchase item
        // Update local state
    }
}

enum PaymentMethod {
    case wallet
    case credit
}

