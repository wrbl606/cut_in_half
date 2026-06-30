---
id: TASK-3
title: Robust web and mobile compatible data storage refactor
status: To Do
assignee: []
created_date: '2026-06-30 12:27'
updated_date: '2026-06-30 12:32'
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
- [ ] #1 Player progress (per-level best scores, sound preference) persists across app restarts on all three platforms (web, iOS, macOS)
- [ ] #2 Attempt history persists across app restarts on all three platforms, including multiplayer session grouping
- [ ] #3 All existing tests pass with the new storage layer (using fakes/mocks as appropriate)
- [ ] #4 All screens that read/write storage (Menu, Settings, Progress, Cut, Multiplayer, Attempts) work identically on all three platforms
- [ ] #5 The old StorageService and AttemptStore implementations referencing path_provider / dart:io are removed
<!-- AC:END -->
