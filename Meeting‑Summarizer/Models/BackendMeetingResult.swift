import Foundation

struct UploadReceipt: Decodable, Equatable, Sendable {
    let jobID: String?
    let message: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
        case meetingID = "meeting_id"
        case message
        case status
    }

    init(jobID: String?, message: String?, status: String?) {
        self.jobID = jobID
        self.message = message
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let directJobID = try container.decodeIfPresent(String.self, forKey: .jobID)
        let meetingID = try container.decodeIfPresent(String.self, forKey: .meetingID)
        self.jobID = directJobID ?? meetingID
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }
}

struct BackendMeetingResult: Decodable, Sendable {
    let status: MeetingProcessingStatus
    let transcript: String?
    let summary: String?
    let actionItems: [BackendActionItem]
    let decisions: [BackendDecisionItem]
    let openQuestions: [BackendOpenQuestionItem]

    enum CodingKeys: String, CodingKey {
        case status
        case transcript
        case summary
        case actionItems = "action_items"
        case decisions = "key_decisions"
        case openQuestions = "open_questions"
    }
}

struct BackendActionItem: Decodable, Sendable {
    let task: String
    let owner: String?
    let deadlineText: String?
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case task
        case owner
        case deadlineText = "deadline_text"
        case confidence
        case sourceSegment = "source_segment"
    }
}

struct BackendDecisionItem: Decodable, Sendable {
    let text: String
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case text
        case confidence
        case sourceSegment = "source_segment"
    }
}

struct BackendOpenQuestionItem: Decodable, Sendable {
    let text: String
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case text
        case confidence
        case sourceSegment = "source_segment"
    }
}
