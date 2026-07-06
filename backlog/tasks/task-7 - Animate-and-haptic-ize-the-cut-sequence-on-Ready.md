---
id: TASK-7
title: Animate and haptic-ize the cut sequence on Ready
status: To Do
assignee: []
created_date: '2026-07-06 12:10'
labels:
  - gameplay
  - animation
  - haptics
dependencies: []
references:
  - lib/screens/cut_screen.dart
  - lib/widgets/cut_canvas.dart
priority: medium
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After the player taps 'Ready' on the CutScreen, play a visual cut animation that follows each of the cut lines the player prepared, accompanied by haptic feedback. Only once the cut animation completes should the screen navigate to the result/next screen. Today lib/screens/cut_screen.dart calls _finish() directly from the Ready button, which immediately splits the image mask and triggers navigation (cut_screen.dart:130 and cut_screen.dart:274). Introduce an intermediate animation+ haptic phase between tapping Ready and navigation. Needs Flutter HapticFeedback (package:flutter/services) and an animation controller (the screen already mixes in TickerProviderStateMixin) that sweeps along each CutLine in order. Single-player and multiplayer flows should both go through this animation before invoking the existing _finish/onComplete navigation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tapping 'Ready' starts an animation that visually traces each prepared CutLine in sequence
- [ ] #2 Each cut played in the animation triggers a haptic feedback event
- [ ] #3 Navigation to ResultScreen (single-player) or onComplete (multiplayer) happens only after the cut animation finishes, not on the Ready tap itself
- [ ] #4 The cut animation works for 1-cut (levels 1 and 2) and 2-cut (level 3) cases
- [ ] #5 Existing timer-expiry path still triggers the same animation+haptics before navigating
- [ ] #6 No regressions to current countdown / timer / Ready-enabled behavior
<!-- AC:END -->
