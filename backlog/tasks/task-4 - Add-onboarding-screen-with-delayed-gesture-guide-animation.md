---
id: TASK-4
title: Add onboarding screen with delayed gesture guide animation
status: Done
assignee: []
created_date: '2026-07-01 18:48'
updated_date: '2026-07-02 18:13'
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
- [x] #1 On first launch (or when progress is empty), the app shows the onboarding screen instead of the menu
- [x] #2 The onboarding screen uses level_01 (Sparrow) with the full cutting mechanic active
- [x] #3 After 2 seconds of no interaction, a gesture guide line animates diagonally from the bottom-left of the shape area to the top-right
- [x] #4 The guide animation uses an existing visual style consistent with the inactivity hint (half-transparent line with fingertip indicator) but with the new diagonal trajectory
- [x] #5 Once the player draws their first cut (or the level is completed), the onboarding experience ends and the app transitions to the main menu
- [x] #6 The onboarding screen is only shown once — subsequent launches go directly to the menu (tracked via persistent storage)
- [x] #7 All existing tests pass and flutter analyze is clean
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add onboardingCompleted flag to PlayerProgress (persisted, default false). 2. Add hintDelay + hintDiagonal params to CutCanvas (defaults preserve existing 15s horizontal hint). 3. Extend _CutPainter._drawHintOverlay to support a bottom-left -> top-right diagonal trajectory. 4. Create lib/screens/onboarding_screen.dart reusing level_01 with full CutCanvas cutting mechanic, 2s diagonal gesture guide, completes on first cut and sets the flag. 5. Make CutInHalfApp stateful: load progress on boot, route to OnboardingScreen when !onboardingCompleted && levels empty, else MenuScreen. 6. Update models_test + progress_back_button_test round-trips; add onboarding widget test. 7. flutter analyze + flutter test.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented: (1) Added onboardingCompleted flag to PlayerProgress (persisted, default false). (2) Added hintDelay + hintDiagonal params to CutCanvas (defaults preserve the existing 15s horizontal inactivity hint). (3) Extended _CutPainter._drawHintOverlay with a bottom-left -> top-right diagonal trajectory reusing the same half-transparent line + fingertip indicator style. (4) New lib/screens/onboarding_screen.dart reuses level_01 (Sparrow) with the full CutCanvas cutting mechanic, 2s diagonal gesture guide, and completes (persisting the flag) on the player's first committed cut (Sparrow needs exactly 1 cut, so first cut == level completion). (5) Made CutInHalfApp stateful: boots via storage, routes to OnboardingScreen when CutInHalfApp.shouldShowOnboarding(progress) (new player: !onboardingCompleted && levels.isEmpty), else MenuScreen; onComplete flips home to the menu. (6) Tests: added test/onboarding_test.dart (pure routing-decision tests + menu-routing widget tests + one consolidated onboarding widget test verifying level_01, 2s diagonal hint config, and first-cut -> menu handoff + persistence); updated models_test.dart round-trip and added onboardingCompleted cases; updated progress_back_button_test.dart to skip onboarding. flutter analyze clean; 51 tests pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a first-run onboarding screen (lib/screens/onboarding_screen.dart) that reuses level_01 (Sparrow) with the full CutCanvas cutting mechanic and a 2s-delayed diagonal gesture guide (bottom-left -> top-right) reusing the existing half-transparent line + fingertip hint style. CutCanvas gained hintDelay/hintDiagonal params (defaults preserve the prior 15s horizontal inactivity hint). PlayerProgress gained a persisted onboardingCompleted flag. CutInHalfApp is now stateful: it boots via storage and routes to the onboarding screen only for new players (CutInHalfApp.shouldShowOnboarding = !onboardingCompleted && levels.isEmpty), then hands off to the menu once the player draws their first cut (which, for Sparrow's single required cut, also completes the level). Verified: flutter analyze clean, 51 tests pass (new test/onboarding_test.dart; updated models_test.dart and progress_back_button_test.dart for the new persisted field and routing).
<!-- SECTION:FINAL_SUMMARY:END -->
