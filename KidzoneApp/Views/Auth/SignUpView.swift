import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var emailExists = false
    
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
                            
                            Text("Sign Up")
                                .font(.system(size: 42, design: .rounded).weight(.heavy))
                                .foregroundStyle(.white)
                            
                            Text("Create your account")
                                .font(.system(.title3, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                TextField("Choose a username", text: $username)
                                    .textContentType(.username)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding(16)
                                    .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                            
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
                                    .onChange(of: email) { _ in
                                        checkEmailExists()
                                    }
                                
                                if emailExists {
                                    Text("This email is already registered")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                SecureField("At least 8 characters", text: $password)
                                    .textContentType(.newPassword)
                                    .padding(16)
                                    .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    PasswordStrengthView(password: password)
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                SecureField("Re-enter your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding(16)
                                    .background(AppTheme.glassBackground(isDark: colorScheme == .dark))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            // Terms and Conditions
                            HStack(spacing: 8) {
                                Text("By signing up, you agree to our")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                Button("Terms & Privacy") {
                                    // TODO: Show terms
                                }
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                            }
                            
                            // Sign Up Button
                            Button(action: signUpWithEmail) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
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
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
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
                                signUpWithOAuth(.google)
                            })
                            
                            OAuthButton(provider: .facebook, action: {
                                signUpWithOAuth(.facebook)
                            })
                            
                            OAuthButton(provider: .microsoft, action: {
                                signUpWithOAuth(.microsoft)
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
            .alert("Sign Up Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        email.contains("@") && email.contains(".") &&
        !emailExists &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    private func checkEmailExists() {
        // TODO: Check against backend
        // For now, mock check
        emailExists = false
    }
    
    private func signUpWithEmail() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        // Check if email exists (duplicate prevention)
        // TODO: Actual API call to check email
        checkEmailExists()
        
        if emailExists {
            errorMessage = "This email is already registered. Please log in instead."
            showError = true
            isLoading = false
            return
        }
        
        // Validate password strength
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            isLoading = false
            return
        }
        
        // TODO: Actual API call to create account
        // For now, mock signup
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isLoading = false
            
            // Mock successful signup
            let user = User(
                id: UUID().uuidString,
                username: username,
                email: email,
                role: .none, // Will be set during role selection
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
    
    private func signUpWithOAuth(_ provider: AuthProvider) {
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

// MARK: - Password Strength Indicator
struct PasswordStrengthView: View {
    let password: String
    
    var strength: PasswordStrength {
        if password.count < 8 { return .weak }
        if password.count < 12 { return .medium }
        if password.range(of: #"[A-Z]"#, options: .regularExpression) != nil &&
           password.range(of: #"[0-9]"#, options: .regularExpression) != nil {
            return .strong
        }
        return .medium
    }
    
    enum PasswordStrength {
        case weak, medium, strong
        
        var color: Color {
            switch self {
            case .weak: return .danger
            case .medium: return .warning
            case .strong: return .success
            }
        }
        
        var label: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
        
        var width: CGFloat {
            switch self {
            case .weak: return 0.33
            case .medium: return 0.66
            case .strong: return 1.0
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Strength: \(strength.label)")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(strength.color)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.width, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

