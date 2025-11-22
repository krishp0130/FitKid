import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAuthOptions = false
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo (KZF)
                AppLogoView()
                    .scaleEffect(bounce ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: bounce
                    )
                    .onAppear {
                        bounce = true
                    }
                
                // App Name
                Text("KZF")
                    .font(.system(size: 48, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                
                // Tagline
                Text("Learn money skills while earning screen time! 🚀")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Auth Button
                Button(action: {
                    withAnimation {
                        showAuthOptions = true
                    }
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.25))
                            .overlay(
                                Capsule()
                                    .stroke(.white, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $showAuthOptions) {
            AuthSelectionView()
                .environmentObject(authManager)
        }
    }
}

// MARK: - App Logo View
struct AppLogoView: View {
    var body: some View {
        ZStack {
            // Rounded square with gradient (Blue to Green)
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.primaryBlue, Color.primaryGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Dollar sign
            Text("$")
                .font(.system(size: 64, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
        }
    }
}
