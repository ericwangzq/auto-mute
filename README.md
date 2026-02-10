# AutoMute (macOS)

AutoMute pauses background music whenever the microphone is in use, and resumes playback when the mic is released. It runs as a lightweight menu bar app.

## Why
Voice input and calls often push Bluetooth headsets into a low-latency mode, which makes music louder and distorted. AutoMute prevents that by pausing playback while the mic is active.

## Features
- Mic-activity based trigger (works with any input method or app)
- Menu bar app with enable/disable toggle
- Start at login
- Multiple media control backends

## How It Works
- Detects microphone activity via CoreAudio device state.
- Sends Play/Pause to the system using a selectable backend.

## Media Control Backends
- `mediaRemote` (recommended): private MediaRemote API, most reliable.
- `hid`: IOHIDPostEvent (public but deprecated, may be blocked on some systems).
- `mediaKey`: NSEvent systemDefined (often blocked on newer macOS).
- `nowPlayingUI`: clicks Control Center UI (not recommended).

## Build
```bash
scripts/build_app.sh
```

## Build DMG
```bash
scripts/build_dmg.sh
```

## Configuration
Config file:
`~/Library/Application Support/AutoMute/config.json`

Common options:
- `triggerMode`: `microphone` (default), `ax`, `hybrid`.
- `mediaControlMode`: `mediaRemote` (default), `hid`, `mediaKey`, `nowPlayingUI`.
- `requireAudioRunning`: only pause if output device is running.
- `debugLog`: verbose logging.

## App Store
This project uses a private API (`MediaRemote`) for reliable media control. It is not App Store safe.

## License
MIT
