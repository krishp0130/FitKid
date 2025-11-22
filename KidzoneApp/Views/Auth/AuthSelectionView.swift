import SwiftUI

struct AuthSelectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    // Logo
                    AppLogoView()
                        .padding(.bottom, 20)
                    
                    // Title
                    Text("Welcome to KZF")
                        .font(.system(size: 36, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                    
                    Text("Choose how you'd like to continue")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Auth Option Buttons
                    VStack(spacing: 16) {
                        // Login Button
                        Button(action: {
                            showLogin = true
                        }) {
                            HStack {
                                Text("Log In")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(AppTheme.glassBackground(isDark: false))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Sign Up Button
                        Button(action: {
                            showSignUp = true
                        }) {
                            HStack {
                                Text("Sign Up")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(AppTheme.glassBackground(isDark: false))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
    }
}

