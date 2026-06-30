---
id: TASK-2
title: >-
  Fix Ready button on web and implement cross-platform storage with
  shared_preferences
status: To Do
assignee: []
created_date: '2026-06-29 13:02'
updated_date: '2026-06-30 18:32'
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
- [ ] #1 On the web build, after making the required cuts and pressing Ready, the app advances to the ResultScreen showing the level result
- [ ] #2 Player progress (per-level best scores, sound preference) persists across app restarts on all three platforms (web, iOS, macOS)
- [ ] #3 Attempt history persists across app restarts on all three platforms, including multiplayer session grouping
- [ ] #4 All existing tests pass with the new storage layer
- [ ] #5 All screens that read/write storage (Menu, Settings, Progress, Cut, Multiplayer, Attempts) work identically on all three platforms
- [ ] #6 The old StorageService and AttemptStore implementations referencing path_provider / dart:io are removed
- [ ] #7 flutter analyze is clean and both web and mobile builds compile without errors
<!-- AC:END -->
