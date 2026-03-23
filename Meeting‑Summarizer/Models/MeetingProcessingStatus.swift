import SwiftUI

enum MeetingProcessingStatus: String, CaseIterable, Codable, Sendable {
    case recorded
    case uploading
    case processing
    case completed
    case failed

    var displayTitle: String {
        switch self {
        case .recorded:
            return "Recorded"
        case .uploading:
            return "Uploading"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }

    var accentColor: Color {
        switch self {
        case .recorded:
            return AppTheme.accent
        case .uploading:
            return Color.orange
        case .processing:
            return Color.yellow
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    var detailMessage: String {
        switch self {
        case .recorded:
            return "Audio was saved locally and is ready for upload."
        case .uploading:
            return "The meeting audio is currently being uploaded to your backend."
        case .processing:
            return "The backend has accepted the file and is processing the meeting."
        case .completed:
            return "The meeting processing flow is complete."
        case .failed:
            return "The meeting hit an error and needs attention."
        }
    }
}
