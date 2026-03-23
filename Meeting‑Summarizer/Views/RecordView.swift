import SwiftUI
import SwiftData
import UIKit

@MainActor
struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @State private var viewModel = RecordViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                recorderStatusCard
                controlSection

                if let savedRecordingURL = viewModel.savedRecordingURL {
                    savedConfirmationCard(url: savedRecordingURL)
                    uploadCard
                }

                if viewModel.permissionStatus == .denied {
                    deniedStateCard
                }

                if let errorMessage = viewModel.errorMessage {
                    errorCard(message: errorMessage)
                }
            }
            .padding(AppTheme.contentPadding)
        }
        .appScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.attachModelContext(modelContext)
            await viewModel.refreshPermissionStatus()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recorder")
                .font(.system(size: 18, weight: .semibold))
                .themeMutedText()

            Text("Capture Meeting Audio")
                .font(.largeTitle)
                .fontWeight(.bold)
                .themeTitle()

            Text("Record locally, confirm the file was saved, and prepare the meeting for the next processing steps.")
                .themeSecondaryText()
        }
        .liquidGlassCard()
    }

    private var recorderStatusCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(indicatorColor.opacity(0.35), lineWidth: 8)
                                .scaleEffect(isRecordingActive ? 1.18 : 1)
                                .opacity(isRecordingActive ? 0.9 : 0)
                                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isRecordingActive)
                        )

                    Text(statusTitle)
                        .font(.headline)
                        .themeTitle()
                }

                Spacer()

                Text(statusBadge)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AppTheme.elevatedSurfaceFill)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppTheme.surfaceStroke, lineWidth: 1)
                    )
                    .themeTitle()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Elapsed Time")
                    .font(.subheadline)
                    .themeMutedText()

                Text(formattedElapsedTime)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .themeTitle()
            }

            Text(statusMessage)
                .themeSecondaryText()
        }
        .liquidGlassCard()
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Controls")
                .font(.subheadline)
                .themeMutedText()

            switch viewModel.permissionStatus {
            case .undetermined:
                permissionButton

            case .granted:
                HStack(spacing: 12) {
                    startButton
                    stopButton
                }

            case .denied:
                settingsButton
            }
        }
        .liquidGlassCard()
    }

    private func savedConfirmationCard(url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Recording Saved")
                    .font(.headline)
                    .themeTitle()
            }

            Text(url.lastPathComponent)
                .font(.headline)
                .themeTitle()

            Text("Saved locally and ready for the next workflow step.")
                .themeSecondaryText()

            Text(url.path)
                .font(.footnote)
                .textSelection(.enabled)
                .themeMutedText()
        }
        .liquidGlassCard()
    }

    private var deniedStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Microphone access is currently off for this app.")
                .font(.subheadline)
                .themeTitle()
            Text("Open Settings and enable microphone access to continue recording on this device.")
                .font(.subheadline)
                .themeSecondaryText()
        }
        .liquidGlassCard()
    }

    private var uploadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Backend Upload")
                    .font(.headline)
                    .themeTitle()
                Spacer()
                Text(uploadStatusLabel)
                    .font(.caption.weight(.semibold))
                    .themeMutedText()
            }

            switch viewModel.uploadState {
            case .idle:
                Text("Upload the saved recording to your backend when the endpoint is configured.")
                    .themeSecondaryText()
            case .uploading(let progress):
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress, total: 1)
                        .tint(AppTheme.accentStrong)
                    Text("Uploading \(Int(progress * 100))%")
                        .themeSecondaryText()
                }
            case .success(let receipt):
                Text(receipt.message ?? "Upload completed successfully.")
                    .themeSecondaryText()
            case .failure(let message):
                Text(message)
                    .themeSecondaryText()
            }

            switch viewModel.pollingState {
            case .idle:
                EmptyView()
            case .polling:
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView()
                        .tint(AppTheme.accentStrong)
                    Text("Polling backend for completed summary...")
                        .themeSecondaryText()
                }
            case .completed:
                Text("Backend summary is ready and the meeting was updated locally.")
                    .themeSecondaryText()
            case .failed(let message):
                Text(message)
                    .themeSecondaryText()
            }

            Button {
                Task {
                    await viewModel.uploadRecordedAudio()
                }
            } label: {
                Label("Upload Recording", systemImage: "arrow.up.circle")
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.savedRecordingURL == nil || isUploadInFlight)
            .opacity(isUploadInFlight ? 0.55 : 1)
            .liquidGlassButtonStyle()
        }
        .liquidGlassCard()
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recording Error")
                .font(.subheadline)
                .themeTitle()
            Text(message)
                .font(.subheadline)
                .themeSecondaryText()
        }
        .liquidGlassCard()
    }

    @ViewBuilder
    private var permissionButton: some View {
        Button {
            Task {
                await viewModel.requestMicrophoneAccess()
            }
        } label: {
            Label(
                viewModel.isRequestingPermission ? "Requesting Access..." : "Allow Microphone Access",
                systemImage: "mic.badge.plus"
            )
            .frame(maxWidth: .infinity)
        }
        .disabled(viewModel.isRequestingPermission)
        .liquidGlassButtonStyle()
    }

    private var settingsButton: some View {
        Button {
            openSettings()
        } label: {
            Label("Open Settings", systemImage: "gearshape")
                .frame(maxWidth: .infinity)
        }
        .liquidGlassButtonStyle()
    }

    private var startButton: some View {
        Button {
            guard !isRecordingActive else { return }
            Task {
                await viewModel.toggleRecording()
            }
        } label: {
            Label("Start", systemImage: "record.circle")
                .frame(maxWidth: .infinity)
        }
        .disabled(isRecordingActive)
        .opacity(isRecordingActive ? 0.55 : 1)
        .liquidGlassButtonStyle()
    }

    private var stopButton: some View {
        Button {
            guard isRecordingActive else { return }
            Task {
                await viewModel.toggleRecording()
            }
        } label: {
            Label("Stop", systemImage: "stop.circle")
                .frame(maxWidth: .infinity)
        }
        .disabled(!isRecordingActive)
        .opacity(isRecordingActive ? 1 : 0.55)
        .liquidGlassButtonStyle()
    }

    private var statusTitle: String {
        switch viewModel.permissionStatus {
        case .undetermined:
            return "Permission Needed"
        case .granted:
            switch viewModel.recordingState {
            case .starting:
                return "Starting Recorder"
            default:
                return "Microphone Ready"
            }
        case .denied:
            return "Access Denied"
        }
    }

    private var statusMessage: String {
        switch viewModel.permissionStatus {
        case .undetermined:
            return "Grant microphone access to prepare the app for audio recording."
        case .granted:
            switch viewModel.recordingState {
            case .idle:
                return "Permission is granted. You can start recording now."
            case .starting:
                return "Starting the recorder and activating the microphone..."
            case .recording:
                return "Recording in progress. The timer is live and the audio is being written to a local .m4a file."
            case .finished:
                return "Recording finished and saved locally."
            case .failed:
                return "Recording failed. Review the error details below."
            }
        case .denied:
            return "Microphone access was denied. You can enable it later in Settings."
        }
    }

    private var formattedElapsedTime: String {
        let totalSeconds = Int(viewModel.elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var statusBadge: String {
        switch viewModel.permissionStatus {
        case .undetermined:
            return "Permission"
        case .granted:
            switch viewModel.recordingState {
            case .idle:
                return "Ready"
            case .starting:
                return "Starting"
            case .recording:
                return "Live"
            case .finished:
                return "Saved"
            case .failed:
                return "Error"
            }
        case .denied:
            return "Denied"
        }
    }

    private var indicatorColor: Color {
        switch viewModel.permissionStatus {
        case .undetermined:
            return Color.orange
        case .granted:
            switch viewModel.recordingState {
            case .idle:
                return AppTheme.accent
            case .starting:
                return Color.orange
            case .recording:
                return Color.red
            case .finished:
                return Color.green
            case .failed:
                return Color.orange
            }
        case .denied:
            return Color.orange
        }
    }

    private var uploadStatusLabel: String {
        switch viewModel.uploadState {
        case .idle:
            return "Idle"
        case .uploading:
            return "Uploading"
        case .success:
            return "Uploaded"
        case .failure:
            return "Failed"
        }
    }

    private var isUploadInFlight: Bool {
        if case .uploading = viewModel.uploadState {
            return true
        }
        return false
    }

    private var isRecordingActive: Bool {
        switch viewModel.recordingState {
        case .starting, .recording:
            return true
        case .idle, .finished, .failed:
            return false
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }
}

#Preview {
    NavigationStack {
        RecordView()
    }
}
