import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            AppLogoView()
                            
                            Text("Log In")
                                .font(.system(size: 42, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                            
                            Text("Welcome back!")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        
                        // Email/Password Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                TextField("you@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding(16)
                                    .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .padding(16)
                                    .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                            
                            // Login Button
                            Button(action: loginWithEmail) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Log In")
                                        .font(.system(.title3, design: .rounded).weight(.bold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white, lineWidth: 2)
                            )
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                            
                            // Forgot Password
                            Button(action: {}) {
                                Text("Forgot Password?")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                        
                        // OAuth Buttons
                        VStack(spacing: 12) {
                            OAuthButton(provider: .google, action: {
                                loginWithOAuth(.google)
                            })
                            
                            OAuthButton(provider: .facebook, action: {
                                loginWithOAuth(.facebook)
                            })
                            
                            OAuthButton(provider: .microsoft, action: {
                                loginWithOAuth(.microsoft)
                            })
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                    .padding(.vertical, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .alert("Login Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loginWithEmail() {
        isLoading = true
        errorMessage = ""
        
        // Validate email format
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            showError = true
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            isLoading = false
            return
        }
        
        // TODO: Actual API call
        // For now, mock authentication
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isLoading = false
            
            // Mock successful login
            let user = User(
                id: UUID().uuidString,
                username: email.components(separatedBy: "@").first ?? "User",
                email: email,
                role: .none, // Will select role next
                familyId: "",
                currentCreditScore: 300,
                parentCode: nil
            )
            
            authManager.currentUser = user
            authManager.authToken = "mock_token_\(UUID().uuidString)"
            authManager.isAuthenticated = true
            
            dismiss()
        }
    }
    
    private func loginWithOAuth(_ provider: AuthProvider) {
        isLoading = true
        authManager.signIn(with: provider) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

