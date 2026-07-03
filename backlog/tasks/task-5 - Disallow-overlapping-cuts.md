---
id: TASK-5
title: Disallow overlapping cuts
status: To Do
assignee: []
created_date: '2026-07-03 11:59'
labels:
  - bug
dependencies: []
references:
  - lib/services/cut_validity.dart
  - lib/widgets/cut_canvas.dart
  - test/cut_validity_test.dart
priority: high
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prevent players from placing cuts whose paths overlap with existing cuts in the same attempt. Overlapping cuts create too many small pieces that confuse the splitter output and degrade the user experience.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A new cut whose segment overlaps an existing cut's segment is rejected with the same shake/invalid feedback as other invalid cuts
- [ ] #2 An existing cut can be moved to a new position that overlaps another cut, but the move is reverted on release with shake feedback
- [ ] #3 Overlap is defined geometrically: two line segments within the same [0,1] normalized coordinate space share one or more points (including endpoint-on-segment and full collinear overlaps)
- [ ] #4 The overlap check runs in CutValidity along with existing rules (endpoint transparency, shape intersection) and uses the same per-line validation function signature
- [ ] #5 Tests verify: two cuts that cross are rejected; a cut that shares an endpoint with another cut is rejected; a cut that lies entirely on top of another cut is rejected; two non-overlapping cuts are accepted
<!-- AC:END -->
