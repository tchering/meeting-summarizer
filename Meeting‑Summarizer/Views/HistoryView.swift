import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .themeTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if meetings.isEmpty {
                        EmptyStateCard(
                            title: "No Meetings Yet",
                            message: "Recorded and imported meetings will appear here once they are saved to the app.",
                            systemImage: "clock.arrow.circlepath"
                        )
                    } else {
                        ForEach(meetings) { meeting in
                            NavigationLink {
                                MeetingDetailView(meeting: meeting)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(meeting.title)
                                            .font(.headline)
                                            .themeTitle()
                                        Text(meeting.summary.isEmpty ? meeting.processingStatus.detailMessage : meeting.summary)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                            .themeSecondaryText()
                                        Text(meeting.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.accent)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 10) {
                                        Text(meeting.processingStatus.displayTitle)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(meeting.processingStatus.accentColor.opacity(0.18))
                                            )
                                            .overlay(
                                                Capsule(style: .continuous)
                                                    .stroke(meeting.processingStatus.accentColor.opacity(0.35), lineWidth: 1)
                                            )
                                            .foregroundStyle(meeting.processingStatus.accentColor)

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .liquidGlassCard()
                        }
                    }
                }
                .padding(AppTheme.contentPadding)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(SampleMeetingData.previewContainer)
}
