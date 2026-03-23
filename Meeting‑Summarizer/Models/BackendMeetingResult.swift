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
    let risks: [BackendRiskItem]
    let openQuestions: [BackendOpenQuestionItem]

    enum CodingKeys: String, CodingKey {
        case status
        case transcript
        case summary
        case actionItems = "action_items"
        case decisions = "key_decisions"
        case risks
        case openQuestions = "open_questions"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(MeetingProcessingStatus.self, forKey: .status) ?? .processing
        self.transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.actionItems = try container.decodeIfPresent([BackendActionItem].self, forKey: .actionItems) ?? []
        self.decisions = try container.decodeIfPresent([BackendDecisionItem].self, forKey: .decisions) ?? []
        self.risks = try container.decodeIfPresent([BackendRiskItem].self, forKey: .risks) ?? []
        self.openQuestions = try container.decodeIfPresent([BackendOpenQuestionItem].self, forKey: .openQuestions) ?? []
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
        case deadline
        case deadlineText = "deadline_text"
        case confidence
        case sourceSegment = "source_segment"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.task = try container.decode(String.self, forKey: .task)
        self.owner = try container.decodeIfPresent(String.self, forKey: .owner)
        self.deadlineText =
            try container.decodeIfPresent(String.self, forKey: .deadline) ??
            container.decodeIfPresent(String.self, forKey: .deadlineText)
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.sourceSegment = try container.decodeIfPresent(String.self, forKey: .sourceSegment)
    }
}

struct BackendDecisionItem: Decodable, Sendable {
    let text: String
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case decision
        case text
        case confidence
        case sourceSegment = "source_segment"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text =
            try container.decodeIfPresent(String.self, forKey: .decision) ??
            container.decodeIfPresent(String.self, forKey: .text) ??
            ""
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.sourceSegment = try container.decodeIfPresent(String.self, forKey: .sourceSegment)
    }
}

struct BackendRiskItem: Decodable, Sendable {
    let text: String
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case risk
        case text
        case confidence
        case sourceSegment = "source_segment"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text =
            try container.decodeIfPresent(String.self, forKey: .risk) ??
            container.decodeIfPresent(String.self, forKey: .text) ??
            ""
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.sourceSegment = try container.decodeIfPresent(String.self, forKey: .sourceSegment)
    }
}

struct BackendOpenQuestionItem: Decodable, Sendable {
    let text: String
    let confidence: Double?
    let sourceSegment: String?

    enum CodingKeys: String, CodingKey {
        case question
        case text
        case confidence
        case sourceSegment = "source_segment"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text =
            try container.decodeIfPresent(String.self, forKey: .question) ??
            container.decodeIfPresent(String.self, forKey: .text) ??
            ""
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.sourceSegment = try container.decodeIfPresent(String.self, forKey: .sourceSegment)
    }
}
