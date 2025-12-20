import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAddChore = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSegment: ChoreSegment = .active
    
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
            .task {
                await loadChores()
            }
        }
    }

    private func loadChores() async {
        guard let token = authManager.session?.accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await appState.fetchChores(accessToken: token)
        if let err = appState.choreError {
            errorMessage = err
        }
    }

    private func handleDecision(chore: Chore, action: ApprovalAction) async {
        guard let token = authManager.session?.accessToken else { return }
        do {
            switch action {
            case .approve:
                try await appState.approveChore(accessToken: token, choreId: chore.id)
            case .reject:
                try await appState.rejectChore(accessToken: token, choreId: chore.id)
            }
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(chore.title)
                    .font(AppTheme.Parent.headlineFont)
                    .foregroundStyle(AppTheme.Parent.textPrimary)

                Text(chore.detail)
                    .font(AppTheme.Parent.bodyFont)
                    .foregroundStyle(AppTheme.Parent.textSecondary)

                Text("Reward: \(chore.rewardFormatted)")
                    .font(AppTheme.Parent.captionFont)
                    .foregroundStyle(AppTheme.Parent.success)
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
                    HStack(spacing: 8) {
                        Button {
                            onDecision?(.approve)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.Parent.success)
                        }
                        Button {
                            onDecision?(.reject)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.Parent.danger)
                        }
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
    @State private var dueDate = ""
    @State private var assigneeId: String = ""
    @State private var children: [User] = []
    @State private var isLoadingChildren = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                Form {
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

                    Section("Chore Details") {
                        TextField("Title", text: $title)
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                        TextField("Reward ($)", text: $reward)
                            .keyboardType(.decimalPad)
                        TextField("Due date (optional)", text: $dueDate)
                            .textInputAutocapitalization(.never)
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(AppTheme.Parent.danger)
                        }
                    }

                    Section {
                        Button("Create Chore") {
                            Task { await create() }
                        }
                        .foregroundStyle(AppTheme.Parent.primary)
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

    private func create() async {
        guard let token = authManager.session?.accessToken else { return }
        if assigneeId.isEmpty {
            await MainActor.run { errorMessage = "Please select a child" }
            return
        }
        let rewardValue = Double(reward) ?? 0
        if rewardValue <= 0 {
            await MainActor.run { errorMessage = "Invalid reward amount" }
            return
        }
        do {
            let dueDateValue = dueDate.trimmingCharacters(in: .whitespacesAndNewlines)
            let descValue = description.trimmingCharacters(in: .whitespacesAndNewlines)
            try await appState.createChore(
                accessToken: token,
                assigneeId: assigneeId,
                title: title,
                detail: descValue,
                rewardDollars: rewardValue,
                dueDateISO: dueDateValue.isEmpty ? nil : dueDateValue
            )
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
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
