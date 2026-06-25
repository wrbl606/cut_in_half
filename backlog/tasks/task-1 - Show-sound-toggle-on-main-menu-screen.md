---
id: TASK-1
title: Show sound toggle on main menu screen
status: To Do
assignee: []
created_date: '2026-06-25 18:07'
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
- [ ] #1 A sound on/off control is visible on the main menu screen without opening any other screen
- [ ] #2 Toggling the control on the menu updates the enabled/disabled state immediately
- [ ] #3 The sound preference persists across app restarts
- [ ] #4 The Settings screen still opens without errors (or is removed intentionally with rationale)
<!-- AC:END -->
