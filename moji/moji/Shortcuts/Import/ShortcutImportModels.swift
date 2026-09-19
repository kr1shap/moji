import Foundation

struct ShortcutImportRow: Equatable, Sendable {
    let rowNumber: Int
    let alias: String
    let emoji: String
}

struct ShortcutImportIssue: Identifiable, Equatable, Sendable {
    let rowNumber: Int
    let message: String

    var id: String {
        "\(rowNumber)-\(message)"
    }
}

struct ShortcutCSVParseResult: Equatable, Sendable {
    let rows: [ShortcutImportRow]
    let issues: [ShortcutImportIssue]
}

enum ShortcutImportAction: String, Equatable, Sendable {
    case add
    case override
}

struct ShortcutImportEntry: Identifiable, Equatable, Sendable {
    let rowNumber: Int
    let alias: String
    let emoji: String
    let action: ShortcutImportAction

    var id: String { alias }
}

struct ShortcutImportPreview: Identifiable, Equatable, Sendable {
    let id: UUID
    let entries: [ShortcutImportEntry]
    let issues: [ShortcutImportIssue]
    let supersededRowCount: Int

    init(
        id: UUID = UUID(),
        entries: [ShortcutImportEntry],
        issues: [ShortcutImportIssue],
        supersededRowCount: Int
    ) {
        self.id = id
        self.entries = entries
        self.issues = issues
        self.supersededRowCount = supersededRowCount
    }

    var addedCount: Int {
        entries.count { $0.action == .add }
    }

    var updatedCount: Int {
        entries.count { $0.action == .override }
    }

    var skippedCount: Int {
        issues.count + supersededRowCount
    }
}

struct ShortcutImportResult: Equatable, Sendable {
    let addedCount: Int
    let updatedCount: Int
    let skippedCount: Int
}

enum ShortcutCSVParserError: LocalizedError, Equatable {
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            "The selected CSV must use UTF-8 text encoding."
        }
    }
}

enum ShortcutImportFileError: LocalizedError, Equatable {
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            "The selected CSV must be 5 MB or smaller."
        }
    }
}
