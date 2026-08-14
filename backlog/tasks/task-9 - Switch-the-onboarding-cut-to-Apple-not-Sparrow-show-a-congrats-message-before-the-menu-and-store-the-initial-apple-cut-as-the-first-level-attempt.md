---
id: TASK-9
title: >-
  Switch the onboarding cut to Apple (not Sparrow), show a congrats message
  before the menu, and store the initial apple cut as the first level attempt
status: To Do
assignee: []
created_date: '2026-08-14 10:03'
labels:
  - feature
  - onboarding
  - gameplay
dependencies: []
references:
  - lib/screens/onboarding_screen.dart
  - assets/levels/levels.json
  - lib/services/attempt_store.dart
  - lib/models/attempt.dart
  - lib/screens/cut_screen.dart
  - test/onboarding_test.dart
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The first-run onboarding teaches the swipe by cutting level_01, which is titled "Sparrow" in assets/levels/levels.json even though its image (apple_1.png) is an apple. The cut the player draws is currently discarded: onboarding completes, the seen-flag is persisted, and the player is pushed straight to the menu.

1. Rebrand the onboarding level from Sparrow to Apple: rename level_01 title to "Apple" in levels.json, update the fallback Level in onboarding_screen.dart, and update any UI copy or tests referencing Sparrow.
2. After the onboarding cut completes, show a congrats message to the player (e.g. dialog) before navigating to the menu, so they know they are ready to play. Navigation happens only after the message is dismissed.
3. Persist the initial apple cut as the player's first level attempt: record an Attempt (mode: single, levelId: level_01) via AttemptStore, mirroring the single-player path in cut_screen.dart, before the handoff to the menu.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Onboarding refers to the level as Apple, not Sparrow: levels.json level_01 title, fallback level, and visible copy all say Apple; no Sparrow references remain.
- [ ] #2 After the onboarding cut is drawn, a congrats message is shown and the player reaches the menu only after it is dismissed.
- [ ] #3 The onboarding cut is stored as the first attempt for level_01 (single-player) and appears in the attempts history.
- [ ] #4 Onboarding already-seen behavior still works: the tutorial is not shown again on subsequent launches.
<!-- AC:END -->
