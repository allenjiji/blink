# Blink

A tiny menu bar app that reminds you to look away from the screen every X
minutes, for X seconds (the 20-20-20 rule). Both values default to 20 and
are configurable from the menu bar icon's Preferences.

It's meeting-aware: if a reminder is due while your mic or camera is active
(Zoom, Meet, Teams, FaceTime, etc.), it holds off instead of interrupting —
then shows up right after the meeting ends.

Pure Swift + AppKit via Swift Package Manager — no Xcode project needed.

<img width="3600" height="2336" alt="image" src="https://github.com/user-attachments/assets/a6b87461-da2c-41c8-b744-c90fedfed435" />

## Story
https://x.com/iamallenjiji/status/2115518777265893383?a=LnnU9m8UHcrlh9LeuAA&s=20

## Install

Download `Blink.dmg` from the [latest release](https://github.com/allenjiji/blink/releases/latest),
open it, and drag Blink into Applications. Launch it from there — macOS will
warn it's from an unidentified developer the first time (it's ad-hoc signed,
not notarized); right-click → Open to bypass that once.

## Develop

```
swift build
swift run Blink --selfcheck  # assert-based self-check (no Xcode => no XCTest on this machine)
swift run                  # launches the menu bar icon; no Dock icon appears
```

Note: "Launch at Login" is disabled/unavailable when run this way — it only
works from the packaged app below.

## Build from source

```
Scripts/build_app.sh        # produces dist/Blink.app
Scripts/build_app.sh --dmg  # also produces dist/Blink.dmg
```

Move the app to `/Applications` before using
"Launch at Login" from the menu — `SMAppService` needs a stable bundle path
to register a login item.

Because the app is only ad-hoc signed (no paid Developer ID), the signature
changes on every rebuild. You may need to re-enable "Launch at Login" after
rebuilding during development.

## Quit

Click the eye icon in the menu bar → "Quit Blink".
