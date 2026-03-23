import Foundation

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]

    init(
        path: String,
        method: HTTPMethod = .post,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
    }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct UploadFile: Sendable {
    let data: Data
    let fieldName: String
    let fileName: String
    let mimeType: String
}

@MainActor
protocol APIClienting {
    func post<RequestBody: Encodable & Sendable, ResponseBody: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody

    func upload<ResponseBody: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        file: UploadFile,
        fields: [String: String],
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody
}

@MainActor
struct APIClient: APIClienting {
    let baseURL: URL
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    func post<RequestBody: Encodable & Sendable, ResponseBody: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        var request = try makeRequest(for: endpoint)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(body)

        return try await send(request, responseType: responseType)
    }

    func upload<ResponseBody: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        file: UploadFile,
        fields: [String: String] = [:],
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try makeRequest(for: endpoint)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(file: file, fields: fields, boundary: boundary)

        return try await send(request, responseType: responseType)
    }

    func makeRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        for (header, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return request
    }

    func send<ResponseBody: Decodable & Sendable>(
        _ request: URLRequest,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let (data, response) = try await session.data(for: request)
        let httpResponse = try validate(response: response, data: data)

        do {
            return try jsonDecoder.decode(ResponseBody.self, from: data)
        } catch {
            throw APIClientError.decodingFailed(statusCode: httpResponse.statusCode, underlyingError: error)
        }
    }

    func validate(response: URLResponse, data: Data) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8)
            throw APIClientError.requestFailed(statusCode: httpResponse.statusCode, responseBody: responseBody)
        }

        return httpResponse
    }

    func makeMultipartBody(file: UploadFile, fields: [String: String], boundary: String) -> Data {
        var body = Data()

        for (name, value) in fields.sorted(by: { $0.key < $1.key }) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n")
        body.append("Content-Type: \(file.mimeType)\r\n\r\n")
        body.append(file.data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        return body
    }
}

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, responseBody: String?)
    case decodingFailed(statusCode: Int, underlyingError: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API request URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case let .requestFailed(statusCode, responseBody):
            if let responseBody, !responseBody.isEmpty {
                return "The request failed with status code \(statusCode): \(responseBody)"
            }
            return "The request failed with status code \(statusCode)."
        case let .decodingFailed(statusCode, underlyingError):
            return "The response could not be decoded after a \(statusCode) response: \(underlyingError.localizedDescription)"
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
