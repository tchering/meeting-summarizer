import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Start") {
                    NavigationLink("Record a Meeting") {
                        RecordView()
                    }

                    NavigationLink("View Processing State") {
                        ProcessingView()
                    }
                }

                Section("Recent") {
                    NavigationLink("Weekly Product Sync") {
                        MeetingDetailView(meetingTitle: "Weekly Product Sync")
                    }
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
