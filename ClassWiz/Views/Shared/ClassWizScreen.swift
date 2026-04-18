import SwiftUI

struct ClassWizTopBar: View {
    let title: String
    let subtitle: String?
    let showNotification: Bool
    let showProfile: Bool
    let showBackButton: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(title: String, subtitle: String? = nil, showNotification: Bool = true, showProfile: Bool = true, showBackButton: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.showNotification = showNotification
        self.showProfile = showProfile
        self.showBackButton = showBackButton
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showBackButton {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AppTheme.surfaceSecondary))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.primary, AppTheme.secondary], startPoint: .leading, endPoint: .trailing)
                    )
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundColor(AppTheme.textSecondary)
                        .textCase(.uppercase)
                }
            }
        
            Spacer()
            
            HStack(spacing: 8) {
                if showNotification {
                    NavigationLink(destination: NotificationView()) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppTheme.surfaceSecondary))
                    }
                }
                
                if showProfile {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppTheme.surfaceSecondary))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
                .shadow(color: Color.black.opacity(0.04), radius: 30, x: 0, y: 8)
        )
    }
}

struct ClassWizBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
        }
    }
}

public struct CWTabBarItem: Equatable, Hashable {
    public let id: Int
    public let title: String
    public let icon: String
    public let selectedIcon: String

    public init(id: Int, title: String, icon: String, selectedIcon: String) {
        self.id = id
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
    }
}

struct ClassWizTabBar: View {
    let items: [CWTabBarItem]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.id) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item.id
                    }
                }) {
                    let isSelected = selection == item.id
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? item.selectedIcon : item.icon)
                            .font(.system(size: 24, weight: isSelected ? .bold : .regular))
                        Text(item.title)
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.textSecondary.opacity(0.7))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? Capsule().fill(AppTheme.primary.opacity(0.15)) : Capsule().fill(Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(AppTheme.surface.opacity(0.95))
                .background(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}

struct ClassWizScreen<Content: View>: View {
    let scrollable: Bool
    let title: String
    let subtitle: String?
    let showNotification: Bool
    let showProfile: Bool
    let showBackButton: Bool
    let content: Content

    init(title: String, subtitle: String? = nil, showNotification: Bool = true, showProfile: Bool = true, showBackButton: Bool = false, scrollable: Bool = true, @ViewBuilder content: () -> Content) {
        self.scrollable = scrollable
        self.title = title
        self.subtitle = subtitle
        self.showNotification = showNotification
        self.showProfile = showProfile
        self.showBackButton = showBackButton
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            ClassWizBackground()
            
            if scrollable {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: 80)
                        content
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 80)
                    content
                    Color.clear.frame(height: 120)
                }
            }
            
            ClassWizTopBar(title: title, subtitle: subtitle, showNotification: showNotification, showProfile: showProfile, showBackButton: showBackButton)
        }
        .navigationBarHidden(true)
    }
}
