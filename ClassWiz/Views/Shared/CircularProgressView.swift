// CircularProgressView.swift
// ClassWiz

import SwiftUI

struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat = 10
    var size: CGFloat = 100
    var showPercentage: Bool = true
    var riskLevel: RiskLevel?

    private var displayColor: Color {
        if let riskLevel { return riskLevel.color }
        return RiskLevel.from(percentage: progress * 100).color
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(displayColor.opacity(0.15), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    displayColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.defaultAnimation, value: progress)

            // Center text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("%")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("Circular Progress") {
    HStack(spacing: 24) {
        CircularProgressView(progress: 0.92, size: 80)
        CircularProgressView(progress: 0.77, size: 80)
        CircularProgressView(progress: 0.60, size: 80)
    }
    .padding()
    .background(AppTheme.background)
}
