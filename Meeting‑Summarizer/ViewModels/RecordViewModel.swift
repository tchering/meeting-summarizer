import Foundation
import Observation

@MainActor
@Observable
final class RecordViewModel {
    private(set) var permissionStatus: MicrophonePermissionStatus
    private(set) var isRequestingPermission = false
    private(set) var recordingState: AudioRecordingState = .idle
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var savedRecordingURL: URL?
    private(set) var errorMessage: String?

    private let permissionService: MicrophonePermissionServicing
    private let recordingService: AudioRecordingService
    private var recordingTimerTask: Task<Void, Never>?

    init() {
        self.permissionService = MicrophonePermissionService()
        self.recordingService = AudioRecordingService()
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
    }

    init(
        permissionService: MicrophonePermissionServicing,
        recordingService: AudioRecordingService
    ) {
        self.permissionService = permissionService
        self.recordingService = recordingService
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
    }

    func refreshPermissionStatus() {
        permissionStatus = permissionService.currentStatus()
        syncRecordingState()
    }

    func requestMicrophoneAccess() async {
        guard !isRequestingPermission else {
            return
        }

        isRequestingPermission = true
        permissionStatus = await permissionService.requestPermission()
        isRequestingPermission = false
    }

    func toggleRecording() {
        switch permissionStatus {
        case .granted:
            switch recordingState {
            case .recording:
                stopRecording()
            default:
                startRecording()
            }
        case .undetermined, .denied:
            break
        }
    }

    private func startRecording() {
        do {
            try recordingService.startRecording()
            savedRecordingURL = nil
            errorMessage = nil
            syncRecordingState()
            startElapsedTimeUpdates()
        } catch {
            errorMessage = error.localizedDescription
            syncRecordingState()
        }
    }

    private func stopRecording() {
        savedRecordingURL = recordingService.stopRecording()
        syncRecordingState()
        stopElapsedTimeUpdates()
    }

    private func startElapsedTimeUpdates() {
        stopElapsedTimeUpdates()

        recordingTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                syncRecordingState()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func stopElapsedTimeUpdates() {
        recordingTimerTask?.cancel()
        recordingTimerTask = nil
        elapsedTime = recordingService.elapsedTime
    }

    private func syncRecordingState() {
        recordingState = recordingService.recordingState
        elapsedTime = recordingService.elapsedTime

        switch recordingState {
        case .idle:
            break
        case .recording:
            errorMessage = nil
        case .finished(let url):
            savedRecordingURL = url
            errorMessage = nil
        case .failed(let message):
            errorMessage = message
        }
    }
}
