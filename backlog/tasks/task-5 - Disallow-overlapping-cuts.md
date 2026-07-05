---
id: TASK-5
title: Disallow overlapping cuts
status: Done
assignee: []
created_date: '2026-07-03 11:59'
updated_date: '2026-07-05 09:42'
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
- [x] #1 A new cut whose segment overlaps an existing cut's segment is rejected with the same shake/invalid feedback as other invalid cuts
- [x] #2 An existing cut can be moved to a new position that overlaps another cut, but the move is reverted on release with shake feedback
- [x] #3 Overlap is defined geometrically: two line segments within the same [0,1] normalized coordinate space share one or more points (including endpoint-on-segment and full collinear overlaps)
- [x] #4 The overlap check runs in CutValidity along with existing rules (endpoint transparency, shape intersection) and uses the same per-line validation function signature
- [x] #5 Tests verify: two cuts that cross are rejected; a cut that shares an endpoint with another cut is rejected; a cut that lies entirely on top of another cut is rejected; two non-overlapping cuts are accepted
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add CutValidity.check overload accepting existing cuts + excludeId; add _overlapsAnyExisting using segment-intersection (collinear + endpoint-on-segment + crossing). 2. Wire new-cut and move validation in cut_canvas to pass existing cuts (excluding the moved cut id) so overlaps trigger shake/revert. 3. Add unit tests in cut_validity_test.dart for the four overlap cases.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Started implementation.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added CutValidity.checkWith(line, mask, existing, {excludeId}) which runs the existing endpoint-transparency + shape-intersection rules and a new segment-overlap rule (proper crossing, endpoint-on-segment, and collinear partial/full overlaps) using the same per-line signature. CutCanvas now passes existing cuts to the new overload for both new-cut commit and live/committed move validation, excluding the moved cut's id so a cut never compares against itself. Existing CutValidity.check(line, mask) is preserved as a thin shim. Added 6 unit tests covering crossing, shared endpoint, full overlay, partial collinear overlap, two non-overlapping parallel cuts, and the excludeId move case. flutter analyze clean; 57 tests pass.
<!-- SECTION:FINAL_SUMMARY:END -->
