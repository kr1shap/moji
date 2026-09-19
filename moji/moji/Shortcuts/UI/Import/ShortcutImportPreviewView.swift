import SwiftUI

struct ShortcutImportPreviewView: View {
    let preview: ShortcutImportPreview
    let onImport: (ShortcutImportPreview) throws -> ShortcutImportResult
    let onComplete: (ShortcutImportResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var importErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Shortcuts")
                .font(.appTitle)

            Label(
                "Shortcuts with matching names will be overwritten.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.bodyText)
            .foregroundStyle(.orange)

            HStack(spacing: 8) {
                countLabel(title: "add", count: preview.addedCount)
                countLabel(title: "override", count: preview.updatedCount)
                countLabel(title: "skip", count: preview.skippedCount)
            }

            previewContent

            if let importErrorMessage {
                Label(importErrorMessage, systemImage: "exclamationmark.triangle")
                    .font(.validationText)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Import error: \(importErrorMessage)")
            }

            HStack {
                MojiActionButton("cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                MojiActionButton("import & override", width: 125, action: applyImport)
                    .keyboardShortcut(.defaultAction)
                    .disabled(preview.entries.isEmpty)
                    .accessibilityHint("Imports new shortcuts and overwrites matching shortcuts")
                    .accessibilityIdentifier("confirmShortcutImportButton")
            }
        }
        .padding(15)
        .frame(width: 500, height: 480)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shortcut import preview")
    }

    @ViewBuilder
    private var previewContent: some View {
        if preview.entries.isEmpty, preview.issues.isEmpty {
            ContentUnavailableView {
                Label("No Shortcuts Found", systemImage: "doc.text.magnifyingglass")
                    .font(.header)
            } description: {
                Text("Add rows in shortcut,emoji format and choose the file again.")
                    .font(.bodyText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(preview.entries) { entry in
                        ShortcutImportPreviewRow(entry: entry)
                    }

                    if preview.supersededRowCount > 0 {
                        ShortcutImportIssueRow(
                            message: "\(preview.supersededRowCount) earlier duplicate row\(preview.supersededRowCount == 1 ? " was" : "s were") superseded by the last valid value."
                        )
                    }

                    ForEach(preview.issues) { issue in
                        ShortcutImportIssueRow(
                            message: "Row \(issue.rowNumber): \(issue.message)"
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func countLabel(title: String, count: Int) -> some View {
        Text("\(count) \(title)")
            .font(.bodyText)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(.primary.opacity(0.08), in: Capsule())
            .accessibilityLabel("\(count) \(title)")
    }

    private func applyImport() {
        do {
            let result = try onImport(preview)
            onComplete(result)
            dismiss()
        } catch {
            importErrorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Moji could not import these shortcuts."
        }
    }
}

#Preview("Import Preview") {
    ShortcutImportPreviewView(
        preview: ShortcutImportPreview(
            entries: [
                ShortcutImportEntry(rowNumber: 1, alias: "skull", emoji: "💀", action: .add),
                ShortcutImportEntry(rowNumber: 2, alias: "party", emoji: "🥳", action: .override)
            ],
            issues: [
                ShortcutImportIssue(rowNumber: 3, message: "Enter a shortcut name.")
            ],
            supersededRowCount: 1
        ),
        onImport: { preview in
            ShortcutImportResult(
                addedCount: preview.addedCount,
                updatedCount: preview.updatedCount,
                skippedCount: preview.skippedCount
            )
        },
        onComplete: { _ in }
    )
}
