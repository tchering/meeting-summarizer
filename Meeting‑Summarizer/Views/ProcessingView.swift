import SwiftUI

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Processing Meeting")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Upload and AI processing states will be connected in later phases.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Processing")
    }
}

#Preview {
    NavigationStack {
        ProcessingView()
    }
}
