import SwiftUI

struct MeetingDetailView: View {
    let meetingTitle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meetingTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themeTitle()

                detailSection(
                    title: "Summary",
                    body: "Meeting summary will appear here after processing."
                )

                detailSection(
                    title: "Action Items",
                    body: "No action items yet."
                )

                detailSection(
                    title: "Decisions",
                    body: "No decisions yet."
                )

                detailSection(
                    title: "Transcript",
                    body: "Transcript content will be shown here."
                )
            }
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .themeTitle()
            Text(body)
                .themeSecondaryText()
        }
        .liquidGlassCard()
    }
}

#Preview {
    NavigationStack {
        MeetingDetailView(meetingTitle: "Weekly Product Sync")
    }
}
