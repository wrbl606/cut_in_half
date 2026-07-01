---
id: TASK-4
title: Add onboarding screen with delayed gesture guide animation
status: To Do
assignee: []
created_date: '2026-07-01 18:48'
updated_date: '2026-07-01 18:48'
labels:
  - feature
  - onboarding
dependencies: []
references:
  - lib/screens/menu_screen.dart
  - lib/screens/cut_screen.dart
  - lib/widgets/cut_canvas.dart
  - lib/models/level.dart
  - lib/models/player_progress.dart
  - lib/services/storage_service.dart
  - lib/app.dart
  - assets/levels/levels.json
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add an onboarding screen that serves as the first experience for new players. The screen reuses the first single-player level (level_01 / Sparrow) with the full cutting mechanic, but with a key instructional difference: after a 2-second delay, an animated gesture guide sweeps diagonally from bottom-left to top-right across the shape to teach the core swipe-to-cut action. This replaces or complements the existing 15-second inactivity hint with a deliberate, always-triggered tutorial animation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 On first launch (or when progress is empty), the app shows the onboarding screen instead of the menu
- [ ] #2 The onboarding screen uses level_01 (Sparrow) with the full cutting mechanic active
- [ ] #3 After 2 seconds of no interaction, a gesture guide line animates diagonally from the bottom-left of the shape area to the top-right
- [ ] #4 The guide animation uses an existing visual style consistent with the inactivity hint (half-transparent line with fingertip indicator) but with the new diagonal trajectory
- [ ] #5 Once the player draws their first cut (or the level is completed), the onboarding experience ends and the app transitions to the main menu
- [ ] #6 The onboarding screen is only shown once — subsequent launches go directly to the menu (tracked via persistent storage)
- [ ] #7 All existing tests pass and flutter analyze is clean
<!-- AC:END -->
