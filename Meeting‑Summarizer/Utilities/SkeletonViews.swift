import SwiftUI

struct SkeletonBlock: View {
    let width: CGFloat?
    let height: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat = 14) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.elevatedSurfaceFill.opacity(0.55),
                        AppTheme.surfaceStroke.opacity(0.95),
                        AppTheme.elevatedSurfaceFill.opacity(0.55)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .opacity(isAnimating ? 1 : 0.58)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct SkeletonParagraph: View {
    let widths: [CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, width in
                SkeletonBlock(width: width, height: 13)
            }
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.title3.weight(.semibold))
                .themeTitle()

            Text(message)
                .themeSecondaryText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard()
    }
}
