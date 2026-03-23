import Foundation
import Observation
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
final class RecordViewModel {
    private(set) var permissionStatus: MicrophonePermissionStatus
    private(set) var isRequestingPermission = false
    private(set) var recordingState: AudioRecordingState = .idle
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var savedRecordingURL: URL?
    private(set) var importedAudioURL: URL?
    private(set) var currentError: AppErrorState?
    private(set) var uploadState: UploadState = .idle
    private(set) var pollingState: MeetingPollingState = .idle

    private let permissionService: MicrophonePermissionServicing
    private let audioFileImportService: AudioFileImportServicing
    private let recordingService: AudioRecordingService
    private let uploadService: UploadService
    private let pollingService: MeetingPollingService
    private let meetingSummaryPersistenceService: MeetingSummaryPersistenceService
    private var recordingTimerTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var activeMeeting: Meeting?
    private var latestUploadReceipt: UploadReceipt?

    init() {
        self.permissionService = MicrophonePermissionService()
        self.audioFileImportService = AudioFileImportService()
        self.recordingService = AudioRecordingService()
        self.uploadService = UploadService()
        self.pollingService = MeetingPollingService()
        self.meetingSummaryPersistenceService = MeetingSummaryPersistenceService()
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
        self.uploadState = uploadService.state
        self.pollingState = pollingService.state
    }

    init(
        permissionService: MicrophonePermissionServicing,
        audioFileImportService: AudioFileImportServicing,
        recordingService: AudioRecordingService,
        uploadService: UploadService,
        pollingService: MeetingPollingService,
        meetingSummaryPersistenceService: MeetingSummaryPersistenceService
    ) {
        self.permissionService = permissionService
        self.audioFileImportService = audioFileImportService
        self.recordingService = recordingService
        self.uploadService = uploadService
        self.pollingService = pollingService
        self.meetingSummaryPersistenceService = meetingSummaryPersistenceService
        self.permissionStatus = permissionService.currentStatus()
        self.recordingState = recordingService.recordingState
        self.uploadState = uploadService.state
        self.pollingState = pollingService.state
    }

    func refreshPermissionStatus() async {
        permissionStatus = permissionService.currentStatus()
        syncPermissionErrorState()
        await prepareRecordingSessionIfNeeded()
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
        syncPermissionErrorState()
        await prepareRecordingSessionIfNeeded()
    }

    var supportedImportContentTypes: [UTType] {
        audioFileImportService.supportedContentTypes
    }

    func importAudioFile(from sourceURL: URL) async {
        do {
            let importedURL = try audioFileImportService.importAudioFile(from: sourceURL)
            importedAudioURL = importedURL
            savedRecordingURL = nil
            uploadState = .idle
            pollingState = .idle
            currentError = nil
            persistAudioMeeting(
                from: importedURL,
                title: importedMeetingTitle(for: importedURL),
                summary: "Audio imported from device. Upload and summarization can use the same backend workflow as recorded audio."
            )

            if activeMeeting != nil {
                await uploadRecordedAudio()
            }
        } catch {
            currentError = .uploadFailed(error.localizedDescription)
        }
    }

    func setErrorMessage(_ message: String?) {
        guard let message else {
            currentError = nil
            return
        }

        currentError = mapErrorState(for: message, fallback: .uploadFailed(message))
    }

    func performErrorAction(_ action: AppErrorAction) async {
        switch action {
        case .openSettings:
            break
        case .retryRecording:
            await startRecording()
        case .retryUpload:
            await uploadRecordedAudio()
        case .retryProcessing:
            guard let latestUploadReceipt else {
                currentError = .processingFailed("The backend job could not be resumed because no upload receipt is available.")
                return
            }

            await pollForMeetingResult(using: latestUploadReceipt)
        }
    }

    func uploadRecordedAudio() async {
        guard let audioFileURL = currentAudioFileURL else {
            uploadState = .failure("No audio file is available to upload.")
            currentError = .uploadFailed("No audio file is available to upload.")
            return
        }

        currentError = nil
        updateMeetingStatus(.uploading)

        await uploadService.uploadAudioFile(
            at: audioFileURL,
            fields: ["meeting_title": activeMeeting?.title ?? defaultMeetingTitle(for: Date())]
        )
        uploadState = uploadService.state

        switch uploadState {
        case .idle:
            break
        case .uploading:
            updateMeetingStatus(.uploading)
        case .success(let receipt):
            latestUploadReceipt = receipt
            updateMeetingStatus(.processing)
            await pollForMeetingResult(using: receipt)
        case .failure:
            updateMeetingStatus(.failed)
            syncUploadErrorState()
        }
    }

    func toggleRecording() async {
        switch permissionStatus {
        case .granted:
            switch recordingState {
            case .recording:
                stopRecording()
            default:
                await startRecording()
            }
        case .undetermined, .denied:
            break
        }
    }

