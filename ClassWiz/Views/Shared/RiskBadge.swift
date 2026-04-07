// RiskBadge.swift
// ClassWiz

import SwiftUI

enum RiskLevel: String, Codable, CaseIterable {
    case safe     = "safe"
    case warning  = "warning"
    case critical = "critical"

    var label: String {
        switch self {
        case .safe:     return "Safe"
        case .warning:  return "Warning"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .safe:     return "checkmark.shield.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .safe:     return AppTheme.safe
        case .warning:  return AppTheme.warning
        case .critical: return AppTheme.critical
        }
    }

    static func from(percentage: Double) -> RiskLevel {
        if percentage >= 80 { return .safe }
        if percentage >= 75 { return .warning }
        return .critical
    }
}

struct RiskBadge: View {
    let level: RiskLevel
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(compact ? .caption2 : .caption)

            if !compact {
                Text(level.label)
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundColor(level.color)
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(
            Capsule()
                .fill(level.color.opacity(0.12))
        )
    }
}

#Preview("Risk Badges") {
    VStack(spacing: 16) {
        RiskBadge(level: .safe)
        RiskBadge(level: .warning)
        RiskBadge(level: .critical)
        HStack(spacing: 8) {
            RiskBadge(level: .safe, compact: true)
            RiskBadge(level: .warning, compact: true)
            RiskBadge(level: .critical, compact: true)
        }
    }
    .padding()
    .background(AppTheme.background)
}
