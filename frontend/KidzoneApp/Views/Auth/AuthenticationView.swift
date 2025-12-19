import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var selectedProvider: AuthProvider?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Neutral auth gradient
            LinearGradient(
                colors: [AppTheme.Child.primary, AppTheme.Child.secondary, Color.parentNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
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
                Text("Sign In")
                    .font(.system(size: 48, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                
                Text("Choose how you want to sign in")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 16) {
                    OAuthButton(
                        provider: .google,
                        icon: "g.circle.fill",
                        color: .white,
                        isLoading: isLoading && selectedProvider == .google,
                        disabled: false
                    ) {
                        signIn(with: .google)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                Spacer()
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "Something went wrong. Please try again.")
        }
    }
    
    private func signIn(with provider: AuthProvider) {
        selectedProvider = provider
        isLoading = true
        
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

struct OAuthButton: View {
    let provider: AuthProvider
    let icon: String
    let color: Color
    let isLoading: Bool
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                
                Text("Continue with \(provider.rawValue.capitalized)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                
                Spacer()
            }
            .foregroundStyle(color)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading || disabled)
    }
}

// Apple button removed; Google is the primary path now.
