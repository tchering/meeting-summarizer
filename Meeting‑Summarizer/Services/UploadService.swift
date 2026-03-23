import Foundation
import Observation

enum UploadState: Equatable {
    case idle
    case uploading(progress: Double)
    case success(UploadReceipt)
    case failure(String)
}

struct UploadServiceConfiguration: Sendable {
    let baseURL: URL
    let endpoint: APIEndpoint
    let fileFieldName: String

    init(baseURL: URL, endpoint: APIEndpoint, fileFieldName: String = "file") {
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.fileFieldName = fileFieldName
    }
}

@MainActor
@Observable
final class UploadService {
    private(set) var state: UploadState = .idle
    private(set) var isUploading = false

    private let apiClient: APIClient?
    private let configuration: UploadServiceConfiguration?
    private let session: URLSession
    private let jsonDecoder = JSONDecoder()

    init(
        configuration: UploadServiceConfiguration? = nil,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        if let configuration {
            self.apiClient = APIClient(baseURL: configuration.baseURL, session: session)
        } else {
            self.apiClient = nil
        }
    }

    func uploadAudioFile(at fileURL: URL, fields: [String: String] = [:]) async {
        guard !isUploading else {
            return
        }

        guard let configuration, let apiClient else {
            state = .failure("Backend upload endpoint is not configured yet.")
            return
        }

        do {
            isUploading = true
            state = .uploading(progress: 0)

            let fileData = try Data(contentsOf: fileURL)
            let uploadFile = UploadFile(
                data: fileData,
                fieldName: configuration.fileFieldName,
                fileName: fileURL.lastPathComponent,
                mimeType: "audio/m4a"
            )

            var request = try apiClient.makeRequest(for: configuration.endpoint)
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let body = apiClient.makeMultipartBody(file: uploadFile, fields: fields, boundary: boundary)

            let (data, response) = try await performUpload(request: request, body: body)
            _ = try apiClient.validate(response: response, data: data)

            let receipt = try decodeUploadReceipt(from: data)
            state = .success(receipt)
        } catch {
            state = .failure(error.localizedDescription)
        }

        isUploading = false
    }

    private func performUpload(request: URLRequest, body: Data) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.uploadTask(with: request, from: body) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data, let response else {
                    continuation.resume(throwing: UploadServiceError.invalidUploadResponse)
                    return
                }

                continuation.resume(returning: (data, response))
            }

            Task { @MainActor in
                while task.state == .running || task.state == .suspended {
                    state = .uploading(progress: max(task.progress.fractionCompleted, 0.02))
                    try? await Task.sleep(for: .milliseconds(120))
                }
            }

            task.resume()
        }
    }

    private func decodeUploadReceipt(from data: Data) throws -> UploadReceipt {
        if let decoded = try? jsonDecoder.decode(UploadReceipt.self, from: data) {
            return decoded
        }

        let message = String(data: data, encoding: .utf8)
        return UploadReceipt(jobID: nil, message: message?.isEmpty == true ? nil : message, status: nil)
    }
}

enum UploadServiceError: LocalizedError {
    case invalidUploadResponse

    var errorDescription: String? {
        switch self {
        case .invalidUploadResponse:
            return "The upload finished without a valid server response."
        }
    }
}
