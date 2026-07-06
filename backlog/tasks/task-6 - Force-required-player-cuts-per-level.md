---
id: TASK-6
title: Force required player cuts per level
status: To Do
assignee: []
created_date: '2026-07-06 12:08'
labels:
  - gameplay
  - levels
dependencies: []
references:
  - assets/levels/levels.json
  - lib/models/level.dart
priority: medium
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Levels 1 and 2 should force the player to make exactly 1 cut to reach 2 pieces. Level 3 should force the player to make exactly 2 cuts to reach 3 pieces (no pre-placed initial cuts that count toward the piece count). Adjust the level configuration in assets/levels/levels.json and the level model logic in lib/models/level.dart so the player must perform the required cuts themselves.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Level 1 (level_01) requires the player to make 1 cut to produce 2 pieces
- [ ] #2 Level 2 (level_02) requires the player to make 1 cut to produce 2 pieces
- [ ] #3 Level 3 (level_03) requires the player to make 2 cuts to produce 3 pieces
- [ ] #4 No pre-placed initial cuts reduce the number of cuts the player must perform
- [ ] #5 Existing level loading and requiredCuts logic in lib/models/level.dart still works
<!-- AC:END -->
