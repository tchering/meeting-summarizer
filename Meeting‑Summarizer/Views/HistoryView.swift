import SwiftUI

struct HistoryView: View {
    private let placeholderMeetings = [
        "Weekly Product Sync",
        "Design Review",
        "Client Check-In"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .themeTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(placeholderMeetings, id: \.self) { meetingTitle in
                        NavigationLink {
                            MeetingDetailView(meetingTitle: meetingTitle)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(meetingTitle)
                                        .font(.headline)
                                        .themeTitle()
                                    Text("Placeholder transcript and summary preview")
                                        .font(.subheadline)
                                        .themeSecondaryText()
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                        .liquidGlassCard()
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
}
