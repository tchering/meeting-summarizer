import SwiftUI

struct AppErrorCard: View {
    let error: AppErrorState
    let actionHandler: (AppErrorAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)

                Text(error.title)
                    .font(.headline)
                    .themeTitle()
            }

            Text(error.message)
                .font(.subheadline)
                .themeSecondaryText()

            if let action = error.action, let actionLabel = error.actionLabel {
                Button(actionLabel) {
                    actionHandler(action)
                }
                .liquidGlassButtonStyle()
            }
        }
        .liquidGlassCard()
    }
}
