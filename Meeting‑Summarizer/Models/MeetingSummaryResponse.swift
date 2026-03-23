import Foundation

struct MeetingSummaryResponse: Decodable, Sendable {
    let meetingTitle: String
    let summary: String
    let keyDecisions: [MeetingSummaryDecision]
    let actionItems: [MeetingSummaryActionItem]
    let risks: [MeetingSummaryRisk]
    let openQuestions: [MeetingSummaryOpenQuestion]
    let speakers: [MeetingSummarySpeaker]

    enum CodingKeys: String, CodingKey {
        case meetingTitle = "meeting_title"
        case summary
        case keyDecisions = "key_decisions"
        case actionItems = "action_items"
        case risks
        case openQuestions = "open_questions"
        case speakers
    }

    init(
        meetingTitle: String,
        summary: String,
        keyDecisions: [MeetingSummaryDecision],
        actionItems: [MeetingSummaryActionItem],
        risks: [MeetingSummaryRisk],
        openQuestions: [MeetingSummaryOpenQuestion],
        speakers: [MeetingSummarySpeaker]
    ) {
        self.meetingTitle = meetingTitle
        self.summary = summary
        self.keyDecisions = keyDecisions
        self.actionItems = actionItems
        self.risks = risks
        self.openQuestions = openQuestions
        self.speakers = speakers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meetingTitle = try container.decodeIfPresent(String.self, forKey: .meetingTitle) ?? ""
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        self.keyDecisions = try container.decodeIfPresent([MeetingSummaryDecision].self, forKey: .keyDecisions) ?? []
        self.actionItems = try container.decodeIfPresent([MeetingSummaryActionItem].self, forKey: .actionItems) ?? []
        self.risks = try container.decodeIfPresent([MeetingSummaryRisk].self, forKey: .risks) ?? []
        self.openQuestions = try container.decodeIfPresent([MeetingSummaryOpenQuestion].self, forKey: .openQuestions) ?? []
        self.speakers = try container.decodeIfPresent([MeetingSummarySpeaker].self, forKey: .speakers) ?? []
    }
}

struct MeetingSummaryDecision: Decodable, Sendable, Identifiable {
    let id = UUID()
    let text: String

    init(text: String) {
        self.text = text
    }
}

struct MeetingSummaryActionItem: Decodable, Sendable, Identifiable {
    let id = UUID()
    let task: String
    let owner: String?
    let deadline: String?

    init(task: String, owner: String?, deadline: String?) {
        self.task = task
        self.owner = owner
        self.deadline = deadline
    }
}

struct MeetingSummaryRisk: Decodable, Sendable, Identifiable {
    let id = UUID()
    let text: String

    init(text: String) {
        self.text = text
    }
}

struct MeetingSummaryOpenQuestion: Decodable, Sendable, Identifiable {
    let id = UUID()
    let text: String

    init(text: String) {
        self.text = text
    }
}

struct MeetingSummarySpeaker: Decodable, Sendable, Identifiable {
    let id = UUID()
    let name: String
    let highlights: [String]

    init(name: String, highlights: [String]) {
        self.name = name
        self.highlights = highlights
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        self.highlights = try container.decodeIfPresent([String].self, forKey: .highlights) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case name
        case highlights
    }
}
