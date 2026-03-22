import SwiftUI

struct MeetingDetailView: View {
    let meetingTitle: String

    var body: some View {
        List {
            Section("Summary") {
                Text("Meeting summary will appear here after processing.")
            }

            Section("Action Items") {
                Text("No action items yet.")
            }

            Section("Decisions") {
                Text("No decisions yet.")
            }

            Section("Transcript") {
                Text("Transcript content will be shown here.")
            }
        }
        .navigationTitle(meetingTitle)
    }
}

#Preview {
    NavigationStack {
        MeetingDetailView(meetingTitle: "Weekly Product Sync")
    }
}
