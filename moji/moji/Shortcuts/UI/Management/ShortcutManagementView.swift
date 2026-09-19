import SwiftUI
import UniformTypeIdentifiers

struct ShortcutManagementView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ShortcutManagementViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            header
            shortcutContent
            footer
        }
        .padding(15)
        .frame(width: 440, height: 400)
        .sheet(item: $viewModel.presentedSheet) { sheet in
            switch sheet {
            case let .editor(mode):
                ShortcutEditorView(mode: mode, onSave: saveShortcut)
            case let .importPreview(preview):
                ShortcutImportPreviewView(
                    preview: preview,
                    onImport: coordinator.applyShortcutImport,
                    onComplete: viewModel.presentImportResult
                )
            }
        }
        .confirmationDialog(
            "Delete Shortcut?",
            isPresented: $viewModel.isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deletePendingShortcut(using: coordinator)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let shortcutPendingDeletion = viewModel.shortcutPendingDeletion {
                Text("This removes :\(shortcutPendingDeletion.alias): from Moji.")
            }
        }
        .alert(viewModel.activeAlert?.title ?? "", isPresented: $viewModel.isAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.activeAlert?.message ?? "")
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false,
            onCompletion: { result in
                viewModel.handleFileSelection(result, using: coordinator)
            },
            onCancellation: {}
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shortcut management")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 4) {
            Image("moji")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("shortcuts")
                    .font(.appTitle)
                Text("the phrases you use the most.")
                    .font(.bodyText)
            }
            .padding(.top, 5)

            Spacer(minLength: 4)
            HStack{
                MojiActionButton(viewModel.isPreparingImport ? "reading..." : "auto-import", width: 88) {
                    viewModel.isFileImporterPresented = true
                }
                .disabled(viewModel.isPreparingImport)
                .accessibilityLabel("Auto-import shortcuts")
                .accessibilityIdentifier("autoImportButton")
                
                MojiActionButton("add", action: viewModel.presentAddShortcut)
                    .accessibilityLabel("Add shortcut")
                    .accessibilityIdentifier("addShortcutButton")
            }
            .padding(.top, 4)
        }
    }

    private var shortcutContent: some View {
        Group {
            if coordinator.repository.shortcuts.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 24))
                    Text("no shortcuts yet")
                        .font(.header)
                    Text("add one to replace a typed alias with an emoji.")
                        .font(.bodyText)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(coordinator.repository.shortcuts, id: \.persistentModelID) { shortcut in
                            EmojiShortcutRow(
                                shortcut: shortcut,
                                onEdit: { viewModel.presentEditor(for: shortcut) },
                                onToggleEnabled: {
                                    viewModel.updateEnabledState(for: shortcut, using: coordinator)
                                },
                                onDelete: { viewModel.confirmDeletion(of: shortcut) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 290)
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text("\(coordinator.repository.shortcuts.count) configured")
                .font(.bodyText)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            MojiActionButton("done", action: dismiss.callAsFunction)
                .accessibilityIdentifier("doneButton")
        }
        .padding(.top, 10)
    }

    private func saveShortcut(alias: String, emoji: String) throws {
        try viewModel.saveShortcut(alias: alias, emoji: emoji, using: coordinator)
    }
}

// Preview-only examples for management-screen data states.
#Preview("Empty") {
    ShortcutManagementView()
        .environment(AppCoordinator.preview())
}

#Preview("Populated") {
    ShortcutManagementView()
        .environment(AppCoordinator.preview(shortcuts: [
            ("skull", "💀", true),
            ("party", "🎉", false)
        ]))
}
