import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.03, green: 0.06, blue: 0.12)
    static let backgroundMiddle = Color(red: 0.06, green: 0.16, blue: 0.26)
    static let backgroundBottom = Color(red: 0.10, green: 0.34, blue: 0.42)

    static let glowPrimary = Color(red: 0.24, green: 0.82, blue: 0.87)
    static let glowSecondary = Color(red: 0.49, green: 0.64, blue: 0.97)

    static let surfaceFill = Color.white.opacity(0.10)
    static let surfaceStroke = Color.white.opacity(0.18)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.72)
    static let accent = Color(red: 0.53, green: 0.86, blue: 0.96)
    static let accentStrong = Color(red: 0.31, green: 0.71, blue: 0.96)

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
                colors: [.clear, Color.black.opacity(0.18)],
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
}
