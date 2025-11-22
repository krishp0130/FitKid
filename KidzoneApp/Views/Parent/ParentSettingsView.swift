import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var salesTax = 8.0
    @State private var minScore = 650
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.parentGradient
                    .ignoresSafeArea()
                
                Form {
                    Section("Credit Rules") {
                        HStack {
                            Text("Penalty Points")
                            Spacer()
                            Text("\(appState.state.parentSettings.penaltyPoints) pts")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Grace Period")
                            Spacer()
                            Text("\(appState.state.parentSettings.graceDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Taxes & Rewards") {
                        HStack {
                            Text("Sales Tax")
                            Spacer()
                            Text("\(Int(appState.state.parentSettings.salesTax * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Cashback Bonus")
                            Spacer()
                            Text("\(Int(appState.state.parentSettings.cashbackBonus * 100))%")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Device Hours") {
                        HStack {
                            Text("Minimum Score")
                            Spacer()
                            Text("\(appState.state.parentSettings.deviceMinimumScore)")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Daily Cap")
                            Spacer()
                            Text("\(appState.state.parentSettings.dailyHourCap) hrs")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section {
                        Button("Edit Settings") {
                            // TODO: Show edit sheet
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

