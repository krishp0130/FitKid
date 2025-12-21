import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAddChore = false
    @State private var showEditChore = false
    @State private var selectedChoreForEdit: Chore?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSegment: ChoreSegment = .active
    @State private var refreshTimer: Timer?
    @State private var hasLoadedOnce = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Chores", selection: $selectedSegment) {
                            Text("Active").tag(ChoreSegment.active)
                            Text("Completed").tag(ChoreSegment.completed)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        VStack(spacing: AppTheme.Parent.cardSpacing) {
                        if isLoading {
                            ProgressView()
                                .tint(AppTheme.Parent.primary)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(AppTheme.Parent.danger)
                        }

                        ForEach(filteredChores) { chore in
                            ParentChoreCard(chore: chore, onDecision: { action in
                                Task { await handleDecision(chore: chore, action: action) }
                            }, onEdit: {
                                showEditChore = true
                                selectedChoreForEdit = chore
                            })
                        }

                        if filteredChores.isEmpty && errorMessage == nil && !isLoading {
                            Text("No chores in this section yet.")
                                .font(AppTheme.Parent.bodyFont)
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        }
                    }
                    .padding(AppTheme.Parent.screenPadding)
                }
            }
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddChore = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.Parent.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddChore) {
                AddChoreView()
            }
            .sheet(item: $selectedChoreForEdit) { chore in
                // TODO: Add EditChoreView.swift to Xcode project's compile sources
                // EditChoreView(chore: chore)
                Text("Edit: \(chore.title)") // Temporary placeholder
            }
            .task {
                await loadChores(showLoading: true)
            }
            .onAppear {
                // Auto-refresh every 1 second (silently in background)
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    Task {
                        await loadChores(showLoading: false)
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoreCreated"))) { _ in
                Task { await loadChores(showLoading: false) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoreUpdated"))) { _ in
                Task { await loadChores(showLoading: false) }
            }
        }
    }
    
    private func loadChores(showLoading: Bool = false) async {
        guard let token = authManager.session?.accessToken else { return }
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        defer { 
            if showLoading {
                isLoading = false
            }
        }
        await appState.fetchChores(accessToken: token, force: false)
        if let err = appState.choreError {
            errorMessage = err
        }
        hasLoadedOnce = true
    }

    private func handleDecision(chore: Chore, action: ApprovalAction) async {
        guard let token = authManager.session?.accessToken else { return }
        // Show loading for user-initiated actions
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            switch action {
            case .approve:
                try await appState.approveChore(accessToken: token, choreId: chore.id)
            case .reject:
                try await appState.rejectChore(accessToken: token, choreId: chore.id)
            }
            // Refresh chores list silently
            await loadChores(showLoading: false)
            // Notify dashboard to refresh
            NotificationCenter.default.post(name: NSNotification.Name("ChoreUpdated"), object: nil)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private var filteredChores: [Chore] {
        switch selectedSegment {
        case .active:
            return appState.state.chores.filter { $0.status == .assigned || $0.status == .pendingApproval }
        case .completed:
            return appState.state.chores.filter { $0.status == .completed || $0.status == .rejected }
        }
    }
}

struct ParentChoreCard: View {
    let chore: Chore
    var onDecision: ((ApprovalAction) -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chore.title)
                        .font(AppTheme.Parent.headlineFont)
                        .foregroundStyle(AppTheme.Parent.textPrimary)
                    
