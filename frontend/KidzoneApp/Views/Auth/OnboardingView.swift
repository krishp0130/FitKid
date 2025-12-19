import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showParent = false
    @State private var showChild = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.Child.primary, AppTheme.Child.secondary, Color.parentNavy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Choose your role")
                        .font(.system(size: 32, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)

                    OnboardingRoleCard(
                        title: "Parent",
                        description: "Create a family and manage settings",
                        action: { showParent = true }
                    )

                    OnboardingRoleCard(
                        title: "Child",
                        description: "Join your family to earn and spend",
                        action: { showChild = true }
                    )
                }
                .padding()
            }
            .sheet(isPresented: $showParent) {
                ParentOnboardingSheet()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showChild) {
                ChildOnboardingSheet()
                    .environmentObject(authManager)
            }
        }
    }
}

private struct OnboardingRoleCard: View {
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.2))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct ParentOnboardingSheet: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var familyName: String = "My Family"
    @State private var username: String = ""
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Family")) {
                    TextField("Family name", text: $familyName)
                }
                Section(header: Text("Parent name")) {
                    TextField("Your name", text: $username)
                }
                if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                }
                Button {
                    submit()
                } label: {
                    HStack {
                        if isSubmitting { ProgressView() }
                        Text("Create Family")
                    }
                }
                .disabled(isSubmitting || familyName.isEmpty || username.isEmpty)
            }
            .navigationTitle("Parent Setup")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        error = nil
        authManager.onboardParent(familyName: familyName, username: username) { result in
            isSubmitting = false
            switch result {
            case .success:
                dismiss()
            case .failure(let err):
                error = err.localizedDescription
            }
        }
    }
}

private struct ChildOnboardingSheet: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var familyId: String = ""
    @State private var username: String = ""
    @State private var isSubmitting = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Family Code")) {
                    TextField("Family ID", text: $familyId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section(header: Text("Your name")) {
                    TextField("Child name", text: $username)
                }
                if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                }
                Button {
                    submit()
                } label: {
                    HStack {
                        if isSubmitting { ProgressView() }
                        Text("Join Family")
                    }
                }
                .disabled(isSubmitting || familyId.isEmpty || username.isEmpty)
            }
            .navigationTitle("Join Family")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        error = nil
        authManager.onboardChild(familyId: familyId, username: username) { result in
            isSubmitting = false
            switch result {
            case .success:
                dismiss()
            case .failure(let err):
                error = err.localizedDescription
            }
        }
    }
}
