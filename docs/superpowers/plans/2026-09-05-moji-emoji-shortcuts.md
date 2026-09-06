# Moji Emoji Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Use `swiftui-expert-skill` while implementing SwiftUI milestones and `swiftui-pro` as the pre-commit SwiftUI review gate. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Moji, a macOS menu-bar utility that replaces user-configured colon-delimited emoji shortcodes in supported text fields.

**Architecture:** A SwiftUI menu-bar app owns an application coordinator, durable shortcut store, and Accessibility-gated active `CGEvent` tap. The tap normalizes key-down events and hands them to a pure bounded state machine backed by an in-memory shortcut index. A successful match suppresses only the closing colon and invokes a pasteboard-first replacement coordinator.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, AppKit, ApplicationServices/CoreGraphics, XCTest and Swift Testing, macOS 15.4.

**Spec:** `README.md`

## Global Constraints

- Retain the existing macOS 15.4 deployment target and `com.krishap.moji` bundle identifier.
- Moji is an agent-style menu-bar app with `LSUIElement = YES`; it has no primary application window.
- Do not use `InputMethodKit`, IMKSwift, or a custom input-source bundle.
- Persist only intentional shortcut save actions; never seed, infer, or auto-create shortcuts.
- Store aliases canonically without delimiters (`skull`), while typed syntax is always `:skull:`.
- Permit aliases containing only ASCII letters, digits, `_`, `-`, and `+`; set the maximum typed candidate length to 64 Unicode scalars.
- The runtime keyboard path must use an immutable in-memory `[String: String]` index and must not query SwiftData.
- Do not log raw typed text, captured aliases, or emoji replacement values in production logs.
- Start global interception only while the feature is enabled and Accessibility trust is available.
- V1 excludes launch-at-login, suggestions, autocomplete, imports, and favorites UI.
- V1 uses pasteboard-first insertion: snapshot clipboard, post backspaces, paste emoji, and restore the snapshot on a best-effort basis.
- Use Observation for new UI state: `@Observable @MainActor` models, `@State` ownership, `@Environment` injection, and `@Bindable` only where a view needs bindings. Do not introduce `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
- Keep all view-owned `@State` and `@FocusState` properties `private`; never mark passed values as `@State`.
- Keep each production type in its own Swift file, extract stateful or substantial sections into dedicated `View` types, and keep view initializers and bodies free of persistence, sorting, filtering, and other business logic.
- Use stable SwiftData identity in `ForEach`, one top-level row view per item, and a pre-sorted repository snapshot rather than sorting or filtering inside `body`.
- Use semantic SwiftUI controls and styles: `Button` instead of tap gestures, `Label` for icon-plus-text controls, `foregroundStyle`, modern `onChange`, trailing-closure `Section`, and `ContentUnavailableView` for an empty shortcut list.
- Every user-facing control must have a useful text label for VoiceOver; decorative symbols must be hidden from accessibility; status must be conveyed by text/icon as well as color.
- Every SwiftUI view must have self-contained `#Preview` coverage for its meaningful states using in-memory or static mock data and no production defaults, disk persistence, permissions, or global event tap.
- Do not adopt Liquid Glass styling unless the user explicitly adds it to scope.

## Required Skill Gates

- At the start of every milestone that creates or changes SwiftUI, invoke `swiftui-expert-skill` and read `references/latest-apis.md` plus the topic references named in that milestone.
- Before committing Milestones 1, 2, 4, and 6, invoke `swiftui-pro` and review the changed SwiftUI files against its API, views, data, design, accessibility, performance, Swift, and hygiene references. Fix genuine findings, rerun tests, then commit.
- During Milestone 7, run one final full-project `swiftui-pro` review and a `swiftui-expert-skill` correctness pass covering state ownership, stable list identity, view composition, previews, accessibility, and macOS scene usage.
- `swiftui-expert-skill` governs implementation choices; `swiftui-pro` is the independent review checklist. Where their generic iOS defaults conflict with this repository, the project facts win: this is a macOS 15.4 app using the existing Swift language mode until a separate migration is requested.