    private func startRecording() async {
        recordingState = .starting
        currentError = nil
        importedAudioURL = nil
        savedRecordingURL = nil

        do {
            try await recordingService.startRecording()
            currentError = nil
            syncRecordingState()
            startElapsedTimeUpdates()
        } catch {
            currentError = .recordingFailed(error.localizedDescription)
            syncRecordingState()
        }
    }

    private func prepareRecordingSessionIfNeeded() async {
        guard permissionStatus == .granted else {
            return
        }

        do {
            try await recordingService.prepareRecordingSession()
        } catch {
            currentError = .recordingFailed(error.localizedDescription)
        }
    }

    private func stopRecording() {
        savedRecordingURL = recordingService.stopRecording()
        syncRecordingState()
        stopElapsedTimeUpdates()

        if let savedRecordingURL {
            persistAudioMeeting(
                from: savedRecordingURL,
                title: defaultMeetingTitle(for: Date()),
                summary: "Audio recorded locally. Transcription and summarization will happen in a later phase.",
                durationSeconds: elapsedTime
            )
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
        pollingState = pollingService.state

        switch recordingState {
        case .idle:
            break
        case .starting:
            currentError = nil
            uploadState = .idle
        case .recording:
            currentError = nil
            uploadState = .idle
        case .finished(let url):
            savedRecordingURL = url
            currentError = nil
        case .failed(let message):
            currentError = .recordingFailed(message)
        }

        syncUploadErrorState()
        syncPollingErrorState()
    }

    private func pollForMeetingResult(using receipt: UploadReceipt) async {
        guard let jobID = receipt.jobID else {
            pollingState = .failed("Upload succeeded, but no backend job identifier was returned.")
            currentError = .invalidResponse("Upload succeeded, but the backend did not return a job identifier for processing.")
            return
        }

        guard let result = await pollingService.poll(jobID: jobID) else {
            pollingState = pollingService.state
            updateMeetingStatus(.failed)
            syncPollingErrorState()
            return
        }

        pollingState = pollingService.state
        applyBackendResult(result)
    }

    private func persistAudioMeeting(
        from audioURL: URL,
        title: String,
        summary: String,
        durationSeconds: Double = 0
    ) {
        guard let modelContext else {
            currentError = .localPersistenceFailure("The audio file was saved, but the app could not store the meeting locally.")
            return
        }

        let createdAt = Date()
        let meeting = Meeting(
            title: title,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: MeetingProcessingStatus.recorded.rawValue,
            transcript: "",
            summary: summary,
            audioFilePath: audioURL.path,
            durationSeconds: durationSeconds
        )

        modelContext.insert(meeting)

        do {
            try modelContext.save()
            activeMeeting = meeting
        } catch {
            modelContext.delete(meeting)
            currentError = .localPersistenceFailure("The audio file was saved, but the meeting entry could not be created.")
        }
    }

    private func updateMeetingStatus(_ status: MeetingProcessingStatus) {
        guard let modelContext, let activeMeeting else {
            return
        }

        activeMeeting.processingStatus = status
        AppLogger.processingStateChanged(status.rawValue)

        do {
            try modelContext.save()
        } catch {
            currentError = .localPersistenceFailure("The meeting status could not be updated.")
        }
    }

    private func applyBackendResult(_ result: BackendMeetingResult) {
        guard let modelContext, let activeMeeting else {
            return
        }

        do {
            try meetingSummaryPersistenceService.apply(
                result,
                to: activeMeeting,
                in: modelContext
            )
            currentError = nil
        } catch {
            currentError = .invalidResponse("The processed meeting result could not be saved locally.")
        }
    }

    private func defaultMeetingTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Recorded Meeting \(formatter.string(from: date))"
    }

    private func importedMeetingTitle(for audioURL: URL) -> String {
        let fileName = audioURL.deletingPathExtension().lastPathComponent
        guard !fileName.isEmpty else {
            return "Imported Audio Meeting"
        }

        return "Imported \(fileName)"
    }

    private var currentAudioFileURL: URL? {
        savedRecordingURL ?? importedAudioURL
    }

    private func syncPermissionErrorState() {
        if permissionStatus == .denied {
            currentError = .microphoneDenied()
        } else if currentError?.kind == .microphoneDenied {
            currentError = nil
        }
    }

    private func syncUploadErrorState() {
        guard case .failure(let message) = uploadState else {
            return
        }

        currentError = mapErrorState(for: message, fallback: .uploadFailed(message))
    }

    private func syncPollingErrorState() {
        guard case .failed(let message) = pollingState else {
            return
        }

        currentError = mapErrorState(for: message, fallback: .processingFailed(message))
    }

    private func mapErrorState(for message: String, fallback: AppErrorState) -> AppErrorState {
        let normalized = message.lowercased()

        if normalized.contains("denied") || normalized.contains("microphone") {
            return .microphoneDenied()
        }

        if normalized.contains("invalid response")
            || normalized.contains("decode")
            || normalized.contains("decoding")
            || normalized.contains("job identifier")
        {
            return .invalidResponse(message)
        }

        if normalized.contains("processing") || normalized.contains("poll") || normalized.contains("backend") {
            return .processingFailed(message)
        }

        return fallback
    }
}
