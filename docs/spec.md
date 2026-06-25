# Cut In Half — Game Specification

Version 1.0 · Status: locked · Last updated: 2026-06-24

---

## 1. Overview

A precision party game built in Flutter. Players cut an on-screen image into a target number of pieces by dragging cut lines. Closer-to-equal piece areas = better score. Two modes:

- **Single Player** — structured campaign with unlockable levels + persistent best-score progression.
- **Multiplayer** — 2–12 players, hot-swap the same device, identical randomized level, compare accuracy, pick a winner.

---

## 2. Cut mechanics

- Drag a finger over the screen → a **single straight cut line** defined by its start and end points.
- A cut is **valid** iff:
  1. Both endpoints lie on a **transparent pixel** of the image (alpha ≤ threshold). Endpoints are looked up against the alpha mask directly — not the non-transparent AABB — so they may sit anywhere the image is transparent: the outer padding *and* internal negative space / holes (crescents, donuts, stenciled shapes, etc.). Pointer positions that fall outside the displayed image rect are clamped to the image edge before lookup.
  2. The line segment **intersects** the image's non-transparent region at least once.
- Invalid drags are discarded with brief shake/flash feedback; no cut is added.
- Valid drags draw a persistent slash line on top of the image.

### Cut interaction (selection, move, delete)

- **Tap-to-select** interaction model (tap-then-drag, to avoid ambiguity with new-cut creation).
- Tap an existing non-locked cut to enter **select mode**: two endpoint handles + a body handle appear.
- Drag an endpoint handle → repositions that endpoint.
- Drag the body handle → translates the entire line.
- Tap empty canvas → deselect.
- Locked cuts ignore all pointer events; selecting is blocked.
- **Deletion applies only to player-drawn cuts** (tap-to-select → delete affordance).
- Initial unlocked cuts are **movable but not removable**.
- On release of a moved cut, re-validate (§2 validity rules). If invalid (endpoint on an opaque pixel / no intersection), the cut **snaps back** to its prior valid position with shake feedback.

### Cut classification

A `CutLine` is characterized by two flags:

| Flag        | Player-drawn | Initial (locked) | Initial (unlocked) |
|-------------|--------------|-----------------|--------------------|
| `isInitial` | false        | true            | true               |
| `locked`    | false        | true            | false              |
| Movable     | yes          | no              | yes                |
| Deletable   | yes          | no              | no                 |

### Target piece count

- N pieces requires **N − 1 cuts** total (initial + player-drawn counts combined).
- Example: target 4 pieces with 1 initial cut → player draws 2 more.
- Loader enforces `initial_cuts.length <= target_pieces − 1` (excess is ignored).
- The **Ready** button activates only when total cuts = `target_pieces − 1`.

---

## 3. Time limit

- Each level declares `time_limit` (integer seconds).
- Countdown starts at level load; visible HUD, last 5s pulse red.
- Reaching 0 auto-triggers the cut-and-score phase (same as pressing **Ready**).

---

## 4. Level format

Single `assets/levels/levels.json` file containing an array of levels.

```json
[
  {
    "id": "level_03",
    "title": "Apple",
    "image": "assets/images/apple.png",
    "time_limit": 20,
    "target_pieces": 4,
    "initial_cuts": [
      { "x1": 0.10, "y1": 0.00, "x2": 0.10, "y2": 1.00, "locked": true }
    ],
    "unlock_points": 60
  }
]
```

- **Single image** per level (PNG only for v1). The app computes the non-transparent mask from the image's **alpha channel** at load time — no separate mask file.
- **Coordinates are normalized [0,1]** against the on-screen image display rect for resolution independence.
- `initial_cuts` entries carry a `locked` boolean:
  - `locked: true` — pre-placed, non-interactive, constrains the puzzle.
  - `locked: false` — pre-placed but movable (per §2 interaction rules); not deletable.
- `unlock_points`: cumulative points needed from earlier levels to unlock.

---

## 5. Cut & split algorithm

