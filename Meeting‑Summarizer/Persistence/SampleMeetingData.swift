import Foundation
import SwiftData

@MainActor
enum SampleMeetingData {
    static func seedIfNeeded(in modelContext: ModelContext) throws {
        var fetchDescriptor = FetchDescriptor<Meeting>()
        fetchDescriptor.fetchLimit = 1

        let existingMeetings = try modelContext.fetch(fetchDescriptor)
        guard existingMeetings.isEmpty else {
            return
        }

        for meeting in seedMeetings {
            modelContext.insert(meeting)
        }

        try modelContext.save()
    }

    static var previewContainer: ModelContainer {
        let schema = Schema([
            Meeting.self,
            ActionItem.self,
            DecisionItem.self,
            OpenQuestionItem.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try seedIfNeeded(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }

    static var previewMeeting: Meeting {
        seedMeetings[0]
    }

    private static var seedMeetings: [Meeting] {
        [
            makeMeeting(
                title: "Weekly Product Sync",
                daysAgo: 1,
                status: "completed",
                durationSeconds: 2_340,
                summary: "The team aligned on the launch checklist, approved the onboarding flow updates, and flagged analytics instrumentation as the main remaining risk.",
                transcript: "Alex: We are on track for launch if analytics is instrumented by Friday. Priya: Onboarding copy changes are approved. Sam: I will confirm App Store screenshots.",
                actionItems: [
                    ("Confirm analytics events for onboarding funnel", "Alex", "Friday"),
                    ("Finalize App Store screenshots", "Sam", "Thursday")
                ],
                decisions: [
                    "Ship the revised onboarding flow in the next release."
                ],
                openQuestions: [
                    "Do we need one more QA pass on subscription restoration?"
                ]
            ),
            makeMeeting(
                title: "Design Review",
                daysAgo: 3,
                status: "completed",
                durationSeconds: 1_560,
                summary: "The design review focused on information density, navigation clarity, and the need for a stronger visual hierarchy in the meeting detail screen.",
                transcript: "Maya: The detail screen needs clearer sections. Leo: The summary should stay above fold. Maya: We should simplify the tab labels.",
                actionItems: [
                    ("Revise hierarchy for detail sections", "Maya", "Next sprint")
                ],
                decisions: [
                    "Keep the summary section pinned near the top of the detail view."
                ],
                openQuestions: [
                    "Should the transcript be collapsible by default?"
                ]
            ),
            makeMeeting(
                title: "Client Check-In",
                daysAgo: 6,
                status: "completed",
                durationSeconds: 2_880,
                summary: "The client approved the reporting format and asked for clearer ownership tracking on action items before rollout.",
                transcript: "Client: Reporting format looks good. Nina: We can add owner labels to each action item. Client: Please include deadlines in the exported summary.",
                actionItems: [
                    ("Add owner labels to action item output", "Nina", "Monday"),
                    ("Prototype deadline formatting for exports", "Ravi", "Wednesday")
                ],
                decisions: [
                    "Use the simplified recap structure for the pilot rollout."
                ],
                openQuestions: [
                    "Should shared recaps include the raw transcript by default?"
                ]
            )
        ]
    }

    private static func makeMeeting(
        title: String,
        daysAgo: Int,
        status: String,
        durationSeconds: Double,
        summary: String,
        transcript: String,
        actionItems: [(task: String, owner: String, deadlineText: String)],
        decisions: [String],
        openQuestions: [String]
    ) -> Meeting {
        let createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let meeting = Meeting(
            title: title,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: status,
            transcript: transcript,
            summary: summary,
            durationSeconds: durationSeconds
        )

        let meetingActionItems = actionItems.map { item in
            ActionItem(
                task: item.task,
                owner: item.owner,
                deadlineText: item.deadlineText,
                confidence: 0.92,
                sourceSegment: "Sample seed data",
                isCompleted: false,
                meeting: meeting
            )
        }

        let meetingDecisions = decisions.map { text in
            DecisionItem(
                text: text,
                confidence: 0.9,
                sourceSegment: "Sample seed data",
                meeting: meeting
            )
        }

        let meetingOpenQuestions = openQuestions.map { text in
            OpenQuestionItem(
                text: text,
                confidence: 0.78,
                sourceSegment: "Sample seed data",
                meeting: meeting
            )
        }

        meeting.actionItems = meetingActionItems
        meeting.decisions = meetingDecisions
        meeting.openQuestions = meetingOpenQuestions

        return meeting
    }
}
