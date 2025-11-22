import SwiftUI

struct ParentChoresView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var showAddChore = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.parentGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(appState.state.chores) { chore in
                            ParentChoreCard(chore: chore)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddChore = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.white)
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
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                
                Text(chore.detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text("Reward: \(chore.rewardFormatted)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.kidzoneYellow)
            }
            
            Spacer()
            
            Text(chore.status.label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
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
                AppTheme.parentGradient
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
                }
            }
        }
    }
}

