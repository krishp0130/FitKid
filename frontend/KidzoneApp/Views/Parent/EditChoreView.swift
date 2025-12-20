import SwiftUI

struct EditChoreView: View {
    let chore: Chore
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppStateViewModel
    @State private var title: String
    @State private var description: String
    @State private var reward: String
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var recurrenceType: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    init(chore: Chore) {
        self.chore = chore
        _title = State(initialValue: chore.title)
        _description = State(initialValue: chore.detail)
        _reward = State(initialValue: String(format: "%.2f", chore.reward))
        
        // Parse due date if it exists
        if let dueDateString = chore.dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let parsed = formatter.date(from: dueDateString)
            _dueDate = State(initialValue: parsed)
            _hasDueDate = State(initialValue: parsed != nil)
        } else {
            _dueDate = State(initialValue: nil)
            _hasDueDate = State(initialValue: false)
        }
        
        _recurrenceType = State(initialValue: chore.recurrenceType ?? "NONE")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()
                
                Form {
                    Section("Chore Details") {
                        TextField("Title", text: $title)
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                        TextField("Reward ($)", text: $reward)
                            .keyboardType(.decimalPad)
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
                    
                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(AppTheme.Parent.danger)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            Task { await updateChore() }
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save Changes")
                                        .font(AppTheme.Parent.headlineFont)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.Parent.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isSubmitting)
                    }
                }
            }
            .navigationTitle("Edit Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Parent.textPrimary)
                }
            }
        }
    }
    
    private func updateChore() async {
        guard let token = authManager.session?.accessToken else { return }
        if isSubmitting { return }
        isSubmitting = true
        errorMessage = nil
        
        let rewardValue = Double(reward) ?? 0
        if rewardValue <= 0 {
            await MainActor.run {
                errorMessage = "Invalid reward amount"
                isSubmitting = false
            }
            return
        }
        
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
            
            try await appState.updateChore(
                accessToken: token,
                choreId: chore.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                detail: descValue.isEmpty ? nil : descValue,
                rewardDollars: rewardValue,
                dueDateISO: dueDateISO,
                recurrenceType: recurrenceType == "NONE" ? nil : recurrenceType
            )
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

