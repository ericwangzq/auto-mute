import CoreAudio
import Foundation

final class MicActivityMonitor {
    private var inputDeviceID = AudioDeviceID(0)
    private var isRunning = false
    private var defaultInputListenerInstalled = false
    private var runningListenerInstalled = false

    var onStart: (() -> Void)?
    var onEnd: (() -> Void)?

    func start() {
        registerDefaultInputListener()
        attachToDefaultInputDevice()
    }

    func stop() {
        removeRunningListener()
        removeDefaultInputListener()
    }

    private func registerDefaultInputListener() {
        guard !defaultInputListenerInstalled else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            defaultInputListener,
            Unmanaged.passUnretained(self).toOpaque()
        )

        if status == noErr {
            defaultInputListenerInstalled = true
        } else {
            Log.info("MicActivity: failed to listen for default input changes: \(status)")
        }
    }

    private func removeDefaultInputListener() {
        guard defaultInputListenerInstalled else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            defaultInputListener,
            Unmanaged.passUnretained(self).toOpaque()
        )
        defaultInputListenerInstalled = false
    }

    private func attachToDefaultInputDevice() {
        let newDeviceID = getDefaultInputDeviceID()
        if newDeviceID == 0 {
            Log.info("MicActivity: no default input device")
            return
        }
        if newDeviceID == inputDeviceID {
            updateRunningState()
            return
        }
        removeRunningListener()
        inputDeviceID = newDeviceID
        Log.info("MicActivity: default input device set [id=\(newDeviceID)]")
        registerRunningListener()
        updateRunningState()
    }

    private func getDefaultInputDeviceID() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        if status != noErr {
            Log.info("MicActivity: failed to get default input device: \(status)")
            return 0
        }
        return deviceID
    }

    private func registerRunningListener() {
        guard inputDeviceID != 0, !runningListenerInstalled else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectAddPropertyListener(
            inputDeviceID,
            &address,
            runningListener,
            Unmanaged.passUnretained(self).toOpaque()
        )

        if status == noErr {
            runningListenerInstalled = true
        } else {
            Log.info("MicActivity: failed to listen for running state: \(status)")
        }
    }

    private func removeRunningListener() {
        guard runningListenerInstalled, inputDeviceID != 0 else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectRemovePropertyListener(
            inputDeviceID,
            &address,
            runningListener,
            Unmanaged.passUnretained(self).toOpaque()
        )
        runningListenerInstalled = false
    }

    fileprivate func handleDefaultInputChanged() {
        Log.info("MicActivity: default input device changed")
        DispatchQueue.main.async { [weak self] in
            self?.attachToDefaultInputDevice()
        }
    }

    fileprivate func handleRunningStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateRunningState()
        }
    }

    private func updateRunningState() {
        guard inputDeviceID != 0 else { return }
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            inputDeviceID,
            &address,
            0,
            nil,
            &size,
            &running
        )
        if status != noErr {
            Log.info("MicActivity: failed to get running state: \(status)")
            return
        }

        let nowRunning = running != 0
        if nowRunning == isRunning { return }
        isRunning = nowRunning
        Log.info("MicActivity: running=\(nowRunning ? "true" : "false") deviceId=\(inputDeviceID)")
        if nowRunning {
            onStart?()
        } else {
            onEnd?()
        }
    }

}

private func defaultInputListener(
    _: AudioObjectID,
    _: UInt32,
    _: UnsafePointer<AudioObjectPropertyAddress>,
    _ clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData else { return noErr }
    let monitor = Unmanaged<MicActivityMonitor>.fromOpaque(clientData).takeUnretainedValue()
    monitor.handleDefaultInputChanged()
    return noErr
}

private func runningListener(
    _: AudioObjectID,
    _: UInt32,
    _: UnsafePointer<AudioObjectPropertyAddress>,
    _ clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData else { return noErr }
    let monitor = Unmanaged<MicActivityMonitor>.fromOpaque(clientData).takeUnretainedValue()
    monitor.handleRunningStateChanged()
    return noErr
}
