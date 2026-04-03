// EmptyStateView.swift
// ClassWiz

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primary.opacity(0.5))
                .padding(.bottom, AppTheme.spacingSM)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacingXL)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(CWSecondaryButtonStyle())
                .padding(.horizontal, AppTheme.spacingXL)
                .padding(.top, AppTheme.spacingSM)
            }
        }
        .padding(AppTheme.spacingXL)
    }
}

#Preview {
    EmptyStateView(
        icon: "tray",
        title: "No Data Yet",
        subtitle: "There's nothing to show here right now.",
        actionTitle: "Refresh",
        action: {}
    )
}
