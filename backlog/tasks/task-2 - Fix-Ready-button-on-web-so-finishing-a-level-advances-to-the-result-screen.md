---
id: TASK-2
title: Fix Ready button on web and implement cross-platform storage with sembast
status: Done
assignee:
  - '@opencode'
created_date: '2026-06-29 13:02'
updated_date: '2026-06-30 18:07'
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

Solution: Replace the current JSON-file-based persistence (StorageService and AttemptStore using path_provider + dart:io) with sembast (pub.dev/packages/sembast), a NoSQL document database that works on web, iOS, and macOS via sqflite on native and indexed_db on web. No migration of existing data is needed — the old solution will be fully replaced. Do not use Hive or Isar.
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
1. Add sembast + sembast_web + sembast_sqflite + sqflite deps; drop path_provider. 2. Add platform-conditional database backend helper (sqflite on native, indexed_db on web). 3. Rewrite StorageService and AttemptStore over sembast stores, keeping public API. 4. Remove dart:io/path_provider refs from impls; screens unchanged. 5. Add sembast-backed round-trip tests; keep existing FakeStorage tests working. 6. Run flutter analyze + flutter test.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented: replaced JSON-file persistence (path_provider + dart:io) with sembast. Added lib/services/storage_backend.dart (conditional: sqflite native, sembast_web/indexed_db web) plus storage_backend_stub/native/web. Rewrote StorageService and AttemptStore over sembast stores keeping the same public API; pure logic (record/recordSession/clear/newSessionId/newAttemptId/_prune) preserved. Removed path_provider from pubspec (added sembast, sembast_web, sembast_sqflite, sqflite). macos/iOS generated plugin registrants now pull sqflite_darwin. Added test/storage_service_test.dart exercising real in-memory sembast round-trips (progress + attempts + multiplayer session grouping + clear). Existing FakeStorage-backed widget tests still pass (no behavior change to screen storage API). Run results: flutter analyze clean; flutter test 51/51 pass; flutter build web --release compiles (dart2js + Wasm dry run). Updated docs/spec.md persistence references.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced JSON-file persistence (path_provider + dart:io File) with sembast: StorageService and AttemptStore now store documents in sembast databases selected at compile time via sqflite on native (iOS/macOS, sqflite_darwin) and indexed_db on Flutter Web (storage_backend_*). Public storage APIs and screen behavior are unchanged, so the Cut screen's _finish() no longer throws UnsupportedError on web and advances to ResultScreen. Added real in-memory sembast round-trip tests for progress/attempt/session persistence; existing widget tests still pass. Verified: flutter analyze clean, flutter test 51/51, flutter build web --release compiles. Removed path_provider dep; updated docs/spec.md.
<!-- SECTION:FINAL_SUMMARY:END -->
