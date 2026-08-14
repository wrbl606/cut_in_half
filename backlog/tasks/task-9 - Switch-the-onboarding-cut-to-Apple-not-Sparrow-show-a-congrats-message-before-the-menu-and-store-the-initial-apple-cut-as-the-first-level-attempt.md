---
id: TASK-9
title: >-
  Switch the onboarding cut to Apple (not Sparrow), show a congrats message
  before the menu, and store the initial apple cut as the first level attempt
status: Done
assignee:
  - '@opencode'
created_date: '2026-08-14 10:03'
updated_date: '2026-08-14 10:16'
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
- [x] #1 Onboarding refers to the level as Apple, not Sparrow: levels.json level_01 title, fallback level, and visible copy all say Apple; no Sparrow references remain.
- [x] #2 After the onboarding cut is drawn, a congrats message is shown and the player reaches the menu only after it is dismissed.
- [x] #3 The onboarding cut is stored as the first attempt for level_01 (single-player) and appears in the attempts history.
- [x] #4 Onboarding already-seen behavior still works: the tutorial is not shown again on subsequent launches.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. levels.json: rename level_01 title Sparrow->Apple. 2. onboarding_screen.dart: update fallback Level to Apple/apple_1.png; fix doc/inline comments; store ImageMask from onCanvasReady; on first cut persist onboarding flag, record a single-player Attempt (level_01) via AttemptStore mirroring cut_screen (Splitter when mask ready, fallback otherwise), then show a non-dismissible congrats AlertDialog dismissed only via its button, and only then navigate to the menu. 3. test/onboarding_test.dart: mock SharedPreferences, assert Apple copy, assert congrats dialog appears before menu and menu only after dismissal, assert a single attempt for level_01 (Apple) is recorded, keep already-seen skip tests. 4. Run flutter analyze + flutter test.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implementation: (1) assets/levels/levels.json level_01 title Sparrow->Apple. (2) lib/screens/onboarding_screen.dart: added imports for Attempt/AttemptStore/Splitter; store ImageMask from onCanvasReady in _mask; _onCutsChanged passes cuts to _complete(cuts); _complete persists onboardingCompleted flag, then _recordAttempt (mirrors cut_screen single-player path: Splitter.split+buildResult when mask ready, fallback percents=[]/accuracy=0/objectiveMet=(cuts.length==requiredCuts) when mask null so the cut is still recorded), then _showCongratsDialog (non-dismissible AlertDialog, dismissed only via its 'Play' button), and only then navigates to the menu (onComplete path or pushReplacement). Fallback Level image fixed to assets/images/apple_1.png (existed; old 1047665181.png did not). (3) test/onboarding_test.dart: added SharedPreferences.setMockInitialValues setUp so AttemptStore works in tests; rewrote the consolidated onboarding widget test to assert Apple copy (no Sparrow), assert the congrats dialog ('Nice cut!'/'Play') appears before the menu and the menu appears only after dismissing it, assert a single single-player attempt for level_01 (Apple) is recorded in the attempt history, then assert menu handoff + onboardingCompleted persisted. Validation: flutter analyze clean; flutter test 57/57 pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Rebranded the onboarding level from Sparrow to Apple (levels.json level_01 title, the onboarding fallback Level title+image, and all onboarding doc/comment/test references). After the onboarding cut is drawn, the screen now records it as the player's first single-player Attempt for level_01 via AttemptStore (mirroring cut_screen.dart, using Splitter when the image mask is ready, with a defensive fallback that still records the cut), then shows a non-dismissible congrats AlertDialog ('Nice cut!') that is dismissed only via its 'Play' button; the menu is reached only after dismissal. Onboarding already-seen behavior is preserved (flag persisted; existing player/completed-progress skip tests unchanged). Verified with flutter analyze (clean) and flutter test (57/57 pass), including a consolidated onboarding widget test that asserts Apple copy, the dialog-then-menu ordering, and the recorded single-player attempt for level_01.
<!-- SECTION:FINAL_SUMMARY:END -->
