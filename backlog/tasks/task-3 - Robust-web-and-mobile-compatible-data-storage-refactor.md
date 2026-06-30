---
id: TASK-3
title: Robust web and mobile compatible data storage refactor
status: Done
assignee:
  - '@opencode'
created_date: '2026-06-30 12:27'
updated_date: '2026-06-30 13:00'
labels: []
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current JSON-file-based persistence (StorageService and AttemptStore using path_provider + dart:io) with sembast (pub.dev/packages/sembast), a NoSQL document database that works on web, iOS, and macOS via sqflite on native and indexed_db on web. No migration of existing data is needed — the old solution will be fully replaced. Do not use Hive or Isar.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Player progress (per-level best scores, sound preference) persists across app restarts on all three platforms (web, iOS, macOS)
- [x] #2 Attempt history persists across app restarts on all three platforms, including multiplayer session grouping
- [x] #3 All existing tests pass with the new storage layer (using fakes/mocks as appropriate)
- [x] #4 All screens that read/write storage (Menu, Settings, Progress, Cut, Multiplayer, Attempts) work identically on all three platforms
- [x] #5 The old StorageService and AttemptStore implementations referencing path_provider / dart:io are removed
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add sembast + sembast_web + sembast_sqflite + sqflite deps; remove path_provider. 2. Add conditional db_factory (web=sembast_web/indexed_db, native=sembast_sqflite/sqflite) + shared DB singleton. 3. Rewrite StorageService and AttemptStore on sembast, keeping public APIs. 4. Update widget tests' mock-setUp (drop path_provider mock) and add sembast-based persistence unit tests. 5. flutter analyze + test green.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Replaced JSON-file persistence with sembast. Added conditional db_factory: sembast_web/IndexedDB on web, sembast_sqflite/sqflite on native (sqflite auto-resolves the platform databases dir, so no path_provider/dart:io is referenced). Shared lazy DB singleton in lib/services/database.dart. StorageService and AttemptStore keep their public APIs but persist documents in sembast stores, preserving multiplayer session grouping and the 200-attempt pruning logic. Removed path_provider from pubspec. Existing widget tests use fakes (unaffected); updated progress_back_button_test to drop the obsolete path_provider mock setter; refreshed stale comments. Added unit tests using newDatabaseFactoryMemory: test/storage_service_test.dart (3) and test/attempt_store_test.dart (6) covering load/save round-trips, persistence across instances, prune-of-multiplayer-session grouping, clear, and id generation. flutter analyze: clean. flutter test: 54 passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced JSON-file persistence (path_provider + dart:io) with sembast. Added a platform-conditional DB factory (sembast_web/IndexedDB on web, sembast_sqflite + sqflite on native, with sqflite resolving the platform databases dir so path_provider/dart:io are never referenced) and a shared lazy database singleton. Rewrote StorageService and AttemptStore on sembast keeping their public APIs, preserving multiplayer session grouping and the 200-attempt pruning. Removed path_provider from pubspec; macOS/iOS generated plugin registrants now register sqflite_darwin. Existing widget tests still use in-memory fakes; dropped the obsolete path_provider mock in progress_back_button_test and refreshed stale comments. Added sembast unit tests using newDatabaseFactoryMemory (storage_service_test.dart, attempt_store_test.dart). Verified: flutter analyze clean, flutter test 54 passed.
<!-- SECTION:FINAL_SUMMARY:END -->