## Target File Structure

```text
moji/moji/
  App/
    MojiApp.swift
    AppCoordinator.swift
    RuntimeState.swift
  MenuBar/
    MenuBarView.swift
    ShortcutListView.swift
    ShortcutEditorView.swift
    PermissionStatusView.swift
  Persistence/
    EmojiShortcut.swift
    EmojiShortcutRepository.swift
    PreferencesStore.swift
    ModelContainerFactory.swift
  Keyboard/
    KeyboardInput.swift
    NormalizedKeyboardEvent.swift
    EventDisposition.swift
    KeyboardEventNormalizer.swift
    ShortcodeDecision.swift
    ShortcodeStateMachine.swift
    GlobalEventTap.swift
    ReplacementCoordinator.swift
  Support/
    AccessibilityPermission.swift
moji/mojiTests/
  EmojiShortcutRepositoryTests.swift
  ShortcodeStateMachineTests.swift
  ReplacementCoordinatorTests.swift
  PreferencesStoreTests.swift
moji/mojiUITests/
  MenuBarShortcutManagementUITests.swift
```

---

## Milestone 1 — Menu-bar foundation

**Commit:** `chore: prepare macOS menu bar app foundation`

**Files:**

- Create: `moji/moji/App/MojiApp.swift`, `moji/moji/App/AppCoordinator.swift`, `moji/moji/MenuBar/MenuBarView.swift`, `moji/moji/Persistence/ModelContainerFactory.swift`
- Modify: `moji/moji/mojiApp.swift`, `moji/moji/ContentView.swift`, `moji/moji.xcodeproj/project.pbxproj`, `moji/moji/moji.entitlements`
- Test: `moji/mojiUITests/mojiUITests.swift`

**Interfaces:**

```swift
@MainActor
@Observable
final class AppCoordinator {
    private(set) var runtimeState: RuntimeState
    init(modelContainer: ModelContainer)
    func start()
    func stop()
}

enum RuntimeState: Equatable {
    case disabled
    case permissionRequired
    case active
    case error(String)
}

enum ModelContainerFactory {
    static func makePersistent() throws -> ModelContainer
    static func makeInMemory() throws -> ModelContainer
}
```

- [ ] Invoke `swiftui-expert-skill` and apply `references/latest-apis.md`, `references/state-management.md`, `references/view-structure.md`, `references/macos-scenes.md`, `references/accessibility-patterns.md`, and `references/previews.md` to this milestone.
- [ ] Replace the starter `WindowGroup` entry point with a window-style `MenuBarExtra` owned through `@State private var coordinator` in `MojiApp`, then inject it with `.environment(coordinator)`.
- [ ] Configure `LSUIElement` in the generated Info.plist build settings and remove the unused starter `ContentView` after its replacement is compiling.
- [ ] Create a `ModelContainerFactory` with a persistent production container and an in-memory test container; use an empty schema initially and update it in Milestone 2.
- [ ] Create `@Observable @MainActor AppCoordinator` with explicit `start` and `stop` lifecycle methods, initially exposing `.disabled`; call `start` from app launch and `stop` during termination.
- [ ] Render a menu-bar view showing the application name, a disabled status row, and Quit action. Do not add settings logic yet.
- [ ] Add self-contained `#Preview` variants for Disabled, Permission Required, Active, and Error using a preview-only coordinator with no live services.
- [ ] Inspect the existing sandbox entitlement before wiring accessibility APIs. If App Sandbox prevents the signed build from receiving the required active event tap, remove only the `com.apple.security.app-sandbox` entitlement and document the reason in the project README; retain hardened runtime and automatic signing.
- [ ] Update the existing UI launch test to assert the application launches and the menu-bar scene is created without a primary window.
- [ ] Invoke `swiftui-pro`, review all changed SwiftUI files, fix genuine findings, and verify there is no legacy observation, icon-only unlabeled button, obsolete API, business logic in `body`, or live dependency in previews.
- [ ] Run `xcodebuild -project moji/moji.xcodeproj -scheme moji -configuration Debug build` and `xcodebuild -project moji/moji.xcodeproj -scheme moji test`; commit only after both pass.

