import SwiftUI
import SwiftData

struct ProcessingView: View {
    @Query(sort: \Meeting.updatedAt, order: .reverse) private var meetings: [Meeting]

    private var activeMeetings: [Meeting] {
        meetings.filter { meeting in
            meeting.processingStatus == .uploading || meeting.processingStatus == .processing
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Processing Queue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themeTitle()

                if meetings.isEmpty {
                    EmptyStateCard(
                        title: "No Meetings In Flight",
                        message: "Recorded meetings will appear here as they move through upload and processing states.",
                        systemImage: "waveform.and.magnifyingglass"
                    )
                } else {
                    if activeMeetings.isEmpty {
                        EmptyStateCard(
                            title: "Nothing Is Processing Right Now",
                            message: "You can still review completed meetings in History while new uploads wait to start.",
                            systemImage: "checkmark.circle"
                        )
                    }

                    ForEach(meetings) { meeting in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(meeting.title)
                                    .font(.headline)
                                    .themeTitle()
                                Spacer()
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
                            }

                            if meeting.processingStatus == .uploading || meeting.processingStatus == .processing {
                                ProgressView()
                                    .tint(meeting.processingStatus.accentColor)

                                SkeletonParagraph(widths: [230, 190, 160])
                                    .padding(.top, 4)
                            }

                            Text(meeting.processingStatus.detailMessage)
                                .themeSecondaryText()
                        }
                        .liquidGlassCard()
                    }
                }
            }
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
        .navigationTitle("Processing")
    }
}

#Preview {
    NavigationStack {
        ProcessingView()
    }
    .modelContainer(SampleMeetingData.previewContainer)
}
