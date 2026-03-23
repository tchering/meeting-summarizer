import Foundation

struct MeetingExportPayload: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let status: String
    let transcript: String
    let summary: String
    let audioFilePath: String?
    let durationSeconds: Double
    let actionItems: [MeetingExportActionItem]
    let decisions: [MeetingExportDecisionItem]
    let openQuestions: [MeetingExportOpenQuestionItem]
}

struct MeetingExportActionItem: Codable {
    let id: UUID
    let task: String
    let owner: String
    let deadlineText: String
    let confidence: Double
    let sourceSegment: String
    let isCompleted: Bool
}

struct MeetingExportDecisionItem: Codable {
    let id: UUID
    let text: String
    let confidence: Double
    let sourceSegment: String
}

struct MeetingExportOpenQuestionItem: Codable {
    let id: UUID
    let text: String
    let confidence: Double
    let sourceSegment: String
}

extension MeetingExportPayload {
    init(meeting: Meeting) {
        self.id = meeting.id
        self.title = meeting.title
        self.createdAt = meeting.createdAt
        self.updatedAt = meeting.updatedAt
        self.status = meeting.status
        self.transcript = meeting.transcript
        self.summary = meeting.summary
        self.audioFilePath = meeting.audioFilePath
        self.durationSeconds = meeting.durationSeconds
        self.actionItems = meeting.actionItems.map { item in
            MeetingExportActionItem(
                id: item.id,
                task: item.task,
                owner: item.owner,
                deadlineText: item.deadlineText,
                confidence: item.confidence,
                sourceSegment: item.sourceSegment,
                isCompleted: item.isCompleted
            )
        }
        self.decisions = meeting.decisions.map { item in
            MeetingExportDecisionItem(
                id: item.id,
                text: item.text,
                confidence: item.confidence,
                sourceSegment: item.sourceSegment
            )
        }
        self.openQuestions = meeting.openQuestions.map { item in
            MeetingExportOpenQuestionItem(
                id: item.id,
                text: item.text,
                confidence: item.confidence,
                sourceSegment: item.sourceSegment
            )
        }
    }
}
