import SwiftUI

struct ChildWelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var bounceAnimation = false
    
    var body: some View {
        ZStack {
            AppTheme.childGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Welcome Animation
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.kidzoneYellow)
                        .rotationEffect(.degrees(bounceAnimation ? 360 : 0))
                        .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: bounceAnimation
                        )
                    
                    Text("Welcome to Kidzone! 🎉")
                        .font(.system(size: 36, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .onAppear {
                    bounceAnimation = true
                }
                
                VStack(spacing: 16) {
                    FeatureBadge(icon: "creditcard.fill", text: "Get your first credit card")
                    FeatureBadge(icon: "checkmark.circle.fill", text: "Complete chores to earn money")
                    FeatureBadge(icon: "gamecontroller.fill", text: "Buy screen time with your earnings")
                    FeatureBadge(icon: "chart.line.uptrend.xyaxis", text: "Learn about money the fun way!")
                }
                .padding(.vertical, 30)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Text("Let's Go!")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(.white, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.kidzoneYellow)
            
            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.15))
        )
    }
}

