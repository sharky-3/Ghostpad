import Carbon.HIToolbox
import CoreGraphics
import Foundation
import os

private nonisolated func inputBlockerCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    return Unmanaged<InputBlocker>.fromOpaque(userInfo).takeUnretainedValue().handle(type: type, event: event)
}

nonisolated final class InputBlocker: @unchecked Sendable {
    enum Mode: Sendable {
        case none
        case gestures
        case all
    }

    private struct State {
        var mode = Mode.none
        var anchor: CGPoint?
        var tap: CFMachPort?
        var runLoop: CFRunLoop?
    }

    private static let pointerTypes: [UInt32] = [1, 2, 3, 4, 5, 6, 7, 25, 26, 27]
    private static let gestureTypes: [UInt32] = [18, 19, 20, 22, 29, 30, 31, 32, 34]
    private static let keyTypes: [UInt32] = [10]

    private let state = OSAllocatedUnfairLock(uncheckedState: State())
    private let onEscape: @Sendable () -> Void

    init(onEscape: @escaping @Sendable () -> Void) {
        self.onEscape = onEscape
    }

    var isRunning: Bool {
        state.withLockUnchecked { $0.tap != nil }
    }

    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        let mask = (Self.pointerTypes + Self.gestureTypes + Self.keyTypes).reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << CGEventMask($1)) }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: inputBlockerCallback, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else { return false }
        nonisolated(unsafe) let unsafeSource = source
        nonisolated(unsafe) let unsafeTap = tap
        state.withLockUnchecked { $0.tap = tap }
        let thread = Thread { [weak self] in
            let runLoop = CFRunLoopGetCurrent()
            self?.state.withLockUnchecked { $0.runLoop = runLoop }
            CFRunLoopAddSource(runLoop, unsafeSource, .commonModes)
            CGEvent.tapEnable(tap: unsafeTap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "Ghostpad.InputBlocker"
        thread.qualityOfService = .userInteractive
        thread.start()
        return true
    }

    func stop() {
        setMode(.none)
        let (tap, runLoop) = state.withLockUnchecked { state in
            defer {
                state.tap = nil
                state.runLoop = nil
            }
            return (state.tap, state.runLoop)
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoop {
            CFRunLoopStop(runLoop)
        }
    }

    func setMode(_ mode: Mode) {
        let previous = state.withLockUnchecked { state in
            let previous = state.mode
            state.mode = mode
            if mode == .all && previous != .all {
                state.anchor = CGEvent(source: nil)?.location
            } else if mode != .all {
                state.anchor = nil
            }
            return previous
        }
        guard previous != mode, previous == .all || mode == .all else { return }
        CGAssociateMouseAndMouseCursorPosition(mode == .all ? 0 : 1)
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = state.withLockUnchecked({ $0.tap }) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return pass
        }
        let (mode, anchor) = state.withLockUnchecked { ($0.mode, $0.anchor) }
        let raw = type.rawValue
        switch mode {
        case .none:
            return pass
        case .gestures:
            return Self.gestureTypes.contains(raw) ? nil : pass
        case .all:
            if type == .keyDown {
                guard event.getIntegerValueField(.eventSourceUserData) != KeySender.marker, event.getIntegerValueField(.keyboardEventKeycode) == Int64(kVK_Escape) else { return pass }
                onEscape()
                return nil
            }
            if [5, 6, 7, 27].contains(raw), let anchor, hypot(event.location.x - anchor.x, event.location.y - anchor.y) > 0.5 {
                CGWarpMouseCursorPosition(anchor)
            }
            return nil
        }
    }
}
