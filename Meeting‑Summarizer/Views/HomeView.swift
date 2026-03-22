import SwiftUI

struct HomeView: View {
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
                        NavigationLink {
                            MeetingDetailView(meetingTitle: "Weekly Product Sync")
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Weekly Product Sync")
                                    .font(.headline)
                                    .themeTitle()
                                Text("Summary and transcript placeholder")
                                    .font(.subheadline)
                                    .themeSecondaryText()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    .liquidGlassCard()
                }
                .padding(AppTheme.contentPadding)
            }
            .scrollContentBackground(.hidden)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MeetingDetailView(meetingTitle: "Weekly Product Sync")
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(10)
                    }
                    .liquidGlassCard()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
}
