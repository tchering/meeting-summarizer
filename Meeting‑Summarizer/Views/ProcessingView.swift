import SwiftUI

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppTheme.accent)

                Text("Processing Meeting")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .themeTitle()

                Text("Upload and AI processing states will be connected in later phases.")
                    .multilineTextAlignment(.center)
                    .themeSecondaryText()
            }
            .liquidGlassCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.contentPadding)
        .appScreenBackground()
        .navigationTitle("Processing")
    }
}

#Preview {
    NavigationStack {
        ProcessingView()
    }
}
