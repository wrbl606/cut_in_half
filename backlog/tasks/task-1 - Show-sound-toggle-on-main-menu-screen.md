---
id: TASK-1
title: Show sound toggle on main menu screen
status: Done
assignee:
  - '@opencode'
created_date: '2026-06-25 18:07'
updated_date: '2026-06-29 08:16'
labels: []
dependencies: []
references:
  - lib/screens/menu_screen.dart
  - lib/screens/settings_screen.dart
  - lib/services/storage_service.dart
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Make the sound on/off control directly visible on the main menu screen so players can mute or unmute without navigating into the separate Settings screen. Currently the toggle lives only in SettingsScreen (lib/screens/settings_screen.dart) as local state and is not persisted, so it resets on every app launch.\n\nMove (or mirror) the control onto the menu screen (lib/screens/menu_screen.dart), e.g. as a small icon/switch in the top corner of the SafeArea. Persist the setting so the chosen state survives restarts (reuse the JSON storage in lib/services/storage_service.dart or shared prefs; expand PlayerProgress if needed). Keep the Settings screen working or remove it if the menu control fully replaces it (prefer keeping the menu control as the single source of truth).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A sound on/off control is visible on the main menu screen without opening any other screen
- [x] #2 Toggling the control on the menu updates the enabled/disabled state immediately
- [x] #3 The sound preference persists across app restarts
- [x] #4 The Settings screen still opens without errors (or is removed intentionally with rationale)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add soundEnabled field to PlayerProgress (JSON key sound_enabled, default true). 2. Add a sound icon toggle in the top-right of MenuScreen SafeArea; load preference from StorageService on init, save on toggle. 3. Pass storage into SettingsScreen so it reads/writes the same persisted soundEnabled (single source of truth); refresh menu state when returning from Settings. 4. Update existing PlayerProgress JSON round-trip test and add menu sound toggle widget tests.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented: added soundEnabled (JSON sound_enabled, default true) to PlayerProgress for persistence via existing StorageService. Added an IconButton (volume_up/volume_off) in the top-right of the MenuScreen SafeArea that loads the preference on init and saves on toggle. SettingsScreen now takes storage and reads/writes the same persisted preference (single source of truth); menu refreshes its state when returning from Settings. Updated existing PlayerProgress round-trip test for the new field and added widget tests for the menu toggle, persistence, and Settings sync. flutter analyze clean; 45 tests pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a persisted sound on/off toggle to the main menu. Expanded PlayerProgress with a soundEnabled field (JSON key sound_enabled, default true) saved via the existing StorageService JSON store. MenuScreen now shows an IconButton (volume_up/volume_off) in the top-right of the SafeArea that loads the preference on init and saves on toggle. SettingsScreen was kept and rewired to read/write the same persisted preference (single source of truth), with the menu refreshing its state on return. Updated the existing PlayerProgress round-trip test and added widget tests covering menu toggle visibility, immediate state updates, persistence, persisted-state load, and Settings sync. Verified: flutter analyze clean, 45 tests pass.
<!-- SECTION:FINAL_SUMMARY:END -->
