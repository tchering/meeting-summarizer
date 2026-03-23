import SwiftUI
import UIKit

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
            } label: {
                Label("Microphone Ready", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .disabled(true)
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
            return "Permission has been granted. Recording controls will be added next."
        case .denied:
            return "Microphone access was denied. You can enable it later in Settings."
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