                    if chore.isRecurring {
                        Text(chore.recurrenceLabel)
                            .font(AppTheme.Parent.captionFont)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.parentAccent.opacity(0.2))
                            )
                            .foregroundStyle(Color.parentAccent)
                    }
                }

                Text(chore.detail)
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)
                    .lineLimit(2)

                HStack {
                    Text("Reward: \(chore.rewardFormatted)")
                        .font(AppTheme.Parent.captionFont)
                        .foregroundStyle(AppTheme.Parent.success)
                    
                    if let assigneeName = chore.assigneeName {
                        Text("• \(assigneeName)")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)
                    }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Text(chore.status.label)
                    .font(AppTheme.Parent.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.Parent.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.Parent.cardBackground)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.Parent.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                    )

                if chore.status == .pendingApproval {
                    VStack(spacing: 8) {
                        Text("Needs Approval")
                            .font(AppTheme.Parent.captionFont)
                            .foregroundStyle(AppTheme.Parent.textSecondary)
                        
                        HStack(spacing: 8) {
                            Button {
                                onDecision?(.approve)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Approve")
                                        .font(AppTheme.Parent.captionFont.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Parent.success)
                                )
                            }
                            Button {
                                onDecision?(.reject)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Reject")
                                        .font(AppTheme.Parent.captionFont.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Parent.danger)
                                )
                            }
                        }
                    }
                } else if chore.status == .assigned {
                    Button {
                        onEdit?()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(AppTheme.Parent.primary)
                    }
                }
            }
        }
        .padding(AppTheme.Parent.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                .fill(AppTheme.Parent.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Parent.cornerRadius)
                        .stroke(AppTheme.Parent.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AddChoreView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var reward = ""
    @State private var dueDate: Date? = nil
    @State private var hasDueDate = false
    @State private var assigneeId: String = ""
    @State private var children: [User] = []
    @State private var isLoadingChildren = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showPresets = false
    @State private var presets: [ChorePreset] = []
    @State private var isLoadingPresets = false
    @State private var selectedPreset: ChorePreset?
    @State private var recurrenceType: String = "NONE"

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section("Quick Start") {
                        Button(action: {
                            showPresets.toggle()
                            Task { await loadPresets() }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Use Preset")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(AppTheme.Parent.primary)
                        }
                    }
                    
                    Section("Assign to") {
                        if isLoadingChildren {
                            ProgressView()
                        } else if children.isEmpty {
                            Text("No children in your family yet.")
                                .foregroundStyle(AppTheme.Parent.textSecondary)
                        } else {
                            Picker("Child", selection: $assigneeId) {
                                ForEach(children) { child in
                                    Text(child.username).tag(child.id)
                                }
                            }
                        }
                    }

                    Section {
                        TextField("Title", text: $title)
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                        TextField("Reward ($)", text: $reward)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Chore Details")
                    }
                    
                    Section {
                        Picker("Frequency", selection: $recurrenceType) {
                            Label("One-time", systemImage: "circle").tag("NONE")
                            Label("Daily", systemImage: "sun.max").tag("DAILY")
                            Label("Weekly", systemImage: "calendar").tag("WEEKLY")
                            Label("Monthly", systemImage: "calendar.badge.clock").tag("MONTHLY")
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Recurrence")
                    } footer: {
                        if recurrenceType != "NONE" {
                            Text("This chore will repeat \(recurrenceType.lowercased()).")
                        }
                    }
                    
                    Section {
                        Toggle("Set Due Date", isOn: $hasDueDate)
                        
                        if hasDueDate {
                            DatePicker(
                                "Due Date & Time",
                                selection: Binding(
                                    get: { 
                                        dueDate ?? Date().addingTimeInterval(86400)
                                    },
                                    set: { newDate in
                                        dueDate = newDate
                                    }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Due Date")
                    } footer: {
                        if hasDueDate {
                            Text("The chore should be completed by this date and time.")
                        }
                    }
                    
                    if showPresets {
                        Section("Presets") {
                            if isLoadingPresets {
                                ProgressView()
                            } else {
                                ForEach(Array(presets)) { preset in
                                    Button(action: {
                                        applyPreset(preset)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(preset.title)
                                                    .font(AppTheme.Parent.headlineFont)
                                                    .foregroundStyle(AppTheme.Parent.textPrimary)
                                                Spacer()
                                                Text(preset.rewardFormatted)
                                                    .font(AppTheme.Parent.headlineFont)
                                                    .foregroundStyle(AppTheme.Parent.success)
                                            }
                                            Text(preset.description)
                                                .font(AppTheme.Parent.captionFont)
                                                .foregroundStyle(AppTheme.Parent.textSecondary)
                                            Text(preset.recurrenceLabel)
                                                .font(AppTheme.Parent.captionFont)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.parentAccent.opacity(0.2))
                                                )
                                                .foregroundStyle(Color.parentAccent)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(AppTheme.Parent.danger)
                        }
                    }

                    Section {
                        Button {
                            Task { await create() }
                        } label: {
                            if isSubmitting {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                Text("Create Chore")
                            }
                        }
                        .foregroundStyle(AppTheme.Parent.primary)
                        .disabled(isSubmitting)
                    }
                }
            }
            .navigationTitle("New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Parent.textPrimary)
                }
            }
            .task {
                await loadChildren()
            }
        }
    }
    
    private func loadPresets() async {
        guard let token = authManager.session?.accessToken else { return }
        if isLoadingPresets { return }
        isLoadingPresets = true
        defer { isLoadingPresets = false }
        do {
            let fetchedPresets = try await appState.fetchPresets(accessToken: token)
            await MainActor.run {
                self.presets = fetchedPresets
            }
        } catch {
            // Presets are optional, don't show error
            print("Failed to load presets: \(error)")
        }
    }
    
    private func applyPreset(_ preset: ChorePreset) {
        title = preset.title
        description = preset.description
        reward = String(format: "%.2f", preset.rewardDollars)
        recurrenceType = preset.recurrenceType
        // Set due date based on recurrence type
        if let suggestedDay = preset.suggestedDueDay {
            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.year, .month, .weekday], from: Date())
            dateComponents.weekday = suggestedDay + 1 // Adjust for weekday index
            if let nextDate = calendar.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) {
                dueDate = nextDate
                hasDueDate = true
            }
        }
        showPresets = false
    }

    private func create() async {
        guard let token = authManager.session?.accessToken else { return }
        if isSubmitting { return }
        if assigneeId.isEmpty {
            await MainActor.run { errorMessage = "Please select a child" }
            return
        }
        let rewardValue = Double(reward) ?? 0
        if rewardValue <= 0 {
            await MainActor.run { errorMessage = "Invalid reward amount" }
            return
        }
        isSubmitting = true
        do {
            let descValue = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Format due date to ISO 8601 string if set
            let dueDateISO: String?
            if hasDueDate, let dueDate = dueDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                dueDateISO = formatter.string(from: dueDate)
            } else {
                dueDateISO = nil
            }
            
            try await appState.createChore(
                accessToken: token,
                assigneeId: assigneeId,
                title: title,
                detail: descValue,
                rewardDollars: rewardValue,
                dueDateISO: dueDateISO,
                recurrenceType: recurrenceType == "NONE" ? nil : recurrenceType
            )
            // Notify listeners (dashboard/child list) to refresh
            NotificationCenter.default.post(name: NSNotification.Name("ChoreCreated"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("ChoreUpdated"), object: nil)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
        isSubmitting = false
    }

    private func loadChildren() async {
        guard let token = authManager.session?.accessToken else { return }
        if isLoadingChildren { return }
        isLoadingChildren = true
        defer { isLoadingChildren = false }
        do {
            let members = try await AuthAPI.shared.fetchFamilyMembers(accessToken: token)
            await MainActor.run {
                self.children = members
                if assigneeId.isEmpty { assigneeId = members.first?.id ?? "" }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

enum ApprovalAction {
    case approve
    case reject
}
