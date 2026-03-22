import Foundation
import SwiftData

@Model
final class Meeting {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var status: String
    var transcript: String
    var summary: String
    var audioFilePath: String?
    var durationSeconds: Double

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.meeting)
    var actionItems: [ActionItem]

    @Relationship(deleteRule: .cascade, inverse: \DecisionItem.meeting)
    var decisions: [DecisionItem]

    @Relationship(deleteRule: .cascade, inverse: \OpenQuestionItem.meeting)
    var openQuestions: [OpenQuestionItem]

    init(
        id: UUID = UUID(),
        title: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        status: String = "draft",
        transcript: String = "",
        summary: String = "",
        audioFilePath: String? = nil,
        durationSeconds: Double = 0,
        actionItems: [ActionItem] = [],
        decisions: [DecisionItem] = [],
        openQuestions: [OpenQuestionItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.transcript = transcript
        self.summary = summary
        self.audioFilePath = audioFilePath
        self.durationSeconds = durationSeconds
        self.actionItems = actionItems
        self.decisions = decisions
        self.openQuestions = openQuestions
    }
}
