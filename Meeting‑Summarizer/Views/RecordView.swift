import SwiftUI

struct RecordView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Record Meeting", systemImage: "mic.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themeTitle()

                Text("Recording controls will be added in Phase 2.")
                    .themeSecondaryText()
            }
            .liquidGlassCard()

            VStack(alignment: .leading, spacing: 10) {
                Text("Ready")
                    .font(.headline)
                    .themeTitle()
                Text("Tap start when microphone permissions and recording flow are added.")
                    .themeSecondaryText()
            }
            .liquidGlassCard()

            Button {
            } label: {
                Label("Start Placeholder", systemImage: "record.circle")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppTheme.contentPadding)
        .appScreenBackground()
        .navigationTitle("Record")
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
}
