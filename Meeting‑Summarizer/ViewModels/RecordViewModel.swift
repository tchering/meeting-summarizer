import Foundation
import Observation

@MainActor
@Observable
final class RecordViewModel {
    private(set) var permissionStatus: MicrophonePermissionStatus
    private(set) var isRequestingPermission = false

    private let permissionService: MicrophonePermissionServicing

    init(permissionService: MicrophonePermissionServicing = MicrophonePermissionService()) {
        self.permissionService = permissionService
        self.permissionStatus = permissionService.currentStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = permissionService.currentStatus()
    }

    func requestMicrophoneAccess() async {
        guard !isRequestingPermission else {
            return
        }

        isRequestingPermission = true
        permissionStatus = await permissionService.requestPermission()
        isRequestingPermission = false
    }
}
