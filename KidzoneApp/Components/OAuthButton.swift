import SwiftUI

struct OAuthButton: View {
    let provider: AuthProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Provider Icon/Logo
                providerIcon
                    .frame(width: 24, height: 24)
                
                Text("Continue with \(provider.displayName)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.glassBackground(isDark: false))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var providerIcon: some View {
        switch provider {
        case .google:
            // Google logo colors
            ZStack {
                Circle()
                    .fill(Color.white)
                Image(systemName: "globe")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.26, green: 0.52, blue: 0.96), // Blue
                                Color(red: 0.26, green: 0.65, blue: 0.28), // Green
                                Color(red: 0.99, green: 0.76, blue: 0.18), // Yellow
                                Color(red: 0.98, green: 0.38, blue: 0.28)  // Red
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        case .facebook:
            // Facebook logo color
            Image(systemName: "f.circle.fill")
                .foregroundStyle(Color(red: 0.26, green: 0.40, blue: 0.70))
        case .microsoft:
            // Microsoft logo pattern
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.62, blue: 0.24), // Green
                                Color(red: 0.12, green: 0.47, blue: 0.90), // Blue
                                Color(red: 1.0, green: 0.58, blue: 0.0),   // Orange
                                Color(red: 0.92, green: 0.26, blue: 0.21)  // Red
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "m.square.fill")
                    .foregroundStyle(.white)
            }
        case .email:
            Image(systemName: "envelope.fill")
                .foregroundStyle(.white)
        }
    }
}

extension AuthProvider {
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .microsoft: return "Microsoft"
        case .facebook: return "Facebook"
        case .email: return "Email"
        }
    }
}

