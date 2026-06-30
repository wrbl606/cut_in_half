---
id: TASK-2
title: >-
  Fix Ready button on web and implement cross-platform storage with
  shared_preferences
status: Done
assignee: []
created_date: '2026-06-29 13:02'
updated_date: '2026-06-30 18:45'
labels:
  - bug
  - web
dependencies: []
references:
  - lib/screens/cut_screen.dart
  - lib/services/storage_service.dart
  - lib/services/attempt_store.dart
  - pubspec.yaml
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
On the web build, pressing the Ready button on the Cut screen only plays the button press animation and never navigates to the ResultScreen.

Root cause: _finish() in lib/screens/cut_screen.dart calls StorageService.save() and AttemptStore.record(). Both services persist via dart:io File plus path_provider's getApplicationSupportDirectory(), neither of which is supported on Flutter Web. StorageService.load() swallows errors and returns fresh state, but StorageService.save() has no try/catch and throws an UnsupportedError on web. That exception escapes _finish() before Navigator.of(context).pushReplacement(...ResultScreen) runs, so the result screen never appears.

Solution: Replace the current JSON-file-based persistence (StorageService and AttemptStore using path_provider + dart:io) with shared_preferences (pub.dev/packages/shared_preferences), a key-value store that works on web, iOS, macOS, and Android. No migration of existing data is needed — the old solution will be fully replaced.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 On the web build, after making the required cuts and pressing Ready, the app advances to the ResultScreen showing the level result
- [x] #2 Player progress (per-level best scores, sound preference) persists across app restarts on all three platforms (web, iOS, macOS)
- [x] #3 Attempt history persists across app restarts on all three platforms, including multiplayer session grouping
- [x] #4 All existing tests pass with the new storage layer
- [x] #5 All screens that read/write storage (Menu, Settings, Progress, Cut, Multiplayer, Attempts) work identically on all three platforms
- [x] #6 The old StorageService and AttemptStore implementations referencing path_provider / dart:io are removed
- [x] #7 flutter analyze is clean and both web and mobile builds compile without errors
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add shared_preferences to pubspec.yaml and remove path_provider. 2. Rewrite StorageService and AttemptStore to use SharedPreferences (key-value), keeping public APIs so callers/tests are unaffected. 3. Remove path_provider mock in progress_back_button_test. 4. Run flutter pub get, flutter analyze, flutter test. 5. Verify web build compiles.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Replaced JSON-file persistence (path_provider + dart:io) in StorageService and AttemptStore with shared_preferences. Removed path_provider dep. Added try/catch to save() so web storage failures never block navigation. Added test/storage_service_test.dart covering round-trip, corrupt-data fallback, multiplayer session grouping, and clear. Removed stale path_provider mock from progress_back_button_test. flutter analyze clean, 49 tests pass, flutter build web succeeds.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced path_provider/dart:io JSON-file persistence in StorageService and AttemptStore with shared_preferences (pubspec updated: removed path_provider, added shared_preferences ^2.5.5). Public APIs preserved so all callers and existing fakes are unaffected. save()/saveAll() now swallow persistence errors, fixing the web Ready-button bug where the UnsupportedError escaped _finish() before navigation. Removed the stale path_provider MethodChannel mock from progress_back_button_test. New test/storage_service_test.dart covers round-trip persistence, corrupt-data fallback, multiplayer session grouping via recordSession, and clear. Verified: flutter analyze clean, 49/49 tests pass, flutter build web succeeds.
<!-- SECTION:FINAL_SUMMARY:END -->