## Milestone 2 — Durable shortcuts and management UI

**Commit:** `feat: add persisted emoji shortcut management`

**Files:**

- Create: `moji/moji/Persistence/EmojiShortcut.swift`, `moji/moji/Persistence/EmojiShortcutRepository.swift`, `moji/moji/Persistence/PreferencesStore.swift`, `moji/moji/MenuBar/ShortcutListView.swift`, `moji/moji/MenuBar/ShortcutEditorView.swift`, `moji/mojiTests/EmojiShortcutRepositoryTests.swift`, `moji/mojiTests/PreferencesStoreTests.swift`
- Modify: `moji/moji/App/AppCoordinator.swift`, `moji/moji/App/MojiApp.swift`, `moji/moji/MenuBar/MenuBarView.swift`, `moji/moji/Persistence/ModelContainerFactory.swift`

**Interfaces:**

```swift
@Model
final class EmojiShortcut {
    @Attribute(.unique) var alias: String
    var emoji: String
    var createdAt: Date
    var updatedAt: Date
    var isEnabled: Bool
}

enum ShortcutValidationError: LocalizedError, Equatable {
    case emptyAlias
    case invalidAlias
    case emptyEmoji
    case duplicateAlias
}

@MainActor
@Observable
final class EmojiShortcutRepository {
    private(set) var shortcuts: [EmojiShortcut]
    private(set) var runtimeIndex: [String: String]
    init(modelContext: ModelContext)
    func load() throws
    func create(alias: String, emoji: String) throws
    func update(_ shortcut: EmojiShortcut, alias: String, emoji: String, isEnabled: Bool) throws
    func delete(_ shortcut: EmojiShortcut) throws
    static func normalize(alias: String) throws -> String
}

@MainActor
@Observable
final class PreferencesStore {
    var isEnabled: Bool
    init(defaults: UserDefaults = .standard)
}
```

- [ ] Invoke `swiftui-expert-skill` and apply `references/latest-apis.md`, `references/state-management.md`, `references/view-structure.md`, `references/list-patterns.md`, `references/macos-views.md`, `references/accessibility-patterns.md`, and `references/previews.md` to this milestone.
- [ ] Write repository tests first using `ModelContainerFactory.makeInMemory()`: canonicalize `:skull:` to `skull`, reject empty/invalid aliases and empty emoji, reject duplicates, update `updatedAt`, delete records, and exclude disabled records from `runtimeIndex`.
- [ ] Add `EmojiShortcut` to the SwiftData schema and implement repository reads and writes with `ModelContext.save()` followed by one complete runtime-index refresh.
- [ ] Define `PreferencesStore.isEnabled` with explicit `UserDefaults` reads/writes and Observation tracking using a single typed key (`moji.isEnabled`) that defaults to `false`; do not put `@AppStorage` inside the observable model. Add a test defaults suite so production preferences are never modified by tests.
- [ ] Replace the static menu content with a list using each shortcut's persistent SwiftData identity and an Add Shortcut `Button`. Use `ContentUnavailableView` when empty and a dedicated unary row view for each shortcut. Editor fields must retain `private @State` drafts locally; only the explicit Save action may call `repository.create` or `repository.update`.
- [ ] Make alias input display colon delimiters for clarity while passing the raw field value through repository normalization; display the canonical alias as `:alias:` in the shortcut list.
- [ ] Add edit, delete-with-confirmation, and enabled toggle actions. Show validation errors inline and preserve the editor draft on validation failure.
- [ ] Inject the repository and preferences into `AppCoordinator` and `MenuBarView` from `MojiApp`.
- [ ] Add self-contained `#Preview` variants for empty, populated, add, edit, and validation-error states backed by preview-only values.
- [ ] Invoke `swiftui-pro`, review the list, row, editor, and data-flow changes, fix genuine findings, and verify stable identity, unary rows, modern presentation APIs, semantic buttons, and VoiceOver labels.
- [ ] Run focused repository and preferences tests, then the full `moji` test suite; commit after green results.

