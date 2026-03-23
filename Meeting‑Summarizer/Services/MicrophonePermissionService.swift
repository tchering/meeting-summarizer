import AVFoundation
import Foundation

enum MicrophonePermissionStatus: Equatable {
    case undetermined
    case granted
    case denied

    init(authorizationStatus: AVAuthorizationStatus) {
        switch authorizationStatus {
        case .authorized:
            self = .granted
        case .notDetermined:
            self = .undetermined
        case .denied, .restricted:
            self = .denied
        @unknown default:
            self = .denied
        }
    }
}

protocol MicrophonePermissionServicing {
    func currentStatus() -> MicrophonePermissionStatus
    func requestPermission() async -> MicrophonePermissionStatus
}

struct MicrophonePermissionService: MicrophonePermissionServicing {
    func currentStatus() -> MicrophonePermissionStatus {
        MicrophonePermissionStatus(
            authorizationStatus: AVCaptureDevice.authorizationStatus(for: .audio)
        )
    }

    func requestPermission() async -> MicrophonePermissionStatus {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        return granted ? .granted : .denied
    }
}
