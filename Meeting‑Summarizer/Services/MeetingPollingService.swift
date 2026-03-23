import Foundation
import Observation

struct MeetingPollingConfiguration: Sendable {
    let baseURL: URL
    let endpointPathTemplate: String
    let pollingInterval: Duration
    let maxAttempts: Int

    init(
        baseURL: URL,
        endpointPathTemplate: String = "meetings/{jobID}",
        pollingInterval: Duration = .seconds(2),
        maxAttempts: Int = 15
    ) {
        self.baseURL = baseURL
        self.endpointPathTemplate = endpointPathTemplate
        self.pollingInterval = pollingInterval
        self.maxAttempts = maxAttempts
    }
}

enum MeetingPollingState: Equatable {
    case idle
    case polling
    case completed
    case failed(String)
}

@MainActor
@Observable
final class MeetingPollingService {
    private(set) var state: MeetingPollingState = .idle

    private let configuration: MeetingPollingConfiguration?
    private let apiClient: APIClient?

    init(configuration: MeetingPollingConfiguration? = nil, session: URLSession = .shared) {
        self.configuration = configuration

        if let configuration {
            self.apiClient = APIClient(baseURL: configuration.baseURL, session: session)
        } else {
            self.apiClient = nil
        }
    }

    func poll(jobID: String) async -> BackendMeetingResult? {
        guard let configuration, let apiClient else {
            state = .failed("Polling is not configured yet.")
            AppLogger.processingFailed(jobID: nil, message: "Polling is not configured yet.")
            return nil
        }

        state = .polling
        AppLogger.processingPollingStarted(jobID: jobID)

        for _ in 0..<configuration.maxAttempts {
            do {
                let endpoint = APIEndpoint(
                    path: configuration.endpointPathTemplate.replacingOccurrences(of: "{jobID}", with: jobID),
                    method: .get
                )
                let result = try await apiClient.get(endpoint, responseType: BackendMeetingResult.self)

                switch result.status {
                case .completed:
                    state = .completed
                    AppLogger.processingCompleted(jobID: jobID)
                    return result
                case .failed:
                    state = .failed("Backend processing failed.")
                    AppLogger.processingFailed(jobID: jobID, message: "Backend processing failed.")
                    return result
                case .processing, .uploading, .recorded:
                    try? await Task.sleep(for: configuration.pollingInterval)
                }
            } catch {
                state = .failed(error.localizedDescription)
                AppLogger.processingFailed(jobID: jobID, message: error.localizedDescription)
                return nil
            }
        }

        state = .failed("Polling timed out before the backend finished processing.")
        AppLogger.processingFailed(jobID: jobID, message: "Polling timed out before the backend finished processing.")
        return nil
    }
}