## Milestone 3 — Pure keyboard model and shortcode state machine

**Commit:** `feat: add shortcode parsing state machine`

**Files:**

- Create: `moji/moji/Keyboard/KeyboardInput.swift`, `moji/moji/Keyboard/ShortcodeDecision.swift`, `moji/moji/Keyboard/ShortcodeStateMachine.swift`, `moji/mojiTests/ShortcodeStateMachineTests.swift`

**Interfaces:**

```swift
enum KeyboardInput: Equatable {
    case printable(String)
    case backspace
    case escape
    case returnKey
    case tab
    case navigation
    case unsupportedModifier
    case other
}

enum ShortcodeDecision: Equatable {
    case passThrough
    case capture
    case replace(alias: String, emoji: String, deletionCount: Int)
    case resetAndPassThrough
}

struct ShortcodeStateMachine {
    static let timeout: TimeInterval = 2
    mutating func process(_ input: KeyboardInput, at time: Date, shortcuts: [String: String], isEnabled: Bool) -> ShortcodeDecision
    mutating func reset()
}
```

- [ ] Write deterministic tests for `:skull:` replacement, unknown aliases, `::`, malformed candidates, Unicode outside the candidate, maximum length, backspace editing, timeout, repeated colon, disabled mode, and each reset key.
- [ ] Implement the state machine as a value type with only candidate scalar storage and the most-recent input timestamp. Do not retain surrounding document text.
- [ ] Treat the first printable colon as capture start; while capturing accept alias characters, perform exact index lookup on a closing colon, and return `.replace` with `deletionCount` equal to the full candidate scalar count.
- [ ] On a second colon with no valid match, reset and return `.resetAndPassThrough`; on invalid characters or reset events, clear only the candidate and preserve the current user event.
- [ ] Treat keyboard input with Command, Control, or Option as `.unsupportedModifier`; Shift is permitted only insofar as it produces printable characters.
- [ ] Run `ShortcodeStateMachineTests` alone, then the full test suite; commit after green results.

## Milestone 4 — Accessibility-gated global event tap

**Commit:** `feat: observe global keyboard events with accessibility gating`

**Files:**

- Create: `moji/moji/Support/AccessibilityPermission.swift`, `moji/moji/Keyboard/KeyboardEventNormalizer.swift`, `moji/moji/Keyboard/GlobalEventTap.swift`, `moji/moji/MenuBar/PermissionStatusView.swift`
- Modify: `moji/moji/App/AppCoordinator.swift`, `moji/moji/MenuBar/MenuBarView.swift`
- Test: `moji/mojiTests/ShortcodeStateMachineTests.swift`

**Interfaces:**

```swift
protocol AccessibilityPermissionChecking {
    var isTrusted: Bool { get }
    func promptForPermission()
    func openAccessibilitySettings()
}

final class AccessibilityPermission: AccessibilityPermissionChecking { }

struct NormalizedKeyboardEvent {
    let input: KeyboardInput
    let isRepeat: Bool
    let timestamp: Date
}

final class GlobalEventTap {
    var onKeyDown: ((NormalizedKeyboardEvent) -> EventDisposition)?
    func start() throws
    func stop()
}

enum EventDisposition { case passThrough, suppress }
```

