import SwiftUI

struct HistoryView: View {
    private let placeholderMeetings = [
        "Weekly Product Sync",
        "Design Review",
        "Client Check-In"
    ]

    var body: some View {
        NavigationStack {
            List(placeholderMeetings, id: \.self) { meetingTitle in
                NavigationLink(meetingTitle) {
                    MeetingDetailView(meetingTitle: meetingTitle)
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
