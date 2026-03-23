import Foundation
import SwiftData

@MainActor
struct MeetingSummaryPersistenceService {
    func apply(
        _ response: MeetingSummaryResponse,
        to meeting: Meeting,
        transcript: String? = nil,
        status: MeetingProcessingStatus = .completed,
        in modelContext: ModelContext
    ) throws {
        if !response.meetingTitle.isEmpty {
            meeting.title = response.meetingTitle
        }

        meeting.summary = response.summary

        if let transcript {
            meeting.transcript = transcript
        }

        meeting.actionItems.removeAll()
        meeting.decisions.removeAll()
        meeting.openQuestions.removeAll()

        meeting.actionItems = response.actionItems.map { item in
            ActionItem(
                task: item.task,
                owner: item.owner ?? "",
                deadlineText: item.deadline ?? "",
                confidence: 0,
                sourceSegment: "",
                isCompleted: false,
                meeting: meeting
            )
        }

        meeting.decisions = response.keyDecisions.map { decision in
            DecisionItem(
                text: decision.text,
                confidence: 0,
                sourceSegment: "",
                meeting: meeting
            )
        }

        meeting.openQuestions = response.openQuestions.map { question in
            OpenQuestionItem(
                text: question.text,
                confidence: 0,
                sourceSegment: "",
                meeting: meeting
            )
        }

        meeting.processingStatus = status

        try modelContext.save()
    }

    func apply(
        _ result: BackendMeetingResult,
        to meeting: Meeting,
        in modelContext: ModelContext
    ) throws {
        let response = MeetingSummaryResponse(
            meetingTitle: meeting.title,
            summary: result.summary ?? "",
            keyDecisions: result.decisions.map {
                MeetingSummaryDecision(text: $0.text)
            },
            actionItems: result.actionItems.map {
                MeetingSummaryActionItem(
                    task: $0.task,
                    owner: $0.owner,
                    deadline: $0.deadlineText
                )
            },
            risks: [],
            openQuestions: result.openQuestions.map {
                MeetingSummaryOpenQuestion(text: $0.text)
            },
            speakers: []
        )

        try apply(
            response,
            to: meeting,
            transcript: result.transcript,
            status: result.status,
            in: modelContext
        )
    }
}
