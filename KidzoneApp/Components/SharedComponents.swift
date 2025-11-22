import SwiftUI

// MARK: - Circular Gauge
struct CircularGauge: View {
    var value: Double
    var maxValue: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.Child.textSecondary.opacity(0.3), lineWidth: 14)

            Circle()
                .trim(from: 0, to: value / maxValue)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.Child.success, AppTheme.Child.primary, AppTheme.Child.secondary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("Score")
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
                Text(String(Int(value)))
                    .font(AppTheme.Child.headlineFont.weight(.heavy))
                    .foregroundStyle(AppTheme.Child.textPrimary)
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
        case ..<580: return AppTheme.Child.danger
        case 580..<670: return AppTheme.Child.warning
        case 670..<740: return AppTheme.Child.secondary
        case 740..<800: return AppTheme.Child.success
        default: return AppTheme.Child.primary
        }
    }

    var body: some View {
        Text(label.uppercased())
            .font(AppTheme.Child.captionFont.weight(.bold))
            .foregroundStyle(AppTheme.Child.textPrimary)
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
                .font(AppTheme.Child.captionFont)
                .foregroundStyle(AppTheme.Child.textSecondary)
            Text(value)
                .font(AppTheme.Child.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.Child.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.Child.textPrimary.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Chore Row
struct ChoreRow: View {
    var chore: Chore

    var statusColor: Color {
        switch chore.status {
        case .pending: return AppTheme.Child.warning
        case .approved: return AppTheme.Child.success
        case .overdue: return AppTheme.Child.danger
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(AppTheme.Child.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.Child.textPrimary)

                Text(chore.detail)
                    .font(AppTheme.Child.captionFont)
                    .foregroundStyle(AppTheme.Child.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(chore.rewardFormatted)
                    .font(AppTheme.Child.bodyFont.weight(.bold))
                    .foregroundStyle(AppTheme.Child.accent)

                Text(chore.status.label)
                    .font(AppTheme.Child.captionFont.weight(.bold))
                    .foregroundStyle(AppTheme.Child.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(AppTheme.Child.textPrimary.opacity(0.05))
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


