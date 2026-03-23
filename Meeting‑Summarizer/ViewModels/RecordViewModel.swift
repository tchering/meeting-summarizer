import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RecordViewModel {
    private(set) var permissionStatus: MicrophonePermissionStatus
    private(set) var isRequestingPermission = false
    private(set) var recordingState: AudioRecordingState = .idle
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var savedRecordingURL: URL?
    private(set) var errorMessage: String?
    private(set) var uploadState: UploadState = .idle

    private let permissionService: MicrophonePermissionServicing
    private let recordingService: AudioRecordingService
    private let uploadService: UploadService
    private var recordingTimerTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var activeMeeting: Meeting?

    init() {
        self.permissionService = MicrophonePermissionService()
        self.recordingService = AudioRecordingService()
        self.uploadService = UploadService()
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
        self.uploadState = uploadService.state
    }

    init(
        permissionService: MicrophonePermissionServicing,
        recordingService: AudioRecordingService,
        uploadService: UploadService
    ) {
        self.permissionService = permissionService
        self.recordingService = recordingService
        self.uploadService = uploadService
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
        self.uploadState = uploadService.state
    }

    func refreshPermissionStatus() {
        permissionStatus = permissionService.currentStatus()
        syncRecordingState()
    }

    func attachModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func requestMicrophoneAccess() async {
        guard !isRequestingPermission else {
            return
        }

        isRequestingPermission = true
        permissionStatus = await permissionService.requestPermission()
        isRequestingPermission = false
    }

    func uploadRecordedAudio() async {
        guard let savedRecordingURL else {
            uploadState = .failure("No recorded audio file is available to upload.")
            return
        }

        updateMeetingStatus(.uploading)

        await uploadService.uploadAudioFile(
            at: savedRecordingURL,
            fields: ["meeting_title": defaultMeetingTitle(for: Date())]
        )
        uploadState = uploadService.state

        switch uploadState {
        case .idle:
            break
        case .uploading:
            updateMeetingStatus(.uploading)
        case .success:
            updateMeetingStatus(.processing)
        case .failure:
            updateMeetingStatus(.failed)
        }
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

        if let savedRecordingURL {
            persistRecordedMeeting(from: savedRecordingURL)
        }
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
        uploadState = uploadService.state

        switch recordingState {
        case .idle:
            break
        case .recording:
            errorMessage = nil
            uploadState = .idle
        case .finished(let url):
            savedRecordingURL = url
            errorMessage = nil
        case .failed(let message):
            errorMessage = message
        }
    }

    private func persistRecordedMeeting(from recordingURL: URL) {
        guard let modelContext else {
            errorMessage = "Recording was saved, but the app could not store the meeting locally."
            return
        }

        let createdAt = Date()
        let meeting = Meeting(
            title: defaultMeetingTitle(for: createdAt),
            createdAt: createdAt,
            updatedAt: createdAt,
            status: MeetingProcessingStatus.recorded.rawValue,
            transcript: "",
            summary: "Audio recorded locally. Transcription and summarization will happen in a later phase.",
            audioFilePath: recordingURL.path,
            durationSeconds: elapsedTime
        )

        modelContext.insert(meeting)

        do {
            try modelContext.save()
            activeMeeting = meeting
        } catch {
            modelContext.delete(meeting)
            errorMessage = "Recording was saved, but the meeting entry could not be created."
        }
    }

    private func updateMeetingStatus(_ status: MeetingProcessingStatus) {
        guard let modelContext, let activeMeeting else {
            return
        }

        activeMeeting.processingStatus = status

        do {
            try modelContext.save()
        } catch {
            errorMessage = "The meeting status could not be updated."
        }
    }

    private func defaultMeetingTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Recorded Meeting \(formatter.string(from: date))"
    }
}
