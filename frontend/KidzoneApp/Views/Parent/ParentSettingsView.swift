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
    @State private var allowanceAmount = ""
    @State private var selectedChildId: String = ""
    @State private var allowanceFrequency: AllowanceFrequency = .weekly
    @State private var allowanceCustomDays = "7"
    @State private var allowanceMessage: String?
    @State private var allowanceSubmitting = false
    @State private var children: [User] = []
    @State private var allowanceDeletingId: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section("Family") {
                        if let familyId = authManager.currentUser?.familyId {
                            HStack(spacing: 12) {
                                Text(familyId)
                                    .font(.system(.subheadline, design: .monospaced).weight(.medium))
                                    .foregroundStyle(AppTheme.Parent.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Spacer(minLength: 8)
                                Button {
                                    UIPasteboard.general.string = familyId
                                    withAnimation { showCopiedToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { showCopiedToast = false }
                                    }
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(AppTheme.Parent.primary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
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

                    Section("Allowance") {
                        Picker("Select Child", selection: $selectedChildId) {
                            Text("Choose a child…").tag("")
                            ForEach(children) { child in
                                Text("\(child.username) (\(shortId(child.id)))").tag(child.id)
                            }
                        }
                        TextField("Amount (e.g. 5.00)", text: $allowanceAmount)
                            .keyboardType(.decimalPad)

                        Picker("Frequency", selection: $allowanceFrequency) {
                            ForEach(AllowanceFrequency.allCases, id: \.self) { freq in
                                Text(freq.label).tag(freq)
                            }
                        }
                        if allowanceFrequency == .custom {
                            TextField("Custom interval (days)", text: $allowanceCustomDays)
                                .keyboardType(.numberPad)
                        }

                        if let allowanceMessage {
                            Text(allowanceMessage)
                                .font(AppTheme.Parent.captionFont)
                                .foregroundStyle(allowanceMessage.contains("Success") ? AppTheme.Parent.success : AppTheme.Parent.danger)
                        }

                        Button {
                            Task { await submitAllowance() }
                        } label: {
                            if allowanceSubmitting {
                                ProgressView()
                            } else {
                                Text("Add Allowance Now")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.Parent.primary)
                        .disabled(allowanceSubmitting)
                    }

                    Section("Scheduled Allowances") {
                        if appState.scheduledAllowances.isEmpty {
                            Text("No scheduled allowances yet.")
                                .font(AppTheme.Parent.captionFont)
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        } else {
                            ForEach(appState.scheduledAllowances) { allowance in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(childName(for: allowance.childId)) (\(shortId(allowance.childId)))")
                                            .font(AppTheme.Parent.bodyFont.weight(.medium))
                                            .foregroundStyle(AppTheme.Parent.textPrimary)
                                        Text("\(allowance.amountFormatted) • \(allowance.frequencyLabel)")
                                            .font(AppTheme.Parent.captionFont)
                                            .foregroundStyle(AppTheme.Parent.textSecondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        Task { await deleteAllowance(allowance.id) }
                                    } label: {
                                        if allowanceDeletingId == allowance.id {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "trash")
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(allowanceDeletingId == allowance.id)
                                }
                                .padding(.vertical, 4)
                            }
                        }
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
            .task {
                await loadChildren()
                await loadAllowances()
            }
            .refreshable {
                await loadAllowances()
            }
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

    private func shortId(_ id: String) -> String {
        if id.count <= 8 { return id }
        return String(id.prefix(8))
    }

    private func childName(for childId: String) -> String {
        children.first { $0.id == childId }?.username ?? "Unknown"
    }

    private func loadChildren() async {
        guard let token = authManager.session?.accessToken else { return }
        do {
            let list = try await AuthAPI.shared.fetchFamilyMembers(accessToken: token)
            await MainActor.run { children = list }
            if selectedChildId.isEmpty, let first = list.first {
                await MainActor.run { selectedChildId = first.id }
            }
        } catch {
            await MainActor.run { children = [] }
        }
    }

    private func loadAllowances() async {
        guard let token = authManager.session?.accessToken else { return }
        await appState.fetchAllowances(accessToken: token)
    }

    private func deleteAllowance(_ allowanceId: String) async {
        guard let token = authManager.session?.accessToken else { return }
        allowanceDeletingId = allowanceId
        defer { allowanceDeletingId = nil }
        do {
            try await appState.deleteAllowance(accessToken: token, allowanceId: allowanceId)
        } catch {
            allowanceMessage = cleanError(error.localizedDescription)
        }
    }

    private func submitAllowance() async {
        guard let token = authManager.session?.accessToken else {
            allowanceMessage = "Not signed in."
            return
        }
        guard !selectedChildId.isEmpty else {
            allowanceMessage = "Please select a child."
            return
        }
        guard let amount = Double(allowanceAmount), amount > 0 else {
            allowanceMessage = "Enter a valid amount."
            return
        }
        var customDays: Int?
        if allowanceFrequency == .custom {
            customDays = Int(allowanceCustomDays) ?? 0
            if let days = customDays, days <= 0 {
                allowanceMessage = "Custom days must be > 0."
                return
            }
        }
        allowanceSubmitting = true
        allowanceMessage = nil
        do {
            try await appState.createAllowance(
                accessToken: token,
                childId: selectedChildId,
                amountCents: Int((amount * 100).rounded()),
                frequency: allowanceFrequency.rawValue,
                customDays: customDays
            )
            allowanceMessage = "Success: allowance added."
            allowanceAmount = ""
        } catch {
            allowanceMessage = cleanError(error.localizedDescription)
        }
        allowanceSubmitting = false
    }
}

enum AllowanceFrequency: String, CaseIterable {
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case custom = "CUSTOM"

    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Custom"
        }
    }
}

private func cleanError(_ message: String) -> String {
    var output = message
    output = output.replacingOccurrences(of: "[", with: "")
    output = output.replacingOccurrences(of: "]", with: "")
    output = output.replacingOccurrences(of: "\"", with: "")
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
}
