import Combine
import Foundation
import IOKit.ps

/// Monitors the Mac's power source to detect battery vs AC power.
class BatteryMonitor: ObservableObject {

    // MARK: - Published State

    @Published var isOnBattery: Bool = false
    @Published var isCharging: Bool = false
    @Published var batteryLevel: Double = 1.0

    // MARK: - Private Properties

    private var runLoopSource: CFRunLoopSource?

    /// Weak reference used by the C callback to reach this instance.
    private static weak var current: BatteryMonitor?

    // MARK: - Monitoring Lifecycle

    /// Begins observing power-source changes via IOKit.
    func startMonitoring() {
        BatteryMonitor.current = self
        checkPowerSource()

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let source = IOPSNotificationCreateRunLoopSource(
            BatteryMonitor.powerSourceCallback,
            context
        )?.takeRetainedValue() else {
            return
        }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
    }

    /// Stops observing power-source changes.
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
        BatteryMonitor.current = nil
    }

    // MARK: - C Callback

    /// Static callback compatible with C function pointers.
    private static let powerSourceCallback: @convention(c) (UnsafeMutableRawPointer?) -> Void = { context in
        guard let context = context else { return }
        let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
        monitor.checkPowerSource()
    }

    // MARK: - Power Source Inspection

    /// Reads the current power source information and updates published properties.
    private func checkPowerSource() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any] else {
            return
        }

        // Determine the providing power source type
        let providingType = IOPSGetProvidingPowerSourceType(snapshot)?.takeRetainedValue() as String?
        let onBattery = (providingType == kIOPSBatteryPowerValue)

        var charging = false
        var level: Double = 1.0

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                level = Double(capacity) / Double(maxCapacity)
            }

            if let chargingState = info[kIOPSIsChargingKey] as? Bool {
                charging = chargingState
            }
        }

        // Publish updates on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.isOnBattery = onBattery
            self?.isCharging = charging
            self?.batteryLevel = level
        }
    }

    deinit {
        stopMonitoring()
    }
}
