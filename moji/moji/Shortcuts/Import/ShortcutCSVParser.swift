import Foundation

enum ShortcutCSVParser {
    private enum FieldState {
        case start
        case unquoted
        case quoted
        case afterQuote
    }

    static func parse(_ data: Data) throws -> ShortcutCSVParseResult {
        guard var text = String(data: data, encoding: .utf8) else {
            throw ShortcutCSVParserError.invalidUTF8
        }
        if text.first == "\u{FEFF}" {
            text.removeFirst()
        }

        var rows: [ShortcutImportRow] = []
        var issues: [ShortcutImportIssue] = []
        var fields: [String] = []
        var field = ""
        var state = FieldState.start
        var firstSyntaxError: String?
        var rowNumber = 1
        var currentLine = 1
        var recordHasSyntax = false
        var index = text.startIndex

        func finishRecord() {
            guard recordHasSyntax else {
                fields.removeAll(keepingCapacity: true)
                field = ""
                state = .start
                firstSyntaxError = nil
                return
            }

            fields.append(field)
            if let firstSyntaxError {
                issues.append(ShortcutImportIssue(rowNumber: rowNumber, message: firstSyntaxError))
            } else if fields.count != 2 {
                issues.append(ShortcutImportIssue(
                    rowNumber: rowNumber,
                    message: "Expected 2 columns but found \(fields.count)."
                ))
            } else {
                rows.append(ShortcutImportRow(
                    rowNumber: rowNumber,
                    alias: fields[0],
                    emoji: fields[1]
                ))
            }

            fields.removeAll(keepingCapacity: true)
            field = ""
            state = .start
            firstSyntaxError = nil
            recordHasSyntax = false
        }

        while index < text.endIndex {
            let character = text[index]
            let nextIndex = text.index(after: index)
            let isNewline = character == "\n" || character == "\r"

            if isNewline {
                if state == .quoted {
                    field.append("\n")
                    recordHasSyntax = true
                } else {
                    finishRecord()
                    rowNumber = currentLine + 1
                }

                if character == "\r", nextIndex < text.endIndex, text[nextIndex] == "\n" {
                    index = text.index(after: nextIndex)
                } else {
                    index = nextIndex
                }
                currentLine += 1
                continue
            }

            switch character {
            case "," where state != .quoted:
                fields.append(field)
                field = ""
                state = .start
                recordHasSyntax = true

            case "\"":
                recordHasSyntax = true
                switch state {
                case .start:
                    state = .quoted
                case .unquoted:
                    firstSyntaxError = firstSyntaxError ?? "Unexpected quote in an unquoted field."
                case .quoted:
                    if nextIndex < text.endIndex, text[nextIndex] == "\"" {
                        field.append("\"")
                        index = text.index(after: nextIndex)
                        continue
                    } else {
                        state = .afterQuote
                    }
                case .afterQuote:
                    firstSyntaxError = firstSyntaxError ?? "Unexpected quote after a closing quote."
                }

            default:
                if !character.isWhitespace {
                    recordHasSyntax = true
                }
                switch state {
                case .start:
                    field.append(character)
                    state = .unquoted
                case .unquoted, .quoted:
                    field.append(character)
                case .afterQuote:
                    firstSyntaxError = firstSyntaxError ?? "Unexpected character after a closing quote."
                }
            }

            index = nextIndex
        }

        if state == .quoted {
            firstSyntaxError = firstSyntaxError ?? "Unterminated quoted field."
        }
        finishRecord()

        return ShortcutCSVParseResult(rows: rows, issues: issues)
    }
}
