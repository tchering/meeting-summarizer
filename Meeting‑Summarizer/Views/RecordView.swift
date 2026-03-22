import SwiftUI

struct RecordView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Record Meeting", systemImage: "mic.fill")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Recording controls will be added in Phase 2.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .navigationTitle("Record")
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
}
