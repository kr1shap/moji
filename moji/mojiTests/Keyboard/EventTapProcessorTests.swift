import Testing
@testable import moji

struct EventTapProcessorTests {
    @Test func repeatGeneratedAndModifiedEventsPassThrough() {
        var processor = EventTapProcessor()
        let base = NormalizedKeyboardEvent(input: .character(":"), isRepeat: false, isMojiGenerated: false, hasUnsupportedModifiers: false)

        #expect(processor.process(base, runtimeIndex: [:], isEnabled: true) == .passThrough)
        #expect(processor.process(NormalizedKeyboardEvent(input: .character("s"), isRepeat: true, isMojiGenerated: false, hasUnsupportedModifiers: false), runtimeIndex: [:], isEnabled: true) == .passThrough)
        #expect(processor.process(NormalizedKeyboardEvent(input: .character("s"), isRepeat: false, isMojiGenerated: true, hasUnsupportedModifiers: false), runtimeIndex: [:], isEnabled: true) == .passThrough)
        #expect(processor.process(NormalizedKeyboardEvent(input: .character("s"), isRepeat: false, isMojiGenerated: false, hasUnsupportedModifiers: true), runtimeIndex: [:], isEnabled: true) == .passThrough)
    }

    @Test func validMatchSuppressesOnlyTheClosingColonAndPublishesAReplacementRequest() {
        var processor = EventTapProcessor()
        for character in ":skull" {
            let event = NormalizedKeyboardEvent(input: .character(character), isRepeat: false, isMojiGenerated: false, hasUnsupportedModifiers: false)
            #expect(processor.process(event, runtimeIndex: ["skull": "💀"], isEnabled: true) == .passThrough)
        }

        let closingColon = NormalizedKeyboardEvent(input: .character(":"), isRepeat: false, isMojiGenerated: false, hasUnsupportedModifiers: false)
        #expect(processor.process(closingColon, runtimeIndex: ["skull": "💀"], isEnabled: true) == .suppress)
        #expect(processor.takeReplacementRequest() == ReplacementRequest(emoji: "💀", deletionCount: 6))
    }

    @Test func disabledStateResetsTheCandidate() {
        var processor = EventTapProcessor()
        let openingColon = NormalizedKeyboardEvent(input: .character(":"), isRepeat: false, isMojiGenerated: false, hasUnsupportedModifiers: false)
        _ = processor.process(openingColon, runtimeIndex: [:], isEnabled: true)

        #expect(processor.process(openingColon, runtimeIndex: ["skull": "💀"], isEnabled: false) == .passThrough)
    }
}
