import CoreGraphics
import Foundation

final class GlobalEventTap: @unchecked Sendable {
    private let lock = NSLock()
    private let normalizer = KeyboardEventNormalizer()
    private var processor = EventTapProcessor()
    private var runtimeIndex: [String: String] = [:]
    private var wantsToRun = false
    private var tap: CFMachPort?
    private var runLoop: CFRunLoop?
    private var replacementHandler: (@Sendable (ReplacementRequest) -> Void)?

    func setReplacementHandler(_ replacementHandler: @escaping @Sendable (ReplacementRequest) -> Void) {
        lock.lock()
        self.replacementHandler = replacementHandler
        lock.unlock()
    }

    func updateRuntimeIndex(_ runtimeIndex: [String: String]) {
        lock.lock()
        self.runtimeIndex = runtimeIndex
        lock.unlock()
    }

    func start() {
        lock.lock()
        guard !wantsToRun else {
            lock.unlock()
            return
        }
        wantsToRun = true
        lock.unlock()

        Thread { [weak self] in
            self?.installAndRun()
        }.start()
    }

    func stop() {
        lock.lock()
        wantsToRun = false
        processor.reset()
        let runLoop = runLoop
        lock.unlock()
        if let runLoop {
            CFRunLoopStop(runLoop)
        }
    }

    private func installAndRun() {
        let eventMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.callback,
            userInfo: userInfo
        ) else {
            lock.lock()
            wantsToRun = false
            lock.unlock()
            return
        }

        let runLoop = CFRunLoopGetCurrent()
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        lock.lock()
        guard wantsToRun else {
            lock.unlock()
            return
        }
        self.tap = tap
        self.runLoop = runLoop
        lock.unlock()

        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopRun()
        CFRunLoopRemoveSource(runLoop, source, .commonModes)

        lock.lock()
        self.tap = nil
        self.runLoop = nil
        processor.reset()
        lock.unlock()
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> EventDisposition {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return .passThrough
        }
        guard type == .keyDown else { return .passThrough }

        lock.lock()
        defer { lock.unlock() }
        let disposition = processor.process(normalizer.normalize(event), runtimeIndex: runtimeIndex, isEnabled: wantsToRun)
        if let request = processor.takeReplacementRequest() {
            replacementHandler?(request)
        }
        return disposition
    }

    private static let callback: CGEventTapCallBack = { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
        guard let userInfo else { return nil }
        let eventTap = Unmanaged<GlobalEventTap>.fromOpaque(userInfo).takeUnretainedValue()
        return switch eventTap.handle(proxy: proxy, type: type, event: event) {
        case .passThrough:
            Unmanaged.passUnretained(event)
        case .suppress:
            nil
        }
    }
}
