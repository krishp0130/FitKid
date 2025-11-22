import SwiftUI

// MARK: - Circular Gauge
struct CircularGauge: View {
    var value: Double
    var maxValue: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 14)
            
            Circle()
                .trim(from: 0, to: value / maxValue)
                .stroke(
                    AngularGradient(
                        colors: [Color.kidzoneGreen, Color.kidzoneBlue, Color.kidzonePink],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("Score")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(String(Int(value)))
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    var score: Int
    
    var label: String {
        switch score {
        case ..<580: return "Risky"
        case 580..<670: return "Building"
        case 670..<740: return "Strong"
        case 740..<800: return "Prime"
        default: return "Elite"
        }
    }
    
    var color: Color {
        switch score {
        case ..<580: return Color.kidzoneDanger
        case 580..<670: return Color.kidzoneWarning
        case 670..<740: return Color.kidzoneBlue
        case 740..<800: return Color.kidzoneGreen
        default: return Color.kidzonePink
        }
    }
    
    var body: some View {
        Text(label.uppercased())
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.65))
            .clipShape(Capsule())
    }
}

// MARK: - Metric Pill
struct MetricPill: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Chore Row
struct ChoreRow: View {
    var chore: Chore
    
    var statusColor: Color {
        switch chore.status {
        case .pending: return Color.kidzoneWarning
        case .approved: return Color.kidzoneSuccess
        case .overdue: return Color.kidzoneDanger
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(chore.detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(chore.rewardFormatted)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.kidzoneYellow)
                
                Text(chore.status.label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Extensions
extension Int {
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self / 100)) ?? "$0"
    }
}

extension Double {
    func formatted() -> String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self)) hrs"
        }
        return "\(String(format: "%.1f", self)) hrs"
    }
}


