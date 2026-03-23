import SwiftUI

extension MeetingProcessingStatus {
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
}
