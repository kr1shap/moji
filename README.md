# Mac Emoji Shortcuts — Implementation Plan

## Goal

Build a native macOS menu-bar utility that runs continuously in the background and replaces Discord-style emoji shortcodes such as `:skull:` with their configured Unicode emoji while the normal ABC keyboard/input source remains active.

The first release is intentionally a focused utility: menu-bar controls, custom shortcuts, global typing detection, persistence, and reliable replacement. It does not implement a custom input method and does not depend on IMKSwift or `InputMethodKit`.

## Product requirements

- Run as a background utility, similar to Scroll Reverser.
- Present a simple SwiftUI menu-bar interface rather than a primary window.
- Detect shortcode typing globally in supported macOS text fields.
- Use colon `:` as the trigger and terminator: `:skull:` → `💀`.
- Keep the normal ABC keyboard/input source active.
- Allow the user/builder to explicitly add, edit, delete, enable, and disable custom shortcuts.
- Never create or persist a custom shortcut automatically; shortcuts are added only after an intentional UI add/save action.
- Persist lightweight preferences with `UserDefaults`.
- Persist custom shortcuts with SwiftData.
- Keep a bounded text buffer/state machine; never retain arbitrary document contents.
- Provide clear permission status and setup guidance for Accessibility access.

> The original discussion mentioned “semicolon,” but the examples and Discord convention use a colon. This plan standardizes on colon-triggered shortcodes.

## Recommended architecture

```text
Menu-bar SwiftUI app
        │
        ├── Settings / shortcut management
        ├── Permission and enabled-state controls
        └── App lifecycle / login-item coordination

Global CGEvent tap
        │  keyDown events only
        ▼
Keyboard event normalizer
        │  produces printable characters, backspace, enter, escape, modifiers
        ▼
Shortcode state machine
        │  bounded candidate buffer, e.g. :skull:
        ▼
Shortcut repository
        │  in-memory [String: ShortcutValue] index loaded from SwiftData
        ▼
Replacement coordinator
        │  delete candidate via synthesized backspaces, then type emoji
        ▼
Focused application text field
```

The event tap is the runtime hot path. SwiftData is used for durable storage and loaded into an in-memory index at startup; the keystroke path must not perform database queries.

## Platform and implementation constraints

- Target macOS 14 or newer unless project constraints require another deployment target.
- Use Swift and SwiftUI.
- Use `NSStatusItem` with a SwiftUI-hosted menu or a SwiftUI `MenuBarExtra` where the deployment target supports the required behavior.
- Use `CGEventTapCreate` for global key observation and event suppression/reinjection.
- Do not use `IMKSwift`, `InputMethodKit`, or a custom keyboard/input-source bundle.
- Keep the app agent-like with `LSUIElement` enabled so it does not need a normal Dock presence.
- Keep the event callback minimal and hand state-machine work to a serialized application-owned context when practical.
- Never log raw typed text, shortcode candidates, or replacement content in production logs.

## Components

### App lifecycle

`AppDelegate` or an equivalent application coordinator should:

1. Create the SwiftData `ModelContainer`.
2. Construct the repository and load the enabled shortcut index.
3. Request or inspect Accessibility permission.
4. Start or stop the event tap when the app is enabled/disabled.
5. Register the menu-bar UI.
6. Stop the event tap and release resources on termination.

The event tap must not start until the user enables the feature and Accessibility permission is available.

### Global event tap

Observe `.keyDown` events with a listen-only or active tap as appropriate. Decode the event into a normalized input value containing:

- Printable text, if available.
- Key code for special keys.
- Command, Control, Option, and Shift flags.
- Whether the event is a repeat.
- The current timestamp if needed for timeout handling.

Ignore command-modified shortcuts, most control-modified events, key repeats, and non-printable navigation keys unless the state machine explicitly needs them. Preserve unrelated events unchanged.

Because an active event tap can suppress an event, replacement must be atomic from the user’s perspective: suppress only the final terminator event when a valid shortcode is recognized, then synthesize deletion events and emoji text. If the shortcode is invalid, pass the original terminator through unchanged.

### Shortcode state machine

The state machine starts capturing when a printable colon is typed. It maintains only a bounded candidate, for example:

- `inactive`
- `capturing(candidate: String)`
- `disabled(reason)`

Rules:

1. A colon starts a candidate with `:`.
2. While capturing, accept only a conservative shortcode character set: ASCII letters, digits, underscore, hyphen, plus, and colon as the closing delimiter.
3. Enforce a maximum candidate length, such as 64 Unicode scalars.
4. A closing colon performs an exact lookup using the normalized alias, such as `skull` or `:skull:`; choose one canonical storage format and use it everywhere.
5. On a valid match, replace the whole candidate.
6. On an invalid closing colon, keep normal typing behavior and reset safely.
7. Backspace removes the most recent captured scalar; if the candidate becomes empty, return to `inactive`.
8. Escape, Return, Tab, arrow keys, focus-changing behavior, unsupported modifiers, and timeout reset the candidate without affecting the user’s event.
9. A new colon while capturing starts a new candidate only if the prior candidate cannot be completed safely.
10. The buffer must reset after a short inactivity timeout, such as 2 seconds, to avoid carrying state across unrelated typing.

