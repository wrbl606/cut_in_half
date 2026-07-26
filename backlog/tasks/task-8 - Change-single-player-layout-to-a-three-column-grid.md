---
id: TASK-8
title: Change single player layout to a three-column grid
status: Done
assignee:
  - '@opencode-agent'
created_date: '2026-07-26 15:29'
updated_date: '2026-07-26 15:35'
labels:
  - ui
  - refactor
dependencies: []
references:
  - lib/screens/progress_screen.dart
modified_files:
  - lib/screens/progress_screen.dart
priority: medium
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current vertical ListView row layout in ProgressScreen with a responsive three-column grid layout showing level cards.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Levels display in a three-column grid layout instead of vertical rows
- [x] #2 Grid responds to screen width — narrower screens drop to two or one column
- [x] #3 Each grid cell shows level title, lock state, best accuracy, and the attempts button
- [x] #4 Level unlock progression works the same as before
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Replaced ListView.separated with LayoutBuilder + GridView.builder using responsive breakpoints (>=600px: 3 cols, >=360px: 2 cols, <360px: 1 col). Converted _LevelRow (ListTile) to _LevelCard (Material+InkWell card) with vertical layout showing lock state, title, accuracy/points, pieces/time info, and attempts button. All 57 existing tests pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced ListView.separated in ProgressScreen with a responsive GridView.builder using LayoutBuilder. Breakpoints: >=600px = 3 columns, >=360px = 2 columns, <360px = 1 column. Converted _LevelRow (horizontal ListTile) to _LevelCard (vertical Material+InkWell card) showing lock state icon, level title, best accuracy/points, pieces/time info, and attempts button. Unlock progression logic unchanged. All 57 existing tests pass.
<!-- SECTION:FINAL_SUMMARY:END -->
