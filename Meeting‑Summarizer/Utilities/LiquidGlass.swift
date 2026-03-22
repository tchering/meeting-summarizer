import SwiftUI

struct LiquidGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardStroke)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(Color.white.opacity(0.06)).interactive(), in: .rect(cornerRadius: AppTheme.cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                        .fill(AppTheme.surfaceFill)
                )
        }
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
            .stroke(AppTheme.surfaceStroke, lineWidth: 1)
    }
}

struct LiquidGlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(AppTheme.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(buttonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(AppTheme.accent.opacity(0.14)).interactive(), in: .rect(cornerRadius: 18))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surfaceFill)
        }
    }
}

extension View {
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCardModifier())
    }

    @ViewBuilder
    func liquidGlassButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            modifier(LiquidGlassButtonModifier())
        } else {
            modifier(LiquidGlassButtonModifier())
        }
    }
}
