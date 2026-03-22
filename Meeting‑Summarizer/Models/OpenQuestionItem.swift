import Foundation
import SwiftData

@Model
final class OpenQuestionItem {
    var id: UUID
    var text: String
    var confidence: Double
    var sourceSegment: String
    var meeting: Meeting?

    init(
        id: UUID = UUID(),
        text: String = "",
        confidence: Double = 0,
        sourceSegment: String = "",
        meeting: Meeting? = nil
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.sourceSegment = sourceSegment
        self.meeting = meeting
    }
}
