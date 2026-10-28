import CoreAudio
import CoreMediaIO

/// Detects an active meeting by checking whether the mic or camera hardware
/// is in use system-wide. This reads device state (not audio/video content),
/// so it doesn't require microphone/camera permission.
enum MeetingDetector {
    static func isInMeeting() -> Bool {
        isDefaultInputRunning() || isAnyCameraRunning()
    }

    private static func isDefaultInputRunning() -> Bool {
        var deviceID = AudioDeviceID(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr else {
            return false
        }

        var isRunning: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isRunning) == noErr else {
            return false
        }
        return isRunning != 0
    }

    private static func isAnyCameraRunning() -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, &dataSize) == noErr,
              dataSize > 0 else {
            return false
        }

        let count = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0
        guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, dataSize, &dataUsed, &devices) == noErr else {
            return false
        }

        for device in devices {
            var isRunning: UInt32 = 0
            var runningAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
            let size = UInt32(MemoryLayout<UInt32>.size)
            var used: UInt32 = 0
            if CMIOObjectGetPropertyData(device, &runningAddress, 0, nil, size, &used, &isRunning) == noErr, isRunning != 0 {
                return true
            }
        }
        return false
    }
}
