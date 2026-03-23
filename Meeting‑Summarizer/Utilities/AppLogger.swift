import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MeetingSummarizer"
    private static let recording = Logger(subsystem: subsystem, category: "recording")
    private static let upload = Logger(subsystem: subsystem, category: "upload")
    private static let processing = Logger(subsystem: subsystem, category: "processing")
    private static let networking = Logger(subsystem: subsystem, category: "networking")

    static func recordingSessionPrepared() {
        recording.info("Recording session prepared.")
    }

    static func recordingStartRequested() {
        recording.info("Recording start requested.")
    }

    static func recordingStarted(fileName: String) {
        recording.info("Recording started for file \(fileName, privacy: .public).")
    }

    static func recordingStopped(fileName: String, duration: TimeInterval) {
        recording.info("Recording stopped for file \(fileName, privacy: .public) after \(duration, format: .fixed(precision: 2)) seconds.")
    }

    static func recordingFailed(_ message: String) {
        recording.error("Recording failed: \(message, privacy: .public)")
    }

    static func uploadStarted(fileName: String) {
        upload.info("Upload started for file \(fileName, privacy: .public).")
    }

    static func uploadSucceeded(jobID: String?) {
        if let jobID, !jobID.isEmpty {
            upload.info("Upload succeeded with job id \(jobID, privacy: .private(mask: .hash)).")
        } else {
            upload.info("Upload succeeded without a job id.")
        }
    }

    static func uploadFailed(_ message: String) {
        upload.error("Upload failed: \(message, privacy: .public)")
    }

    static func processingStateChanged(_ status: String) {
        processing.info("Processing state changed to \(status, privacy: .public).")
    }

    static func processingPollingStarted(jobID: String) {
        processing.info("Polling started for job id \(jobID, privacy: .private(mask: .hash)).")
    }

    static func processingCompleted(jobID: String) {
        processing.info("Processing completed for job id \(jobID, privacy: .private(mask: .hash)).")
    }

    static func processingFailed(jobID: String?, message: String) {
        if let jobID, !jobID.isEmpty {
            processing.error("Processing failed for job id \(jobID, privacy: .private(mask: .hash)): \(message, privacy: .public)")
        } else {
            processing.error("Processing failed: \(message, privacy: .public)")
        }
    }

    static func invalidResponse(endpoint: String) {
        networking.error("Invalid response received for endpoint \(endpoint, privacy: .public).")
    }

    static func requestFailed(endpoint: String, statusCode: Int) {
        networking.error("Request failed for endpoint \(endpoint, privacy: .public) with status code \(statusCode).")
    }

    static func decodingFailed(endpoint: String, statusCode: Int, error: String) {
        networking.error("Decoding failed for endpoint \(endpoint, privacy: .public) after status code \(statusCode): \(error, privacy: .public)")
    }
}
