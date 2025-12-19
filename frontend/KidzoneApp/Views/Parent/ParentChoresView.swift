import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showAddChore = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Parent.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Parent.cardSpacing) {
                        ForEach(appState.state.chores) { chore in
                            ParentChoreCard(chore: chore)
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
        }
    }
}

struct ParentChoreCard: View {
    let chore: Chore

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
    @State private var title = ""
    @State private var description = ""
    @State private var reward = ""

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
                        Button("Create Chore") {
                            // TODO: Create chore
                            dismiss()
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
        }
    }
}

