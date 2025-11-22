import SwiftUI

struct MainTabView: View {
    let user: User
    @StateObject private var appState = AppStateViewModel()
    
    var body: some View {
        Group {
            if user.role == .child {
                ChildMainTabView()
                    .environmentObject(appState)
            } else {
                ParentMainTabView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Child Main Tab View
struct ChildMainTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChildDashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ChoresView()
                .tabItem {
                    Label("Chores", systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            CreditCardsView()
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            MarketplaceView()
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Color.kidzoneYellow)
        .onAppear {
            appState.loadMockData()
        }
    }
}

// MARK: - Parent Main Tab View
struct ParentMainTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ParentDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            ParentChoresView()
                .tabItem {
                    Label("Chores", systemImage: "list.clipboard.fill")
                }
                .tag(1)
            
            ParentApprovalsView()
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.seal.fill")
                }
                .tag(2)
            
            ParentSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color.kidzoneBlue)
        .onAppear {
            appState.loadMockData()
        }
    }
}

