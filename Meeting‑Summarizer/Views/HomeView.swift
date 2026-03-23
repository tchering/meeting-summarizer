import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home")
                            .font(.system(size: 18, weight: .semibold))
                            .themeSecondaryText()
                        Text("Meeting Summarizer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .themeTitle()
                        Text("Capture meetings, track progress, and review summaries from one place.")
                            .themeSecondaryText()
                    }

                    NavigationLink {
                        RecordView()
                    } label: {
                        Label("Record a Meeting", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .liquidGlassButtonStyle()

                    NavigationLink {
                        ProcessingView()
                    } label: {
                        Label("View Processing State", systemImage: "waveform.badge.magnifyingglass")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .liquidGlassButtonStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent")
                            .font(.headline)
                            .themeTitle()
                        if let recentMeeting = meetings.first {
                            NavigationLink {
                                MeetingDetailView(meeting: recentMeeting)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recentMeeting.title)
                                        .font(.headline)
                                        .themeTitle()
                                    Text(recentMeeting.summary)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                        .themeSecondaryText()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Sample meetings will appear here.")
                                .themeSecondaryText()
                        }
                    }
                    .liquidGlassCard()
                }
                .padding(AppTheme.contentPadding)
            }
            .scrollContentBackground(.hidden)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let recentMeeting = meetings.first {
                        NavigationLink {
                            MeetingDetailView(meeting: recentMeeting)
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(10)
                        }
                        .liquidGlassCard()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(SampleMeetingData.previewContainer)
}
