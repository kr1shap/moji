import Foundation

enum ShortcutImportFileLoader {
    static let maximumByteCount = 5 * 1_024 * 1_024

    static func loadAndParse(_ url: URL) async throws -> ShortcutCSVParseResult {
        try await Task.detached(priority: .userInitiated) {
            let hasSecurityAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }

            let data = try fileHandle.read(upToCount: maximumByteCount + 1) ?? Data()
            guard data.count <= maximumByteCount else {
                throw ShortcutImportFileError.fileTooLarge
            }
            return try ShortcutCSVParser.parse(data)
        }.value
    }
}
