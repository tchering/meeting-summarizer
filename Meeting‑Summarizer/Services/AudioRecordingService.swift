import AVFAudio
import Foundation
import Observation

enum AudioRecordingState: Equatable {
    case idle
    case recording
    case finished(URL)
    case failed(String)
}

@MainActor
@Observable
final class AudioRecordingService: NSObject, AVAudioRecorderDelegate {
    private(set) var recordingState: AudioRecordingState = .idle
    private(set) var currentRecordingURL: URL?

    private var recorder: AVAudioRecorder?

    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        let recordingURL = try makeRecordingURL()
        let recorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true

        guard recorder.prepareToRecord(), recorder.record() else {
            recordingState = .failed("Unable to start recording.")
            throw AudioRecordingServiceError.unableToStart
        }

        self.recorder = recorder
        currentRecordingURL = recordingURL
        recordingState = .recording
    }

    func stopRecording() -> URL? {
        guard let recorder else {
            return currentRecordingURL
        }

        let recordedURL = recorder.url
        recorder.stop()
        self.recorder = nil

        if FileManager.default.fileExists(atPath: recordedURL.path) {
            currentRecordingURL = recordedURL
            recordingState = .finished(recordedURL)
            return recordedURL
        }

        recordingState = .failed("The recording file could not be found after stopping.")
        return nil
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let recordedURL = recorder.url
            currentRecordingURL = recordedURL
            recordingState = .finished(recordedURL)
        } else {
            recordingState = .failed("Recording did not finish successfully.")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
        let message = error?.localizedDescription ?? "An unknown audio encoding error occurred."
        recordingState = .failed(message)
        self.recorder = nil
    }

    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    private func makeRecordingURL() throws -> URL {
        let recordingsDirectory = try recordingsDirectoryURL()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let filename = "meeting-\(formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")).m4a"
        return recordingsDirectory.appendingPathComponent(filename)
    }

    private func recordingsDirectoryURL() throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsDirectory else {
            throw AudioRecordingServiceError.recordingsDirectoryUnavailable
        }

        let recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }

        return recordingsDirectory
    }
}

enum AudioRecordingServiceError: LocalizedError {
    case recordingsDirectoryUnavailable
    case unableToStart

    var errorDescription: String? {
        switch self {
        case .recordingsDirectoryUnavailable:
            return "The recordings directory could not be created."
        case .unableToStart:
            return "Recording could not be started."
        }
    }
}
