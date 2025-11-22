import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedRole: UserRole?
    @State private var parentCode = ""
    @State private var showCodeInput = false
    @State private var codeError = false
    @State private var showChildWelcome = false
    
    var body: some View {
        ZStack {
            // Neutral gradient for role selection (blend of both themes)
            LinearGradient(
                colors: [Color.parentNavy, AppTheme.Child.primary, AppTheme.Child.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text("Who are you?")
                    .font(.system(size: 42, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)

                Text("Choose your role to get started")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                // Role Selection Cards
                VStack(spacing: 20) {
                    RoleCard(
                        role: .parent,
                        icon: "person.fill.checkmark",
                        title: "I'm a Parent",
                        description: "Manage chores, approve rewards, and monitor progress",
                        isSelected: selectedRole == .parent
                    ) {
                        withAnimation {
                            selectedRole = .parent
                            showCodeInput = false
                        }
                    }
                    
                    RoleCard(
                        role: .child,
                        icon: "person.fill",
                        title: "I'm a Kid",
                        description: "Earn rewards, learn about money, and unlock screen time",
                        isSelected: selectedRole == .child
                    ) {
                        withAnimation {
                            selectedRole = .child
                            showCodeInput = true
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // Parent Code Input (for children)
                if showCodeInput && selectedRole == .child {
                    VStack(spacing: 12) {
                        Text("Enter your parent's code")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        TextField("ABC123", text: $parentCode)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(codeError ? .red : .white.opacity(0.3), lineWidth: 2)
                                    )
                            )
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        
                        if codeError {
                            Text("Invalid code. Please check with your parent.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Continue Button
                if selectedRole != nil {
                    Button(action: continueAction) {
                        HStack {
                            Text("Continue")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(.white, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showChildWelcome) {
            ChildWelcomeView()
        }
    }
    
    private func continueAction() {
        guard let role = selectedRole else { return }
        
        if role == .child {
            // Validate parent code
            if authManager.validateParentCode(parentCode) {
                authManager.updateUserRole(role, parentCode: parentCode.uppercased())
                showChildWelcome = true
            } else {
                codeError = true
            }
        } else {
            // Parent doesn't need code
            authManager.updateUserRole(role)
        }
    }
}

struct RoleCard: View {
    let role: UserRole
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? .white.opacity(0.3) : .white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? .white : .white.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

