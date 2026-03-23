import Foundation

enum AppErrorAction: Equatable {
    case openSettings
    case retryRecording
    case retryUpload
    case retryProcessing
}

enum AppErrorKind: Equatable {
    case microphoneDenied
    case recordingFailed
    case uploadFailed
    case processingFailed
    case invalidResponse
    case localPersistenceFailure
}

struct AppErrorState: Identifiable, Equatable {
    let id = UUID()
    let kind: AppErrorKind
    let title: String
    let message: String
    let action: AppErrorAction?
    let actionLabel: String?

    init(
        kind: AppErrorKind,
        title: String,
        message: String,
        action: AppErrorAction? = nil,
        actionLabel: String? = nil
    ) {
        self.kind = kind
        self.title = title
        self.message = message
        self.action = action
        self.actionLabel = actionLabel
    }

    static func microphoneDenied() -> AppErrorState {
        AppErrorState(
            kind: .microphoneDenied,
            title: "Microphone Access Is Off",
            message: "Enable microphone access in Settings to record meetings on this device.",
            action: .openSettings,
            actionLabel: "Open Settings"
        )
    }

    static func recordingFailed(_ message: String) -> AppErrorState {
        AppErrorState(
            kind: .recordingFailed,
            title: "Recording Failed",
            message: message,
            action: .retryRecording,
            actionLabel: "Try Recording Again"
        )
    }

    static func uploadFailed(_ message: String) -> AppErrorState {
        AppErrorState(
            kind: .uploadFailed,
            title: "Upload Failed",
            message: message,
            action: .retryUpload,
            actionLabel: "Retry Upload"
        )
    }

    static func processingFailed(_ message: String) -> AppErrorState {
        AppErrorState(
            kind: .processingFailed,
            title: "Processing Failed",
            message: message,
            action: .retryProcessing,
            actionLabel: "Retry Processing"
        )
    }

    static func invalidResponse(_ message: String) -> AppErrorState {
        AppErrorState(
            kind: .invalidResponse,
            title: "Invalid Response",
            message: message
        )
    }

    static func localPersistenceFailure(_ message: String) -> AppErrorState {
        AppErrorState(
            kind: .localPersistenceFailure,
            title: "Could Not Save Meeting",
            message: message
        )
    }
}