The state machine should be pure and independently testable. It should return a decision such as `passThrough`, `capture`, `replace(alias, emoji)`, or `resetAndPassThrough` rather than directly posting events.

### Replacement strategy

For a valid `:alias:` candidate:

1. Consume/suppress the final closing-colon event.
2. Synthesize one backspace/delete event per captured character, using the same deletion behavior that works in ordinary text fields.
3. Insert the emoji using a Unicode-safe text insertion mechanism, preferably a synthesized `CGEvent` keyboard event when the target supports it.
4. If direct Unicode event insertion is unreliable for a target app, use a carefully scoped pasteboard fallback: save the prior general pasteboard contents and metadata, write the emoji, paste, then restore the prior contents. This fallback must be opt-in or documented because it can interact with clipboard managers and cannot be perfectly atomic.

Start with the CGEvent path and document unsupported applications. Do not silently mutate the clipboard for every replacement.

Replacement must fail safely: if Accessibility permission disappears or event posting fails, stop interception, pass through future keystrokes, and surface the permission/error state in the menu-bar UI.

## Data model and persistence

### UserDefaults

Use `UserDefaults` only for small preferences:

- `isEnabled`
- `launchAtLogin`
- `autocompleteEnabled` if included in V1
- `maxSuggestions` if included in V1
- `replacementMode` or pasteboard-fallback preference
- `schemaVersion` for preference migrations

Wrap keys in a typed `PreferencesStore`; do not scatter string keys through views and services.

### SwiftData

Use SwiftData for user-created shortcuts.

Suggested model:

```swift
@Model
final class EmojiShortcut {
    @Attribute(.unique) var alias: String
    var emoji: String
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var isEnabled: Bool

    init(alias: String, emoji: String) {
        self.alias = alias
        self.emoji = emoji
        self.createdAt = .now
        self.updatedAt = .now
        self.isFavorite = false
        self.isEnabled = true
    }
}
```

Normalize aliases at the repository boundary. Reject empty aliases, aliases containing unsupported characters, duplicate aliases, and emoji values that are empty. The repository should expose an immutable runtime snapshot such as `[String: String]` and refresh it after mutations.

The app must not seed, infer, import, or auto-create custom shortcuts unless the user/builder explicitly chooses an add or import action. Opening the editor, typing into an unsaved form, using an emoji, or encountering an unknown shortcode must not create a persisted record.

Recommended repository responsibilities:

- CRUD operations on `EmojiShortcut`.
- Alias validation and normalization.
- Loading enabled shortcuts into the runtime index.
- Atomic index refresh after writes.

## Permissions and user experience

Global key observation and event posting require Accessibility permission. The app should:

- Detect whether it is trusted with `AXIsProcessTrustedWithOptions`.
- Explain why permission is needed in plain language.
- Offer a button that opens System Settings → Privacy & Security → Accessibility.
- Show a clear status indicator in the menu-bar menu.
- Avoid claiming the feature is active until the permission check succeeds.
- Provide a disable toggle that immediately removes the event tap.

The app should not request unrelated permissions. If launch-at-login is implemented, use the modern Service Management API and make it an explicit preference.

## Suggested project structure

```text
EmojiShortcuts/
├── App/
│   ├── EmojiShortcutsApp.swift
│   ├── AppDelegate.swift
│   └── AppCoordinator.swift
├── MenuBar/
│   ├── MenuBarView.swift
│   ├── ShortcutListView.swift
│   ├── ShortcutEditorView.swift
│   └── PermissionStatusView.swift
├── Keyboard/
│   ├── GlobalEventTap.swift
│   ├── KeyboardEvent.swift
│   ├── KeyboardEventNormalizer.swift
│   ├── ShortcodeStateMachine.swift
│   └── ReplacementCoordinator.swift
├── Persistence/
│   ├── EmojiShortcut.swift
│   ├── EmojiShortcutRepository.swift
│   ├── PreferencesStore.swift
│   └── ModelContainerFactory.swift
├── Support/
│   ├── AccessibilityPermission.swift
│   └── LoginItemManager.swift
└── EmojiShortcutsTests/
    ├── ShortcodeStateMachineTests.swift
    ├── EmojiShortcutRepositoryTests.swift
    ├── ReplacementCoordinatorTests.swift
    └── Integration/
```

## Testing plan

### Unit tests

Test the state machine with deterministic inputs for:

- `:skull:` valid replacement.
- Unknown aliases.
- Empty aliases and `::`.
- Maximum-length candidates.
- Backspace editing.
- Escape, Return, Tab, arrows, and modifier resets.
- Timeout reset.
- Unicode before and after a candidate.
- Repeated colons and malformed candidates.
- Disabled state and pass-through behavior.

