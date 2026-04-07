// OfflineBanner.swift
// ClassWiz

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.semibold))

            Text("You're offline — showing cached data")
                .font(.caption.weight(.medium))

            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
        .padding(.top, safeAreaTop)
        .background(AppTheme.warning.opacity(0.9).ignoresSafeArea(edges: .top))
    }

    private var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top ?? 0)
    }
}

#Preview {
    OfflineBanner()
}

#Preview {
    OfflineBanner()
}
