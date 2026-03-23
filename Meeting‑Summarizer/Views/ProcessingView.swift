import SwiftUI
import SwiftData

struct ProcessingView: View {
    @Query(sort: \Meeting.updatedAt, order: .reverse) private var meetings: [Meeting]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Processing Queue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themeTitle()

                if meetings.isEmpty {
                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppTheme.accent)

                        Text("No meetings yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .themeTitle()

                        Text("Recorded meetings will appear here as they move through upload and processing states.")
                            .multilineTextAlignment(.center)
                            .themeSecondaryText()
                    }
                    .liquidGlassCard()
                } else {
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
