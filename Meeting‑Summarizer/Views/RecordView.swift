import SwiftUI
import UIKit

@MainActor
struct RecordView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel = RecordViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Record Meeting", systemImage: "mic.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themeTitle()

                Text("Recording controls will be added in Phase 2.")
                    .themeSecondaryText()
            }
            .liquidGlassCard()

            VStack(alignment: .leading, spacing: 10) {
                Text(statusTitle)
                    .font(.headline)
                    .themeTitle()
                Text(statusMessage)
                    .themeSecondaryText()
            }
            .liquidGlassCard()

            primaryActionButton

            if viewModel.permissionStatus == .granted {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Elapsed Time")
                        .font(.subheadline)
                        .themeMutedText()
                    Text(formattedElapsedTime)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .themeTitle()
                }
                .liquidGlassCard()
            }

            if let savedRecordingURL = viewModel.savedRecordingURL {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Saved Recording")
                        .font(.subheadline)
                        .themeMutedText()
                    Text(savedRecordingURL.lastPathComponent)
                        .font(.headline)
                        .themeTitle()
                    Text(savedRecordingURL.path)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .themeSecondaryText()
                }
                .liquidGlassCard()
            }

            if viewModel.permissionStatus == .denied {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Microphone access is currently off for this app.")
                        .font(.subheadline)
                        .themeTitle()
                    Text("Open Settings and enable microphone access to continue with recording in Phase 2.")
                        .font(.subheadline)
                        .themeSecondaryText()
                }
                .liquidGlassCard()
            }

            if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recording Error")
                        .font(.subheadline)
                        .themeTitle()
                    Text(errorMessage)
                        .font(.subheadline)
                        .themeSecondaryText()
                }
                .liquidGlassCard()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(AppTheme.contentPadding)
        .appScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.refreshPermissionStatus()
        }
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        switch viewModel.permissionStatus {
        case .undetermined:
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

        case .granted:
            Button {
                viewModel.toggleRecording()
            } label: {
                Label(
                    viewModel.recordingState == .recording ? "Stop Recording" : "Start Recording",
                    systemImage: viewModel.recordingState == .recording ? "stop.circle" : "record.circle"
                )
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle()

        case .denied:
            Button {
                openSettings()
            } label: {
                Label("Open Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .liquidGlassButtonStyle()
        }
    }

    private var statusTitle: String {
        switch viewModel.permissionStatus {
        case .undetermined:
            return "Permission Needed"
        case .granted:
            return "Microphone Ready"
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
            case .recording:
                return "Recording in progress. Tap stop when you are done."
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
