---
id: TASK-3
title: Drop the settings button and related screens
status: Done
assignee: []
created_date: '2026-07-01 18:43'
updated_date: '2026-07-01 18:54'
labels:
  - refactor
dependencies: []
references:
  - lib/screens/settings_screen.dart
  - lib/screens/menu_screen.dart
  - test/settings_screen_test.dart
  - test/menu_sound_toggle_test.dart
  - docs/spec.md
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Remove the Settings button from the menu screen and delete the SettingsScreen widget and its tests, since the sound toggle now lives directly on the main menu.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The Settings button is no longer visible on the menu screen
- [x] #2 Navigating to SettingsScreen is no longer possible
- [x] #3 The sound toggle on the main menu remains fully functional
- [x] #4 All existing tests pass
- [x] #5 flutter analyze reports no errors
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Removed Settings button and settings_screen.dart import from menu_screen.dart; deleted lib/screens/settings_screen.dart and test/settings_screen_test.dart; updated menu_sound_toggle_test.dart to assert Settings is absent; updated docs/spec.md screen flow. Validation: flutter analyze clean, 43 tests pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Dropped the Settings screen: removed the menu button and import, deleted SettingsScreen widget and its tests, updated the menu sound toggle test to assert Settings is gone, and updated spec.md screen flow. Sound toggle remains on the menu. Verified with flutter analyze (no issues) and flutter test (43 passed).
<!-- SECTION:FINAL_SUMMARY:END -->
