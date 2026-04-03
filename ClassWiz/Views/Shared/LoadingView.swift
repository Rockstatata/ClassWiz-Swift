// LoadingView.swift
// ClassWiz

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: AppTheme.spacingLG) {
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)

                    // Icon
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.primaryGradient)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: AppTheme.spacingSM) {
                    Text("ClassWiz")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Loading your dashboard...")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

#Preview("Loading – Light") {
    LoadingView()
}

#Preview("Loading – Dark") {
    LoadingView()
        .preferredColorScheme(.dark)
}
