import Foundation
import SwiftData

@Model
final class ActionItem {
    var id: UUID
    var task: String
    var owner: String
    var deadlineText: String
    var confidence: Double
    var sourceSegment: String
    var isCompleted: Bool
    var meeting: Meeting?

    init(
        id: UUID = UUID(),
        task: String = "",
        owner: String = "",
        deadlineText: String = "",
        confidence: Double = 0,
        sourceSegment: String = "",
        isCompleted: Bool = false,
        meeting: Meeting? = nil
    ) {
        self.id = id
        self.task = task
        self.owner = owner
        self.deadlineText = deadlineText
        self.confidence = confidence
        self.sourceSegment = sourceSegment
        self.isCompleted = isCompleted
        self.meeting = meeting
    }
}
