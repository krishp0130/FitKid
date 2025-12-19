import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showAuthOptions = false
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            // Neutral welcome gradient (blend of both themes)
            LinearGradient(
                colors: [AppTheme.Child.primary, AppTheme.Child.secondary, Color.parentNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Logo/Icon
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                    .scaleEffect(bounce ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: bounce
                    )
                    .onAppear {
                        bounce = true
                    }
                
                // App Name
                Text("Kidzone")
                    .font(.system(size: 60, design: .rounded).weight(.heavy))
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
                            .fill(.white.opacity(0.2))
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
            AuthenticationView()
        }
    }
}

// MARK: - Button Animation Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

