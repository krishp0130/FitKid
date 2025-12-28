import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showEditSheet = false
    @State private var salesTaxPercent = 8.0
    @State private var cashbackPercent = 2.0
    @State private var penaltyPointsValue = 25
    @State private var graceDaysValue = 3
    @State private var deviceMinimumScoreValue = 650
    @State private var dailyHourCapValue = 3
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section("Family") {
                        if let familyId = authManager.currentUser?.familyId {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Family Code")
                                        .font(AppTheme.Parent.bodyFont)
                                    Text(familyId)
                                        .font(AppTheme.Parent.bodyFont.monospaced().weight(.semibold))
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = familyId
                                    withAnimation { showCopiedToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { showCopiedToast = false }
                                    }
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(AppTheme.Parent.captionFont.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.Parent.primary)
                            }
                        } else {
                            Text("Family code unavailable")
                                .font(AppTheme.Parent.bodyFont)
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        }
                    }

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
                            loadCurrentSettings()
                            showEditSheet = true
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
            .overlay(alignment: .top) {
                if showCopiedToast {
                    Text("Family code copied")
                        .font(AppTheme.Parent.captionFont.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(AppTheme.Parent.cardBackground.opacity(0.9))
                        )
                        .overlay(
                            Capsule().stroke(AppTheme.Parent.textSecondary.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showEditSheet) {
                NavigationView {
                    Form {
                        Section("Credit Rules") {
                            Stepper(value: $penaltyPointsValue, in: 0...100, step: 5) {
                                HStack {
                                    Text("Penalty Points")
                                    Spacer()
                                    Text("\(penaltyPointsValue) pts")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }

                            Stepper(value: $graceDaysValue, in: 0...30, step: 1) {
                                HStack {
                                    Text("Grace Period")
                                    Spacer()
                                    Text("\(graceDaysValue) days")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }
                        }

                        Section("Taxes & Rewards") {
                            Stepper(value: $salesTaxPercent, in: 0...20, step: 0.25) {
                                HStack {
                                    Text("Sales Tax")
                                    Spacer()
                                    Text("\(salesTaxPercent, specifier: "%.2f")%")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }

                            Stepper(value: $cashbackPercent, in: 0...20, step: 0.25) {
                                HStack {
                                    Text("Cashback Bonus")
                                    Spacer()
                                    Text("\(cashbackPercent, specifier: "%.2f")%")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }
                        }

                        Section("Device Hours") {
                            Stepper(value: $deviceMinimumScoreValue, in: 300...850, step: 10) {
                                HStack {
                                    Text("Minimum Score")
                                    Spacer()
                                    Text("\(deviceMinimumScoreValue)")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }

                            Stepper(value: $dailyHourCapValue, in: 0...12, step: 1) {
                                HStack {
                                    Text("Daily Cap")
                                    Spacer()
                                    Text("\(dailyHourCapValue) hrs")
                                        .foregroundStyle(AppTheme.Parent.textSecondary)
                                }
                            }
                        }
                    }
                    .font(AppTheme.Parent.bodyFont)
                    .navigationTitle("Edit Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showEditSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveSettings()
                            }
                            .font(.headline)
                        }
                    }
                }
            }
        }
    }

    private func loadCurrentSettings() {
        let settings = appState.state.parentSettings
        salesTaxPercent = settings.salesTax * 100
        cashbackPercent = settings.cashbackBonus * 100
        penaltyPointsValue = settings.penaltyPoints
        graceDaysValue = settings.graceDays
        deviceMinimumScoreValue = settings.deviceMinimumScore
        dailyHourCapValue = settings.dailyHourCap
    }

    private func saveSettings() {
        let newSettings = ParentSettings(
            salesTax: salesTaxPercent / 100,
            penaltyPoints: penaltyPointsValue,
            graceDays: graceDaysValue,
            cashbackBonus: cashbackPercent / 100,
            deviceMinimumScore: deviceMinimumScoreValue,
            dailyHourCap: dailyHourCapValue
        )
        Task { @MainActor in
            appState.updateParentSettings(newSettings)
            showEditSheet = false
        }
    }
}
