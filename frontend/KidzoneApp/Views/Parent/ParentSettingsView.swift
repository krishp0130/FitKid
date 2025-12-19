import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var salesTax = 8.0
    @State private var minScore = 650
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section("Credit Rules") {
                        HStack {
                            Text("Penalty Points")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(appState.state.parentSettings.penaltyPoints) pts")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }

                        HStack {
                            Text("Grace Period")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(appState.state.parentSettings.graceDays) days")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }
                    }

                    Section("Taxes & Rewards") {
                        HStack {
                            Text("Sales Tax")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(Int(appState.state.parentSettings.salesTax * 100))%")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }

                        HStack {
                            Text("Cashback Bonus")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(Int(appState.state.parentSettings.cashbackBonus * 100))%")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }
                    }

                    Section("Device Hours") {
                        HStack {
                            Text("Minimum Score")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(appState.state.parentSettings.deviceMinimumScore)")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }

                        HStack {
                            Text("Daily Cap")
                                .font(AppTheme.Parent.bodyFont)
                            Spacer()
                            Text("\(appState.state.parentSettings.dailyHourCap) hrs")
                                .font(AppTheme.Parent.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }
                    }

                    Section {
                        Button("Edit Settings") {
                            // TODO: Show edit sheet
                        }
                        .font(AppTheme.Parent.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.Parent.primary)
                    }

                    Section {
                        Button(role: .destructive) {
                            authManager.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
