import Foundation
import UniformTypeIdentifiers

protocol AudioFileImportServicing {
    var supportedContentTypes: [UTType] { get }
    func importAudioFile(from sourceURL: URL) throws -> URL
}

struct AudioFileImportService: AudioFileImportServicing {
    private let fileManager = FileManager.default

    var supportedContentTypes: [UTType] {
        [
            .audio,
            UTType(filenameExtension: "m4a"),
            UTType(filenameExtension: "mp3"),
            UTType(filenameExtension: "wav"),
            UTType(filenameExtension: "aac"),
            UTType(filenameExtension: "mp4"),
            UTType(filenameExtension: "caf"),
            UTType(filenameExtension: "aiff")
        ]
        .compactMap { $0 }
    }

    func importAudioFile(from sourceURL: URL) throws -> URL {
        let hasScopedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let importsDirectory = try importsDirectoryURL()
        let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destinationURL = importsDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    private func importsDirectoryURL() throws -> URL {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioFileImportError.importsDirectoryUnavailable
        }

        let importsDirectory = documentsDirectory.appendingPathComponent("ImportedAudio", isDirectory: true)
        if !fileManager.fileExists(atPath: importsDirectory.path) {
            try fileManager.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
        }

        return importsDirectory
    }
}

enum AudioFileImportError: LocalizedError {
    case importsDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .importsDirectoryUnavailable:
            return "The imported audio directory could not be created."
        }
    }
}
