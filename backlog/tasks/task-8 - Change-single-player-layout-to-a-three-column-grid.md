---
id: TASK-8
title: Change single player layout to a three-column grid
status: To Do
assignee: []
created_date: '2026-07-26 15:29'
labels:
  - ui
  - refactor
dependencies: []
references:
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
- [ ] #1 Levels display in a three-column grid layout instead of vertical rows
- [ ] #2 Grid responds to screen width — narrower screens drop to two or one column
- [ ] #3 Each grid cell shows level title, lock state, best accuracy, and the attempts button
- [ ] #4 Level unlock progression works the same as before
<!-- AC:END -->