- [ ] Implement `AccessibilityPermission` using `AXIsProcessTrustedWithOptions`, with a method that requests the standard prompt and a deep link to Privacy & Security → Accessibility.
- [ ] Invoke `swiftui-expert-skill` and apply `references/latest-apis.md`, `references/state-management.md`, `references/view-structure.md`, `references/macos-views.md`, `references/accessibility-patterns.md`, and `references/previews.md` to the permission UI and coordinator changes.
- [ ] Add `PermissionStatusView` describing why Moji needs Accessibility control, showing a permission-required status, and exposing Request Permission/Open Settings actions.
- [ ] Implement `KeyboardEventNormalizer` to convert `.keyDown` CGEvents into printable text, backspace, Escape, Return, Tab, navigation, modifier, and other categories while retaining the repeat flag and timestamp.
- [ ] Implement a CGEvent tap owned by `GlobalEventTap`; its C callback must only normalize the event, invoke `onKeyDown`, and return the original event or `nil` for suppression. Re-enable the tap if macOS disables it due to timeout or user input.
- [ ] Update `AppCoordinator` to start the tap only when `PreferencesStore.isEnabled` and `AccessibilityPermission.isTrusted` are both true. Stopping the app, disabling the preference, or discovering lost trust must stop the tap and reset the state machine.
- [ ] Pass repeated events through without state-machine processing. For all non-replacement decisions, return `.passThrough`.
- [ ] Add unit tests for normalizer-independent state routing: disabled, missing permission, repeated key, command/control/option events, and tap stop/reset behavior using small protocol-backed test doubles.
- [ ] Add self-contained `#Preview` variants for permission granted, permission required, and runtime error; use semantic `Button` and `Label` controls and never rely on status color alone.
- [ ] Invoke `swiftui-pro`, review the permission and runtime-status SwiftUI, fix genuine findings, and verify Observation ownership, accessible labels, logical focus order, modern APIs, and absence of live permission calls in previews.
- [ ] Build and test the app. Manually grant and revoke Accessibility permission and verify the menu status responds; commit after automated tests pass.

## Milestone 5 — Pasteboard-first replacement coordinator

**Commit:** `feat: replace recognized shortcodes with emoji`

**Files:**

- Create: `moji/moji/Keyboard/ReplacementCoordinator.swift`, `moji/mojiTests/ReplacementCoordinatorTests.swift`
- Modify: `moji/moji/Keyboard/GlobalEventTap.swift`, `moji/moji/App/AppCoordinator.swift`

**Interfaces:**

```swift
protocol PasteboardManaging {
    func snapshot() -> PasteboardSnapshot
    func write(text: String) -> Bool
    func restore(_ snapshot: PasteboardSnapshot)
}

protocol KeyboardEventPosting {
    func postBackspace(count: Int) -> Bool
    func postPasteShortcut() -> Bool
}

struct ReplacementCoordinator {
    func replace(emoji: String, deletionCount: Int) -> Bool
}
```

- [ ] Write mocked coordinator tests for the success sequence, failed emoji write, failed backspace posting, failed paste posting, and snapshot restoration after every attempted replacement.
- [ ] Implement a pasteboard snapshot containing all existing general-pasteboard items and their property lists; restoration must clear the temporary content and restore the captured items in order.
- [ ] Implement event posting for one backspace per `deletionCount`, followed by Command-V; return `false` as soon as a required posting operation fails.
- [ ] On a `.replace` state-machine decision, invoke the coordinator synchronously after the event callback chooses to suppress the final colon. Reset the state machine regardless of success.
- [ ] If a replacement fails, transition `AppCoordinator.runtimeState` to `.error` with a non-sensitive message, stop the event tap, and show the feature as disabled until the user deliberately re-enables it.
- [ ] Do not use direct Unicode CGEvent insertion in V1. Document that replacement briefly uses the general pasteboard and that clipboard managers may observe it.
- [ ] Run coordinator tests and the full suite; commit after green results.

## Milestone 6 — Runtime wiring and user-facing completion

**Commit:** `feat: wire menu bar controls to runtime services`

**Files:**

- Modify: `moji/moji/App/MojiApp.swift`, `moji/moji/App/AppCoordinator.swift`, `moji/moji/MenuBar/MenuBarView.swift`, `moji/moji/MenuBar/ShortcutListView.swift`, `moji/moji/MenuBar/PermissionStatusView.swift`, `README.md`
- Create: `moji/mojiUITests/MenuBarShortcutManagementUITests.swift`

