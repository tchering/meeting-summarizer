import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.02, green: 0.05, blue: 0.10)
    static let backgroundMiddle = Color(red: 0.05, green: 0.14, blue: 0.24)
    static let backgroundBottom = Color(red: 0.07, green: 0.25, blue: 0.34)

    static let glowPrimary = Color(red: 0.10, green: 0.62, blue: 0.78)
    static let glowSecondary = Color(red: 0.28, green: 0.42, blue: 0.82)

    static let surfaceFill = Color(red: 0.08, green: 0.14, blue: 0.22).opacity(0.78)
    static let elevatedSurfaceFill = Color(red: 0.11, green: 0.18, blue: 0.27).opacity(0.84)
    static let surfaceStroke = Color.white.opacity(0.14)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.82)
    static let mutedText = Color.white.opacity(0.60)
    static let accent = Color(red: 0.54, green: 0.88, blue: 0.97)
    static let accentStrong = Color(red: 0.28, green: 0.72, blue: 0.96)

    static let cornerRadius: CGFloat = 24
    static let contentPadding: CGFloat = 20

    static let mainBackground = LinearGradient(
        colors: [backgroundTop, backgroundMiddle, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            AppTheme.mainBackground

            Circle()
                .fill(AppTheme.glowPrimary.opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: 150, y: -220)

            Circle()
                .fill(AppTheme.glowSecondary.opacity(0.22))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: -130, y: 260)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct ThemeTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppTheme.primaryText)
    }
}

struct ThemeSecondaryTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppTheme.secondaryText)
    }
}

struct ThemeMutedTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppTheme.mutedText)
    }
}

extension View {
    func appScreenBackground() -> some View {
        background(AppScreenBackground())
    }

    func themeTitle() -> some View {
        modifier(ThemeTitleModifier())
    }

    func themeSecondaryText() -> some View {
        modifier(ThemeSecondaryTextModifier())
    }

    func themeMutedText() -> some View {
        modifier(ThemeMutedTextModifier())
    }
}
