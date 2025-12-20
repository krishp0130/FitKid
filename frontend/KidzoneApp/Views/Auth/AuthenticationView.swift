import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var selectedProvider: AuthProvider?
    @State private var showError = false
    @State private var isSignUp = false // Toggle between sign-in and sign-up
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showEmailForm = false
    
    var body: some View {
        ZStack {
            // Neutral auth gradient
            LinearGradient(
                colors: [AppTheme.Child.primary, AppTheme.Child.secondary, Color.parentNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Title
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.system(size: 48, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                
                Text(isSignUp ? "Create a new account" : "Choose how you want to sign in")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                if showEmailForm {
                    // Email/Password Form
                    emailPasswordForm
                } else {
                    // OAuth Buttons
                    oAuthButtons
                }
                
                Spacer()
                
                // Toggle between email form and OAuth, and between sign-in/sign-up
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            showEmailForm.toggle()
                        }
                    }) {
                        Text(showEmailForm ? "Use Google/Apple instead" : "Use email instead")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            email = ""
                            password = ""
                            confirmPassword = ""
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "Something went wrong. Please try again.")
        }
    }
    
    private var emailPasswordForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(.white.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
            
            SecureField("Password", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding()
                .background(.white.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
            
            if isSignUp {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Button(action: {
                Task {
                    await handleEmailAuth()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.3))
                )
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty))
        }
        .padding(.horizontal, 40)
    }
    
    private var oAuthButtons: some View {
        VStack(spacing: 16) {
            GoogleAuthButton(
                isLoading: isLoading && selectedProvider == .google,
                isSignUp: isSignUp
            ) {
                handleOAuth(with: .google)
            }

            AppleAuthButton(
                isLoading: isLoading && selectedProvider == .apple,
                isSignUp: isSignUp
            ) {
                handleOAuth(with: .apple)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func handleEmailAuth() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        if isSignUp {
            guard password == confirmPassword else {
                await MainActor.run {
                    authManager.errorMessage = "Passwords do not match"
                    showError = true
                }
                return
            }
            guard password.count >= 6 else {
                await MainActor.run {
                    authManager.errorMessage = "Password must be at least 6 characters"
                    showError = true
                }
                return
            }
        }
        
        isLoading = true
        authManager.errorMessage = nil
        
        do {
            let _: User
            if isSignUp {
                _ = try await authManager.signUpWithEmail(email: email, password: password)
            } else {
                _ = try await authManager.signInWithEmail(email: email, password: password)
            }
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                authManager.errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleOAuth(with provider: AuthProvider) {
        selectedProvider = provider
        isLoading = true
        
        if isSignUp {
            authManager.signUp(with: provider) { result in
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure:
                    showError = true
                }
            }
        } else {
            authManager.signIn(with: provider) { result in
                isLoading = false
                switch result {
                case .success:
                    dismiss()
                case .failure:
                    showError = true
                }
            }
        }
    }
}

struct GoogleAuthButton: View {
    let isLoading: Bool
    let isSignUp: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    // Standard Google Logo - matches official Google sign-in button
                    GoogleLogoView()
                        .frame(width: 18, height: 18)
                }
                
                Text(isSignUp ? "Sign up with Google" : "Continue with Google")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 0.26, green: 0.26, blue: 0.26))
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// Standard Google Logo View - matches the official Google sign-in button design
struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            // White background circle
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
            
            // Google "G" logo - official colors and proportions
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                
                ZStack {
                    // Blue arc (top-right quadrant)
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: size/2, y: size/2),
                            radius: size/2 - 1,
                            startAngle: .degrees(-45),
                            endAngle: .degrees(45),
                            clockwise: false
                        )
                    }
                    .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 2.2)
                    
                    // Red arc (right side)
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: size/2, y: size/2),
                            radius: size/2 - 1,
                            startAngle: .degrees(45),
                            endAngle: .degrees(90),
                            clockwise: false
                        )
                    }
                    .stroke(Color(red: 0.91, green: 0.26, blue: 0.21), lineWidth: 2.2)
                    
                    // Yellow arc (left side)
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: size/2, y: size/2),
                            radius: size/2 - 1,
                            startAngle: .degrees(135),
                            endAngle: .degrees(225),
                            clockwise: false
                        )
                    }
                    .stroke(Color(red: 0.99, green: 0.75, blue: 0.18), lineWidth: 2.2)
                    
                    // Green arc (bottom-right)
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: size/2, y: size/2),
                            radius: size/2 - 1,
                            startAngle: .degrees(270),
                            endAngle: .degrees(315),
                            clockwise: false
                        )
                    }
                    .stroke(Color(red: 0.14, green: 0.65, blue: 0.38), lineWidth: 2.2)
                    
                    // Horizontal line to complete the "G" (extends from center-right)
                    Path { path in
                        let centerX = size/2
                        let centerY = size/2
                        let radius = size/2 - 1
                        let startX = centerX + radius * cos(45 * .pi / 180)
                        let startY = centerY + radius * sin(45 * .pi / 180)
                        path.move(to: CGPoint(x: startX, y: startY))
                        path.addLine(to: CGPoint(x: size - 1, y: startY))
                    }
                    .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 2.2)
                }
            }
        }
        .frame(width: 18, height: 18)
    }
}

struct AppleAuthButton: View {
    let isLoading: Bool
    let isSignUp: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(isSignUp ? "Sign up with Apple" : "Continue with Apple")
                    .font(.system(.headline, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}
