import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    let meeting: Meeting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meeting.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themeTitle()

                detailSection(
                    title: "Summary",
                    body: meeting.summary
                )

                detailSection(
                    title: "Action Items",
                    body: actionItemsText
                )

                detailSection(
                    title: "Decisions",
                    body: decisionsText
                )

                detailSection(
                    title: "Open Questions",
                    body: openQuestionsText
                )

                detailSection(
                    title: "Transcript",
                    body: meeting.transcript
                )
            }
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var actionItemsText: String {
        let lines = meeting.actionItems.map { item in
            "\(item.task) - \(item.owner) (\(item.deadlineText))"
        }

        return lines.isEmpty ? "No action items yet." : lines.joined(separator: "\n")
    }

    private var decisionsText: String {
        let lines = meeting.decisions.map(\.text)
        return lines.isEmpty ? "No decisions yet." : lines.joined(separator: "\n")
    }

    private var openQuestionsText: String {
        let lines = meeting.openQuestions.map(\.text)
        return lines.isEmpty ? "No open questions yet." : lines.joined(separator: "\n")
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
        MeetingDetailView(meeting: SampleMeetingData.previewMeeting)
    }
    .modelContainer(SampleMeetingData.previewContainer)
}