Test repository behavior with an in-memory SwiftData container:

- Create, update, delete, and disable shortcuts.
- Alias normalization and duplicate rejection.
- Runtime index refresh.

### Integration and manual tests

Verify replacements in TextEdit, Notes, Safari text fields, Messages, Slack/Discord, and at least one Electron app. Verify behavior with:

- Accessibility permission granted and revoked.
- ABC input source active.
- Other keyboard layouts where printable-character decoding differs.
- Command/Control/Option shortcuts.
- Key repeats and very fast typing.
- Secure text fields and password fields, which should be excluded or treated conservatively.
- Multiple displays and app switching.
- Sleep/wake and event-tap interruption.
- App disable/quit while a candidate is being captured.

No test should require logging or storing the user’s surrounding text.

## Milestones

### Milestone 1 — Project shell

- Create the macOS app target and menu-bar-only lifecycle.
- Add a minimal SwiftUI menu with enabled state and quit action.
- Add `PreferencesStore` and in-memory SwiftData container.
- Confirm the app remains running after the menu closes.

### Milestone 2 — Persistence and shortcut management

- Add `EmojiShortcut` model and repository.
- Implement list, add, edit, delete, enable/disable, and validation UI.
- Require an explicit user/builder confirmation or Save action before inserting a new shortcut.
- Ensure Cancel, dismiss, validation failure, and abandoned editor states leave SwiftData unchanged.
- Load the runtime dictionary on startup and refresh it after writes.

### Milestone 3 — Pure typing engine

- Implement `KeyboardEvent` normalization interfaces.
- Implement and unit-test the colon-triggered state machine.
- Add bounded-buffer, timeout, modifier, and reset behavior.

### Milestone 4 — Event tap and safe replacement

- Implement Accessibility detection and setup guidance.
- Add the global event tap behind the enabled toggle.
- Implement backspace-plus-insertion replacement.
- Add failure handling that disables interception when posting fails.

### Milestone 5 — Hardening

- Test across representative macOS apps and keyboard layouts.
- Add launch-at-login if still in scope.
- Profile event handling and verify no database work occurs on the event callback path.
- Add diagnostics that contain only aggregate status, never typed content.

## Concurrency and performance constraints

- The CGEvent callback must return quickly and must not block on SwiftData, disk I/O, the main actor, or UI updates.
- Keep the runtime lookup immutable or synchronized for lock-free reads.
- Serialize state-machine mutations so events cannot interleave incorrectly.
- Bound candidate length, timeout state, and any pending replacement queue.
- Avoid retaining `CGEvent` objects longer than necessary.
- Stop and recreate the event tap cleanly after permission or run-loop failures.
- Measure startup time, event processing latency, and memory use with Instruments before release.

## Acceptance criteria

- The app launches as a menu-bar utility and remains active without a Dock window.
- With Accessibility permission and the feature enabled, typing `:skull:` in supported text fields produces `💀` and removes the shortcode.
- The normal ABC keyboard/input source remains selected and usable.
- Unknown or malformed shortcodes pass through without lost characters.
- Backspace, Escape, Return, Tab, navigation, modifiers, timeout, app switching, and disabling the app reset state safely.
- Users can manage custom shortcuts from the SwiftUI menu-bar UI.
- New custom shortcuts are persisted only after an explicit user/builder add or Save action; browsing, typing, replacement, and unknown aliases never add records.
- Preferences survive relaunch through `UserDefaults`.
- Custom shortcuts survive relaunch through SwiftData.
- The event path does not query SwiftData or write to disk per keystroke.
- The app clearly reports missing Accessibility permission and does not intercept input without it.
- No raw typed text or candidate buffers are written to logs or persisted.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| macOS Accessibility permission is denied or revoked | Show status, link to System Settings, and pass through all events when untrusted. |
| Event taps behave differently across apps | Start with common text fields, maintain an app compatibility matrix, and fail open. |
| Unicode insertion is unreliable through CGEvent | Use a tested insertion abstraction and document/optionally support a pasteboard fallback. |
| Deleting the candidate corrupts text in a target app | Keep replacement conservative, test representative apps, and never replace without an exact match. |
| Keyboard layouts do not expose characters uniformly | Normalize from event keyboard data where possible and test non-US layouts before broadening support. |
| Clipboard fallback surprises users | Make it opt-in or clearly documented, preserve and restore pasteboard data, and prefer direct event insertion. |
| State leaks between fields or applications | Reset on timeout, focus/app transitions when detectable, special keys, and permission changes. |
| SwiftData writes impact typing latency | Use an in-memory index and keep all database work off the typing path. |
| Global key monitoring creates privacy concerns | Explain the design, capture only bounded candidates, exclude secure fields where possible, and never persist raw input. |

## Definition of done

The implementation is ready for a first release when all acceptance criteria pass, the manual compatibility matrix has been exercised, Accessibility setup is understandable to a new user, the app remains responsive during sustained typing, and the test suite covers the pure state machine and persistence layers independently of the global event tap.
