# Changelog

All notable changes to Mizunomi Timer are documented in this file.

The project uses semantic versioning.

## Unreleased

### Added

- Timer launch-mode setting that can automatically start the timer when the app launches.
- Reminder display targeting for either the main display or the active display at reminder time.
- Reminder panel appearance settings for size, desktop location, colours, alpha, and text styling.
- App icon inside the reminder panel.
- Reset Settings button in Settings.
- Bundled HTML user manual opened from the Help menu.
- Support section in the bundled user manual.
- Brief explanation of the word Mizunomi in the bundled user manual.

### Changed

- Made the default reminder panel smaller.
- Changed the default reminder colours for better readability in light and dark mode.
- Reduced the default reminder panel height to 90 pt and lowered the minimum custom height.
- Made the menu-bar icon slightly larger.
- Restored the custom menu-bar icon.
- Added exact 1x and 2x bitmap representations for the custom menu-bar icon.
- Lightened the custom menu-bar icon stroke.
- Reworked start time entry to use hour, minute, and AM/PM controls.
- Consolidated reminder text styling into the Reminder Panel settings group.
- Tightened Settings numeric field widths and refined reminder panel size labels.
- Disabled reminder display targeting when only one display is available, updating dynamically as displays change.
- Centre-aligned Settings row headings and contents.
- Reduced the Settings window height to remove extra bottom space.
- Removed the reminder panel shadow so no dark edge appears outside the border.
- Enlarged the water bottle inside the app icon.
- Matched the bundled user manual background to the default reminder panel colour.
- Switched the bundled user manual icon and favicon to generated PNG app icon assets.
- Removed the default supportive reminder sentence from the reminder panel.
- Clarified reminder interval and reminder duration validation for whole-number input.
- Renamed custom panels throughout the app and documentation as reminder panels.
- Reused the open Settings window instead of opening duplicates.

### Fixed

- Fixed Finder list-view icon rendering by generating exact-size iconset PNGs and building the `.icns` with `iconutil`.
- Removed app icon artwork padding so Finder list view no longer shows a light border around the icon.

## [0.1.0] - 2026-04-26

### Added

- Initial native macOS menu-bar app.
- Fixed-schedule water reminders based on start time and interval.
- Custom top-right reminder panel with OK, Skip, and automatic missed recording.
- In-memory consecutive skipped/missed interval tracking.
- Settings for start time, reminder interval, reminder duration, and launch at login.
- About window with app icon, version, and copyright.
- MIT licence and GitHub-ready project documentation.