**Interfaces:**

```swift
@MainActor
extension AppCoordinator {
    func setEnabled(_ enabled: Bool)
    func refreshPermissionState()
    func refreshShortcutIndex() throws
}
```

- [ ] Wire the menu Enabled toggle to `setEnabled(_:)`; enabling without trust must leave the feature inactive and reveal permission guidance rather than claiming success.
- [ ] Invoke `swiftui-expert-skill` and apply `references/latest-apis.md`, `references/state-management.md`, `references/view-structure.md`, `references/list-patterns.md`, `references/accessibility-patterns.md`, `references/macos-scenes.md`, and `references/previews.md` before finalizing the composed menu-bar workflow.
- [ ] Ensure every successful repository mutation publishes a new complete `runtimeIndex` to the coordinator before the editor dismisses.
- [ ] Display four unambiguous states in the menu: Disabled, Accessibility Required, Active, and Error. Error copy must not include aliases, typed text, emoji, or target application names.
- [ ] Add a UI test that creates `skull → 💀`, verifies it appears as `:skull:`, edits its enabled state, deletes it through confirmation, and confirms no record remains after relaunch.
- [ ] Update README with first-run permission steps, supported/unsupported behavior, how to add a shortcut, pasteboard behavior, and explicit V1 exclusions.
- [ ] Invoke `swiftui-pro` for a pre-commit review of every SwiftUI file, fix genuine findings, and rerun unit, UI, and preview compilation checks.
- [ ] Run all automated tests and manually verify that enabling/disabling changes interception immediately; commit after green results.

## Milestone 7 — Integration verification and release readiness

**Commit:** `test: verify emoji replacement across supported macOS apps`

**Files:**

- Modify: `README.md`

- [ ] Run `xcodebuild -project moji/moji.xcodeproj -scheme moji -configuration Debug build`.
- [ ] Run `xcodebuild -project moji/moji.xcodeproj -scheme moji -configuration Release build`.
- [ ] Run `xcodebuild -project moji/moji.xcodeproj -scheme moji test`.
- [ ] Manually verify `:skull:` replacement after explicitly creating `skull → 💀` in TextEdit, Notes, Safari, Messages, Slack or Discord, and one Electron application.
- [ ] Verify unknown aliases, `::`, malformed candidates, backspace, Escape, Return, Tab, arrow keys, key repeats, ABC input source, a non-ABC keyboard layout, and Command/Control/Option shortcuts all pass through safely.
- [ ] Verify behavior before granting Accessibility permission, after granting it, and after revoking it while Moji is enabled.
- [ ] Verify the original clipboard content is restored after a successful replacement and after each coordinator failure case that can be induced in testing.
- [ ] Record manual compatibility results and known limitations in README; commit only after Debug build, Release build, and tests succeed.
- [ ] Invoke `swiftui-pro` for a final full-project review and `swiftui-expert-skill` for the final correctness pass; fix genuine findings and rerun Debug build, Release build, and all tests before committing.

## Completion Checklist

- [ ] Every milestone has its own focused commit and passing automated checks.
- [ ] No uncommitted unrelated generated artifacts remain.
- [ ] Moji has no normal Dock window and does not install an input method.
- [ ] No keystroke path performs persistence reads or logs user text.
- [ ] All runtime interception is gated by both the Enabled preference and Accessibility trust.
- [ ] Shortcut creation remains intentional and explicit.
- [ ] All SwiftUI milestones record use of `swiftui-expert-skill`, and all UI commit gates record a clean `swiftui-pro` review.
- [ ] New SwiftUI state uses Observation with correct `@State`, `@Environment`, and `@Bindable` ownership.
- [ ] Shortcut lists use stable model identity and unary row views; previews are self-contained; controls remain usable with VoiceOver and without relying on color alone.