1. At level load, decode the image and build an **alpha mask** at a fixed sample scale (source's natural resolution capped at ~256 px on the long edge — perf/accuracy trade-off, tunable in code).
2. Total reference area `A_total` = count of pixels where `alpha > threshold` (hard-coded **128** for v1, not exposed in Settings).
3. The alpha mask itself (per-pixel transparent/opaque) is used for "inside/outside the shape" validity checks (§2). Endpoints must land on transparent mask pixels — including internal negative space — not merely outside the shape's axis-aligned bounding box.
4. Apply cuts in sequence to the mask:
   - Each cut line splits every existing region into "left" and "right" sub-regions by classifying each pixel relative to the line.
   - Resulting regions: `R_1 … R_N`.
5. For each region, `area_i` = non-transparent pixel count; `percent_i = area_i / A_total * 100`, rounded to **2 decimals** for display (full precision kept for scoring).
6. Layout resulting pieces in a **PieceGallery** widget (grid/fan), each labeled with its percentage.

### Piece rendering

Each region is rendered by cropping its **bounding box** from the original asset and zeroing alpha outside that region's mask pixels (preserves art fidelity for arbitrary shapes, including negative-space pieces).

---

## 6. Scoring

- Ideal share = `1 / N`. Per-piece deviation `d_i = |p_i/100 − 1/N|`.
- **Accuracy** = `100 * (1 − N * Σ d_i / 2)`, clamped to `[0, 100]`.
  - 100 = perfectly equal pieces.
  - 0 = maximally uneven.
- **Points awarded** = `round(accuracy)` → stored as best result in Single Player progression.
- Best score only goes up on replay (no regression).
- Post-cut screen shows every piece's percentage and the final accuracy.

---

## 7. Single Player mode

- Levels are played in order from `levels.json`.
- **Progress screen** lists all levels; each row shows:
  - lock state (locked/unlocked),
  - best accuracy %,
  - best points earned,
  - cumulative points earned,
  - the level's `unlock_points` threshold.
- A level unlocks when cumulative points reach that level's `unlock_points`.
- Replay may only improve the stored best.
- Persistence via a **JSON file** stored with `path_provider` (cleaner than `shared_preferences` for the structured progress table).

---

## 8. Multiplayer mode

- Setup screen: choose player count **2–12**; enter names (defaults `P1…P12`).
- The level is **randomized** (same for all players, for fairness):
  - Random image (from bundled assets — can share Single Player's library).
  - Random `target_pieces` in range **2–6**.
  - Random `time_limit` from a small preset (e.g., 15 / 20 / 25 / 30s).
  - No `initial_cuts` in v1 (random initial cuts deferred).
- **Hot-swap flow:**
  1. "Pass to P_k" splash → P_k plays → result hidden, stored.
  2. Repeat for `k = 1 … n`.
  3. **Final standings** screen: each player's piece breakdown + accuracy, side-by-side, ranked. Winner highlighted.
  4. Ties broken by **remaining time** at Ready press (higher remaining time = faster = wins tiebreak).
- No persistence between sessions (multiplayer is one-off).

---

## 9. Screen flow

- **Menu**: Single Player · Multiplayer · Settings (sound only for v1)
- Single Player → Progress → Level → Cut → Result → Progress
- Multiplayer → Setup → Pass-splash → Level → Cut → Pass-splash → … → Standings

---

## 10. Architecture

```
lib/
  main.dart
  app.dart
  models/
    level.dart
    cut_line.dart
    level_result.dart
    player_progress.dart
  services/
    level_loader.dart          // parses levels.json
    image_masker.dart          // decodes asset, builds alpha mask
    splitter.dart              // applies cuts to mask -> regions + areas
    storage_service.dart       // JSON via path_provider (single-player)
    randomizer.dart            // multiplayer level generator
  screens/
    menu_screen.dart
    progress_screen.dart
    multi_setup_screen.dart
    cut_screen.dart            // shared gameplay: timer + canvas + Ready
    result_screen.dart
    standings_screen.dart
  widgets/
    cut_canvas.dart            // image + draggable cuts + validity checks
    pass_splash.dart
    piece_gallery.dart
assets/
  levels/levels.json
  images/*.png
```

### New dependencies (vs. stock Flutter)

- `path_provider` — JSON progress storage.
- `image` — decode PNG alpha off the UI isolate via `compute`.

---

## 11. Implementation plan (ordered)

1. Add deps to `pubspec.yaml`; declare `assets/levels/` and `assets/images/` in `pubspec.yaml`.
2. Models: `Level`, `CutLine`, `LevelResult`, `PlayerProgress` with JSON (de)serialization. `CutLine` carries `id`, `x1,y1,x2,y2` (mutable), `locked`, `isInitial`.
3. `LevelLoader` parses `levels.json` → `List<Level>`. Enforce `initial_cuts.length <= target_pieces − 1`.
4. `ImageMasker`: load asset → `image` decode → produce alpha mask grid + non-transparent bbox. Expose `A_total`, mask grid, bbox. Cache per level.
5. `Splitter`: given mask + list of `CutLine` (normalized) → list of region masks → non-transparent pixel counts → per-region percentages. Pure function, unit-testable.
6. `CutValidity.check(line, bbox, mask)`: implements §2 rules. Unit-testable.
7. `CutCanvas` widget: paints the image scaled to its rect, draws existing cuts (locked cuts styled distinctly), captures pointer drag, on drag end validates and either commits a cut or shows shake feedback. Implements tap-to-select → endpoint/body handle drag → live validity preview → snap-back-on-invalid. Tap-to-delete for player-drawn cuts.
8. `CutScreen`: hosts `CutCanvas` + timer HUD + Ready button (activates at total cuts = `target_pieces − 1`); on Ready or timeout → invoke `Splitter` → build `LevelResult` → push to `ResultScreen`.
9. `ResultScreen` + `PieceGallery`: render the pieces (each region as its own cropped image from the original PNG using its bounding rect, with masked alpha) in a grid, each labeled with `xx.xx%`. Show accuracy.
10. `StorageService` (JSON file): load/save `PlayerProgress` (map of `level_id` → best accuracy / best points / total). Provide unlock predicate.
11. `ProgressScreen`: list levels, lock state, best stats, unlock thresholds. Navigation to play.
12. `Randomizer` + `MultiSetupScreen` + `PassSplash` + `Standings`. Hot-swap loop using the same `CutScreen` with the randomized `Level`.
13. Menu + Settings (sound toggle only for v1).
14. Bundle **stub placeholder** levels + images (~12 simple geometric PNGs).
15. Unit tests: `Splitter` correctness (rectangles, triangles, alpha shapes), `CutValidity` cases (endpoint inside, no intersection, snap-back), `LevelLoader` / `StorageService` round-trips, initial-cut move + snap-back behavior.

---

## 12. v1 scope decisions (locked)

| Area                | Decision                                                                   |
| ------------------- | -------------------------------------------------------------------------- |
| Levels / images     | **Stub placeholders** (~12 simple geometric PNGs). Real art swappable later.|
| Image format        | **PNG only**. (WEBP is a trivial later add, not in v1 scope.)              |
| Alpha threshold     | Hard-coded **128**. Not exposed in Settings for v1.                         |
| Initial cuts        | **Locked**³ constrain; **unlocked** movable-but-not-removable (per §2).   |
| Selection UX        | **Tap-to-select-then-drag** (avoids ambiguity with new-cut creation).      |
| Bundled levels      | ~12 for v1.                                                                |
| Persistence         | JSON file via `path_provider`.                                             |
| Mask sample cap     | ~256 px on long edge (tunable in code, not user-facing).                    |
| Piece rendering     | Bounding-box crop of source asset + alpha-zero outside region mask.        |

---

## 13. Deferred / out of scope for v1

- Custom downloadable / importable level packs.
- Random initial cuts in multiplayer.
- WEBP image support.
- User-facing alpha-threshold control.
- Online multiplayer / cross-device play (hot-swap is local-only).
- Sound effects beyond a simple toggle.
- Achievement / medal system beyond best-score progression.