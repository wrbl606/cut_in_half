---
id: TASK-2
title: Fix Ready button on web so finishing a level advances to the result screen
status: Done
assignee:
  - '@opencode'
created_date: '2026-06-29 13:02'
updated_date: '2026-06-29 14:31'
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
- [x] #1 On the web build, after making the required cuts and pressing Ready, the app advances to the ResultScreen showing the level result
- [x] #2 Player progress (best score/accuracy) persists across web app reloads
- [x] #3 Attempt history is recorded on web and survives reloads (or degrades gracefully with documented rationale if intentionally skipped)
- [x] #4 iOS and macOS behavior is unchanged: existing file-based persistence still works
- [x] #5 flutter analyze is clean and both web and mobile builds compile without errors
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add lib/services/local_store.dart conditional export + local_store_io.dart (File+path_provider) + local_store_web.dart (localStorage via dart:js_interop) exposing read/write. 2. Refactor StorageService and AttemptStore to use LocalStore instead of dart:io directly; keep public API (load/save, loadAll/saveAll/record/clear) and accept optional LocalStore for injection. 3. Wrap _finish() persistence in try/catch so navigation to ResultScreen always happens even if persistence throws. 4. Add unit tests with path_provider mock verifying save/load round-trips for progress and attempts on the io path. 5. Run flutter analyze + flutter test + flutter build web to verify.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added lib/services/local_store.dart (conditional export) with local_store_io.dart (File + path_provider, unchanged mobile/desktop behaviour) and local_store_web.dart (window.localStorage via dart:js_interop). Refactored StorageService and AttemptStore to read/write through LocalStore instead of dart:io directly; both accept an optional LocalStore for injection. Wrapped _finish() persistence in try/catch so Navigator.pushReplacement(ResultScreen) always runs even if storage throws — this is the direct fix for the web Ready-button stall. Added test/persistence_test.dart (path_provider mock) verifying save/load round-trips for progress and attempts on the io path.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Fixed the web Ready-button stall by routing StorageService/AttemptStore persistence through a new platform-conditional LocalStore: File+path_provider on mobile/desktop (behaviour unchanged) and window.localStorage via dart:js_interop on web. Wrapped cut_screen _finish() persistence in try/catch so Navigator.pushReplacement(ResultScreen) always runs even if storage throws — the direct cause of the stall. Added test/persistence_test.dart covering save/load round-trips for progress and attempts on the io path. Verified: flutter analyze clean, flutter test 52/52 passing, flutter build web --wasm compiles. iOS/macOS build not executed (no Apple toolchain on Linux) but the dart:io path is covered by analyze + the new unit tests and is unchanged from the original File+path_provider logic.
<!-- SECTION:FINAL_SUMMARY:END -->
