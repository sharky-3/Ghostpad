import AppKit
import OSLog

private nonisolated func handleContactFrame(device: MTDeviceRef?, touches: UnsafeMutablePointer<MTTouch>?, count: Int32, timestamp: Double, frame: Int32) {
    var points: [TouchPoint] = []
    if let touches, count > 0 {
        points.reserveCapacity(Int(count))
        for touch in UnsafeBufferPointer(start: touches, count: Int(count)) {
            let normalized = touch.normalized
            points.append(TouchPoint(id: Int(touch.pathIndex), state: TouchState(raw: touch.state), position: CGPoint(x: Double(normalized.position.x), y: 1 - Double(normalized.position.y)), velocity: CGVector(dx: Double(normalized.velocity.x), dy: -Double(normalized.velocity.y)), size: Double(touch.zTotal), majorAxis: Double(touch.majorAxis), minorAxis: Double(touch.minorAxis)))
        }
    }
    let touchFrame = TouchFrame(touches: points, timestamp: timestamp, number: Int(frame))
    DispatchQueue.main.async {
        MainActor.assumeIsolated {
            MultitouchMonitor.active?.receive(touchFrame)
        }
    }
}

final class MultitouchMonitor {
    fileprivate static weak var active: MultitouchMonitor?

    var onFrame: ((TouchFrame) -> Void)?
    private(set) var geometry = TrackpadGeometry.fallback
    private(set) var isRunning = false

    private let logger = Logger(subsystem: "app.ghostpad", category: "multitouch")
    private var deviceList: CFMutableArray?
    private var devices: [MTDeviceRef] = []
    private var wakeObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    func start() {
        guard !isRunning else { return }
        MultitouchMonitor.active = self
        let list = MTDeviceCreateList()
        deviceList = list
        let all = (0..<CFArrayGetCount(list)).compactMap { index in
            CFArrayGetValueAtIndex(list, index).map { UnsafeMutableRawPointer(mutating: $0) }
        }
        let builtIn = all.filter { MTDeviceIsBuiltIn($0) }
        devices = builtIn.isEmpty ? all : builtIn
        guard let primary = devices.first else {
            logger.error("No multitouch devices found")
            return
        }
        geometry = readGeometry(of: primary)
        for device in devices {
            MTRegisterContactFrameCallback(device, handleContactFrame)
            MTDeviceStart(device, 0)
        }
        isRunning = true
        observePower()
        logger.info("Started \(self.devices.count) of \(all.count) device(s), surface \(self.geometry.width, format: .fixed(precision: 1)) × \(self.geometry.height, format: .fixed(precision: 1)) mm")
    }

    func stop() {
        guard isRunning else { return }
        for device in devices {
            MTUnregisterContactFrameCallback(device, handleContactFrame)
            MTDeviceStop(device)
        }
        devices = []
        deviceList = nil
        isRunning = false
        logger.info("Stopped")
    }

    func restart() {
        stop()
        start()
    }

    fileprivate func receive(_ frame: TouchFrame) {
        onFrame?(frame)
    }

    private func readGeometry(of device: MTDeviceRef) -> TrackpadGeometry {
        var width: Int32 = 0
        var height: Int32 = 0
        let status = MTDeviceGetSensorSurfaceDimensions(device, &width, &height)
        guard status == noErr, width > 0, height > 0 else { return .fallback }
        return TrackpadGeometry(width: Double(width) / 100, height: Double(height) / 100)
    }

    private func observePower() {
        guard wakeObserver == nil else { return }
        let center = NSWorkspace.shared.notificationCenter
        sleepObserver = center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
        wakeObserver = center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                MainActor.assumeIsolated { self?.start() }
            }
        }
    }
}
