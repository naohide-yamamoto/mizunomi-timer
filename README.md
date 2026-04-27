# Mizunomi Timer

Mizunomi Timer is a small macOS menu-bar utility that reminds you to drink a cup of water at a designated interval.

It is intentionally low-profile: there is no Dock icon, no main window, and no persistent drinking history. The app shows a menu-bar icon, a settings window, an about window, and a quiet custom reminder panel in the top-right corner of the desktop.

## Requirements

- Apple Silicon Mac
- macOS Tahoe 26.4
- Xcode 26.4.1 or newer
- Swift 6.3.1 or newer

No backward compatibility is planned for earlier macOS releases.

## Behaviour

- The timer starts automatically when the app launches by default.
- A launch-time timer start and a custom start time are mutually exclusive settings.
- A custom start time can be set in Settings using hour, minute, and AM/PM controls.
- If the custom start time has already passed today, the app waits until that time tomorrow.
- Reminder timing is fixed from the start time. For example, with an 8:00 am start and a 60-minute interval, reminders appear at 9:00 am, 10:00 am, 11:00 am, and so on.
- Clicking OK records that water was had for that interval.
- Clicking Skip records that the interval was skipped.
- Letting the panel time out records that the interval was missed.
- If one or more consecutive intervals were skipped or missed, the next reminder reports how many minutes have passed without water.
- Pause preserves the original schedule and skips reminder display until Resume.
- Stop clears the running timer state and returns the menu item to Start.
- Interval history is kept in memory only and is reset when the app quits.

## Menu

The menu-bar menu contains:

- Start, replaced by `Started at 2:30 pm` after the timer starts
- Pause, replaced by Resume while paused
- Stop
- Settings
- Help
- About Mizunomi Timer
- Quit

## Settings

Settings include:

- Start time
- Start timer at app launch
- Reminder interval, in minutes
- Reminder duration, in minutes
- Reminder panel width, height, display target, desktop location, fill colour, border colour, and text styling
- Launch at login
- Reset Settings

The default reminder interval is 60 minutes. The default reminder duration is 10 minutes. Both fields accept whole numbers only, and reminder duration must be shorter than the reminder interval. The default reminder display target is the main display.

## Help

The Help menu item opens the bundled user manual in your default web browser.

## Build

Build the app bundle with:

```sh
bash scripts/build-app.sh
```

The built app is written to:

```text
build/Mizunomi Timer.app
```

For a debug build:

```sh
CONFIGURATION=debug bash scripts/build-app.sh
```

## Project Details

- Display name: Mizunomi Timer
- Package/repo name: `mizunomi-timer`
- Bundle ID: `com.naohideyamamoto.mizunomitimer`
- Version: `0.1.0`
- Licence: MIT

## Privacy

Mizunomi Timer does not send data anywhere. Settings are stored locally with UserDefaults. Drinking interval history is not persisted and is reset when the app quits.
