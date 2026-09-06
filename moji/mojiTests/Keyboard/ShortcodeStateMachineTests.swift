import Testing
@testable import moji

struct ShortcodeStateMachineTests {
    @Test func validShortcodeReturnsEmojiAndVisiblePrefixDeletionCount() {
        var machine = ShortcodeStateMachine()

        send(":skull", to: &machine)
        let decision = machine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: true)

        #expect(decision == .replace(emoji: "💀", deletionCount: 6))
    }

    @Test func unknownShortcodePassesClosingColonThrough() {
        var machine = ShortcodeStateMachine()

        send(":unknown", to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: [:], isEnabled: true) == .resetAndPassThrough)
    }

    @Test func emptyShortcodeStartsCapturingFromTheSecondColon() {
        var machine = ShortcodeStateMachine()

        #expect(machine.process(.character(":"), runtimeIndex: [:], isEnabled: true) == .passThrough)
        #expect(machine.process(.character(":"), runtimeIndex: [:], isEnabled: true) == .passThrough)
        send("skull", to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: true) == .replace(emoji: "💀", deletionCount: 6))
    }

    @Test func uppercaseAliasMatchesLowercaseRuntimeIndex() {
        var machine = ShortcodeStateMachine()

        send(":SKULL", to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: true) == .replace(emoji: "💀", deletionCount: 6))
    }

    @Test func malformedInputResetsWithoutSuppressingTheCharacter() {
        var machine = ShortcodeStateMachine()

        send(":skull", to: &machine)

        #expect(machine.process(.character(" "), runtimeIndex: ["skull": "💀"], isEnabled: true) == .resetAndPassThrough)
    }

    @Test func maximumLengthAliasCanBeReplaced() {
        let alias = String(repeating: "a", count: 32)
        var machine = ShortcodeStateMachine()

        send(":" + alias, to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: [alias: "🅰️"], isEnabled: true) == .replace(emoji: "🅰️", deletionCount: 33))
    }

    @Test func aliasLongerThanMaximumResetsAndPassesThrough() {
        var machine = ShortcodeStateMachine()

        send(":" + String(repeating: "a", count: 32), to: &machine)

        #expect(machine.process(.character("a"), runtimeIndex: [:], isEnabled: true) == .resetAndPassThrough)
    }

    @Test func backspaceEditsTheCapturedAlias() {
        var machine = ShortcodeStateMachine()

        send(":sku", to: &machine)
        #expect(machine.process(.backspace, runtimeIndex: [:], isEnabled: true) == .passThrough)
        send("ull", to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: true) == .replace(emoji: "💀", deletionCount: 6))
    }

    @Test func resetKeysTimeoutAndDisabledStatePassThrough() {
        let resetInputs: [KeyboardInput] = [.escape, .returnKey, .tab, .navigation, .unsupportedModifiers, .timeout]

        for input in resetInputs {
            var machine = ShortcodeStateMachine()
            send(":skull", to: &machine)
            #expect(machine.process(input, runtimeIndex: ["skull": "💀"], isEnabled: true) == .resetAndPassThrough)
        }

        var disabledMachine = ShortcodeStateMachine()
        send(":skull", to: &disabledMachine)
        #expect(disabledMachine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: false) == .resetAndPassThrough)
    }

    @Test func unicodeAdjacentToShortcodeDoesNotPreventReplacement() {
        var machine = ShortcodeStateMachine()

        #expect(machine.process(.character("🎉"), runtimeIndex: ["skull": "💀"], isEnabled: true) == .passThrough)
        send(":skull", to: &machine)

        #expect(machine.process(.character(":"), runtimeIndex: ["skull": "💀"], isEnabled: true) == .replace(emoji: "💀", deletionCount: 6))
    }

    private func send(_ text: String, to machine: inout ShortcodeStateMachine) {
        for character in text {
            _ = machine.process(.character(character), runtimeIndex: [:], isEnabled: true)
        }
    }
}
