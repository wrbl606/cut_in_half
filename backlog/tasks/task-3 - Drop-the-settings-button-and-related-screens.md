---
id: TASK-3
title: Drop the settings button and related screens
status: To Do
assignee: []
created_date: '2026-07-01 18:43'
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
- [ ] #1 The Settings button is no longer visible on the menu screen
- [ ] #2 Navigating to SettingsScreen is no longer possible
- [ ] #3 The sound toggle on the main menu remains fully functional
- [ ] #4 All existing tests pass
- [ ] #5 flutter analyze reports no errors
<!-- AC:END -->
