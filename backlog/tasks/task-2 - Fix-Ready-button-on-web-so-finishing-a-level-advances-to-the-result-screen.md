---
id: TASK-2
title: Fix Ready button on web so finishing a level advances to the result screen
status: To Do
assignee: []
created_date: '2026-06-29 13:02'
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

Root cause: _finish() in lib/screens/cut_screen.dart calls StorageService.save() and AttemptStore.record(). Both services (lib/services/storage_service.dart, lib/services/attempt_store.dart) persist via dart:io File plus path_provider's getApplicationSupportDirectory(), neither of which is supported on Flutter Web. StorageService.load() swallows errors and returns fresh state, but StorageService.save() has no try/catch and throws an UnsupportedError on web. That exception escapes _finish() before Navigator.of(context).pushReplacement(...ResultScreen) runs, so the result screen never appears and the button looks like it does nothing.

Fix so completing a level on web persists progress with a web-compatible store (e.g. shared_preferences, or conditional exports that swap dart:io for a web-safe implementation) and reliably advances to the ResultScreen. Keep mobile/desktop file-based persistence working.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 On the web build, after making the required cuts and pressing Ready, the app advances to the ResultScreen showing the level result
- [ ] #2 Player progress (best score/accuracy) persists across web app reloads
- [ ] #3 Attempt history is recorded on web and survives reloads (or degrades gracefully with documented rationale if intentionally skipped)
- [ ] #4 iOS and macOS behavior is unchanged: existing file-based persistence still works
- [ ] #5 flutter analyze is clean and both web and mobile builds compile without errors
<!-- AC:END -->
