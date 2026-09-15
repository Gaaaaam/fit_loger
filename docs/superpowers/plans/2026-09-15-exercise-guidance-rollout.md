# Exercise Guidance Full-Catalog Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the approved guidance system from six representative exercises to all 120 built-ins, verify every asset, and remove the superseded exercise SVGs.

**Architecture:** Use the foundation plan's manifest, prompt builder, processor, validator, and generated ArkTS mapping. Roll out sequentially by body part so each batch has an independent metadata review, image review, resource validation, mapping regeneration, and scoped commit before the next batch begins.

**Tech Stack:** HarmonyOS NEXT API 20, ArkTS/ArkUI, Node.js verification scripts, bundled Python 3 with Pillow/WebP, built-in ImageGen tool.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-guidance-artwork-design.md`

**Prerequisite:** `docs/superpowers/plans/2026-09-15-exercise-guidance-foundation.md` is complete; its six-exercise device quality gate is green.

## Global Constraints

- Preserve unrelated dirty-worktree changes and continue in the same isolated implementation worktree.
- Use built-in ImageGen only; one call per exercise and gender mother sheet.
- The completed catalog contains exactly 240 mother sheets before slicing: 120 female and 120 male.
- Do not change the approved visual system after rollout begins.
- Every catalog ID must have 2–4 captions, equal female/male frame counts, a valid card-frame index, and approved WebP assets.
- Inspect every mother sheet before slicing and inspect every part contact sheet at mobile size after slicing.
- Regenerate only failing exercise/gender sheets.
- Generated mother sheets stay in `.work/exercise-guidance/` and the built-in generator directory; they are not committed.
- Do not remove legacy SVGs until all 120 WebP entries, tests, and the HAP build pass.
- Do not commit signing data, `build-profile.json5`, or unrelated files.
- Keep part illustrations because they remain the fallback for custom or invalid actions.

---

## Common Batch Procedure

Every body-part task below repeats this exact procedure; the ID list in that task is the complete scope.

1. Add or review each listed manifest entry with `frameCount`, `layout`, Chinese `captions`, `cardFrameIndex`, `view`, `equipmentNotes`, `muscleNotes`, and `status: planned`.
2. Set a PowerShell variable named `$guidancePart` to the body-part literal named by the task, then run `node tools/exercises/guidance_prompt.mjs --check --part $guidancePart` and fix metadata until it passes.
3. Run `node tools/exercises/guidance_prompt.mjs --jobs --part $guidancePart`; for every printed JSON job, pass its `prompt` unchanged to one built-in ImageGen call.
4. Copy each returned sheet to the exact `sheetPath` printed by `guidance_prompt.mjs`; the prompt builder derives it from the manifest ID and gender.
5. Inspect every sheet with `view_image`; fix stage order, anatomy, grip, equipment contact, target muscles, identity consistency, crop, or forbidden text by regenerating only that sheet.
6. Slice every accepted sheet with `process_guidance_sheet.py --manifest tools/exercises/guidance.json --sheet-root .work/exercise-guidance --out-dir entry/src/main/resources/base/media --part $guidancePart`.
7. Generate a 320 px contact sheet for the part and inspect all final frames.
8. Change only accepted entries to `status: approved`.
9. Run `verify_guidance_assets.py --part $guidancePart` and regenerate `exerciseGuidanceArtwork.generated.ets`.
10. Run `node tools/verify_catalog.mjs` and commit only that part's metadata, WebP resources, and regenerated mapping.

---

### Task 1: Complete the catalog-wide frame plan before image generation

**Files:**

- Modify: `tools/exercises/guidance.json`
- Modify: `tools/exercises/guidance_prompt.mjs`

**Interfaces:**

- Produces: one unique manifest entry for each of the 120 `EXERCISE_CATALOG` IDs.

- [ ] **Step 1: Add a failing full-manifest check**

Extend `guidance_prompt.mjs --check --require-all` to compare manifest IDs with `curated.json` and fail on missing IDs, extras, duplicates, invalid frame counts/layouts, caption mismatch, invalid card index, empty camera/equipment/muscle notes, or non-`planned|approved` status.

- [ ] **Step 2: Run and verify RED**

Run: `node tools/exercises/guidance_prompt.mjs --check --require-all`

Expected: FAIL and list the 114 IDs not covered by the foundation manifest.

- [ ] **Step 3: Add all remaining frame plans**

Use these assignment rules:

- `horizontal-2`: simple isolation, stable machine, or two-state bodyweight actions.
- `horizontal-3`: compound lifts, meaningful mid-trajectory, alternating/unilateral actions, or rotational actions.
- `grid-4`: only actions with four semantically distinct stages; do not inflate a movement merely to use four frames.

Write captions as short visible Chinese phrases, not copied full instruction sentences. Choose the card frame that best identifies the exercise and equipment. Use the existing `pose`, `startPosition`, `steps`, `cues`, primary muscles, and equipment fields as the factual basis.

- [ ] **Step 4: Run and verify GREEN**

Run: `node tools/exercises/guidance_prompt.mjs --check --require-all`

Expected: PASS with `entries=120`; six approved and 114 planned.

- [ ] **Step 5: Commit the reviewed frame plan**

```powershell
git add -- tools/exercises/guidance.json tools/exercises/guidance_prompt.mjs
git commit -m "docs: define full exercise guidance frame plan"
```

---

### Task 2: Chest artwork batch

**Files:**

- Modify: `tools/exercises/guidance.json`
- Create: `entry/src/main/resources/base/media/ex_chest_*_{female|male}_{01..04}.webp`
- Regenerate: `entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets`

**Scope IDs:** `chest_db_bench`, `chest_incline_bench`, `chest_fly`, `chest_cable_crossover`, `chest_dip`, `chest_pushup`, `chest_decline_bench`, `chest_incline_db_press`, `chest_decline_db_press`, `chest_incline_fly`, `chest_machine_press`, `chest_pec_deck`, `chest_close_pushup`, `chest_incline_pushup`, `chest_decline_pushup`, `chest_pullover`. `chest_bb_bench` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'chest'` and run the Common Batch Procedure for only the scope IDs above**

Expected asset check: all 17 chest actions approved; no missing female or male frames.

- [ ] **Step 2: Commit the chest batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_chest_*.webp
git commit -m "feat: add chest exercise guidance artwork"
```

---

### Task 3: Shoulder artwork batch

**Files:**

- Modify: `tools/exercises/guidance.json`
- Create: `entry/src/main/resources/base/media/ex_shoulder_*_female_*.webp`
- Create: `entry/src/main/resources/base/media/ex_shoulder_*_male_*.webp`
- Regenerate: `entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets`

**Scope IDs:** `shoulder_bb_press`, `shoulder_db_press`, `shoulder_lateral_raise`, `shoulder_front_raise`, `shoulder_reverse_fly`, `shoulder_face_pull`, `shoulder_seated_bb_press`, `shoulder_machine_press`, `shoulder_cable_lateral`, `shoulder_cable_rear_fly`, `shoulder_machine_reverse_fly`, `shoulder_bent_over_raise`, `shoulder_cable_front`. `shoulder_arnold` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'shoulder'` and run the Common Batch Procedure for only the scope IDs above**

Expected asset check: all 14 shoulder actions approved.

- [ ] **Step 2: Commit the shoulder batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_shoulder_*.webp
git commit -m "feat: add shoulder exercise guidance artwork"
```

---

### Task 4: Back artwork batch

**Files:** manifest, generated mapping, and `ex_back_*` WebP resources.

**Scope IDs:** `back_pullup`, `back_lat_pulldown`, `back_bb_row`, `back_db_row`, `back_seated_row`, `back_chinup`, `back_wide_pulldown`, `back_close_pulldown`, `back_reverse_pulldown`, `back_chest_supported_row`, `back_straight_arm_pulldown`, `back_hyperextension`, `back_tbar_row`, `back_inverted_row`, `back_one_arm_cable_row`. `back_deadlift` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'back'` and run the Common Batch Procedure for only the scope IDs above**

Expected asset check: all 16 back actions approved.

- [ ] **Step 2: Commit the back batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_back_*.webp
git commit -m "feat: add back exercise guidance artwork"
```

---

### Task 5: Arm artwork batch

**Files:** manifest, generated mapping, and `ex_arm_*` WebP resources.

**Scope IDs:** `arm_bb_curl`, `arm_db_curl`, `arm_hammer_curl`, `arm_pushdown`, `arm_skull_crusher`, `arm_incline_curl`, `arm_preacher_curl`, `arm_cable_curl`, `arm_concentration_curl`, `arm_overhead_extension`, `arm_one_arm_pushdown`, `arm_kickback`, `arm_wrist_curl`, `arm_reverse_wrist`, `arm_ez_curl`, `arm_close_grip_bench`.

- [ ] **Step 1: Set `$guidancePart = 'arm'` and run the Common Batch Procedure for all scope IDs above**

Expected asset check: all 16 arm actions approved.

- [ ] **Step 2: Commit the arm batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_arm_*.webp
git commit -m "feat: add arm exercise guidance artwork"
```

---

### Task 6: Glute artwork batch

**Files:** manifest, generated mapping, and `ex_glute_*` WebP resources.

**Scope IDs:** `glute_hip_thrust`, `glute_rdl`, `glute_bridge`, `glute_abduction`, `glute_single_leg_thrust`, `glute_single_leg_bridge`, `glute_cable_kickback`, `glute_donkey_kick`, `glute_side_lying_abduction`, `glute_band_lateral_walk`, `glute_clamshell`, `glute_pull_through`, `glute_frog_pump`.

- [ ] **Step 1: Set `$guidancePart = 'glute'` and run the Common Batch Procedure for all scope IDs above**

Expected asset check: all 13 glute actions approved.

- [ ] **Step 2: Commit the glute batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_glute_*.webp
git commit -m "feat: add glute exercise guidance artwork"
```

---

### Task 7: Leg artwork batch

**Files:** manifest, generated mapping, and `ex_leg_*` WebP resources.

**Scope IDs:** `leg_press`, `leg_extension`, `leg_curl`, `leg_lunge`, `leg_calf_raise`, `leg_front_squat`, `leg_goblet_squat`, `leg_split_squat`, `leg_bulgarian_split`, `leg_step_up`, `leg_hack_squat`, `leg_seated_curl`, `leg_standing_calf`, `leg_seated_calf`, `leg_walking_lunge`, `leg_reverse_lunge`, `leg_sumo_squat`. `leg_squat` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'leg'` and run the Common Batch Procedure for only the scope IDs above**

Expected asset check: all 18 leg actions approved.

- [ ] **Step 2: Commit the leg batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_leg_*.webp
git commit -m "feat: add leg exercise guidance artwork"
```

---

### Task 8: Abs and core artwork batch

**Files:** manifest, generated mapping, `ex_abs_*` and `ex_core_*` WebP resources.

**Abs IDs:** `abs_crunch`, `abs_reverse_crunch`, `abs_leg_raise`, `abs_machine_crunch`, `abs_cable_crunch`, `abs_hanging_knee`, `abs_hanging_leg`, `abs_alt_crunch`, `abs_heel_touch`, `abs_flutter_kick`, `abs_decline_crunch`, `abs_v_up`.

**Core IDs:** `core_dead_bug`, `core_shoulder_tap`, `core_pallof`, `core_side_plank_hip`, `core_up_down`, `core_russian_twist`, `core_woodchop`, `core_hollow_rock`, `core_body_saw`. `core_bird_dog` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'abs'` and run the Common Batch Procedure for all Abs IDs above**

Expected asset check: all 12 abs actions approved.

- [ ] **Step 2: Set `$guidancePart = 'core'` and run the Common Batch Procedure for only the Core IDs above**

Expected asset check: all 10 core actions approved.

- [ ] **Step 3: Commit the abs/core batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_abs_*.webp entry/src/main/resources/base/media/ex_core_*.webp
git commit -m "feat: add abs and core exercise guidance artwork"
```

---

### Task 9: Cardio artwork batch

**Files:** manifest, generated mapping, and `ex_cardio_*` WebP resources.

**Scope IDs:** `cardio_jump_rope`, `cardio_jumping_jack`, `cardio_mountain_climber`. `cardio_burpee` is already approved.

- [ ] **Step 1: Set `$guidancePart = 'cardio'` and run the Common Batch Procedure for only the scope IDs above**

Expected asset check: all 4 cardio actions approved.

- [ ] **Step 2: Commit the cardio batch**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_cardio_*.webp
git commit -m "feat: add cardio exercise guidance artwork"
```

---

### Task 10: Require full guidance coverage and remove runtime legacy fallback

**Files:**

- Modify: `tools/verify_catalog.mjs`
- Modify: `tools/exercises/verify_guidance_assets.py`
- Modify: `entry/src/main/ets/model/exerciseArtwork.ets`
- Modify: `tools/verify_project.mjs`
- Modify: `tools/exercises/curated.json`
- Modify: `tools/exercises/data.mjs`
- Modify: `tools/exercises/generate.mjs`
- Modify: `entry/src/main/resources/rawfile/exercises/ATTRIBUTION.md`
- Modify: `entry/src/main/resources/rawfile/exercises/LICENSE.txt`

**Interfaces:**

- Changes validation from transitional six-entry coverage to exactly 120 approved entries.
- Keeps part-image fallback for custom or invalid IDs.
- Stops returning legacy start/end SVGs for built-in IDs.

- [ ] **Step 1: Write the failing full-coverage assertions**

Require:

```javascript
assert.equal(GENERATED_GUIDANCE_ARTWORK.length, EXERCISE_CATALOG.length);
for (const item of EXERCISE_CATALOG) {
  const art = guidanceArtworkOf(item.id);
  assert(art, `missing guidance ${item.id}`);
  assert.equal(art.femaleFrames.length, art.maleFrames.length);
  assert(art.femaleFrames.length >= 2 && art.femaleFrames.length <= 4);
  assert.equal(art.frameCaptions.length, art.femaleFrames.length);
  assert(art.cardFrameIndex >= 0 && art.cardFrameIndex < art.femaleFrames.length);
}
```

Also assert `exerciseArtwork.ets` no longer references legacy `.start` or `.end` for built-in fallback.

Add source-contract assertions that `curated.json` and `ATTRIBUTION.md` no longer claim the packaged action artwork is original vector illustration, continue to state that upstream photos are excluded, and identify the new images as AI-generated 3D instructional illustrations reviewed and packaged by this project.

- [ ] **Step 2: Run and verify RED**

Run: `node tools/verify_catalog.mjs`

Expected: FAIL while legacy fallback remains.

- [ ] **Step 3: Remove only the built-in legacy path**

Keep `partFallback(partKey)` and custom-action behavior. `guidanceFramesOf` returns a one-frame part illustration only when no generated entry exists. `cardImageOf` uses the generated card frame or the part illustration.

Update `SOURCE.photoNote` in `data.mjs` and the attribution/license emitters in `generate.mjs`, then regenerate or edit the checked-in outputs consistently. Do not change the upstream data license: retain the pinned `free-exercise-db` commit and Unlicense text, state that no upstream photo is included, and state that the packaged exercise artwork was generated specifically for this project with OpenAI's built-in image generation tool and then manually reviewed/processed.

- [ ] **Step 4: Run full coverage checks**

```powershell
node tools/exercises/guidance_prompt.mjs --check --require-all
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/verify_guidance_assets.py --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media --require-all
node tools/verify_catalog.mjs
node tools/verify_project.mjs
```

Expected: 120 approved entries; all commands exit 0.

- [ ] **Step 5: Commit full runtime coverage**

```powershell
git add -- entry/src/main/ets/model/exerciseArtwork.ets tools/verify_catalog.mjs tools/verify_project.mjs tools/exercises/verify_guidance_assets.py tools/exercises/curated.json tools/exercises/data.mjs tools/exercises/generate.mjs entry/src/main/resources/rawfile/exercises/ATTRIBUTION.md entry/src/main/resources/rawfile/exercises/LICENSE.txt
git commit -m "feat: require guidance artwork for every built-in exercise"
```

---

### Task 11: Verify package size, all UI modes, and the HAP build

**Files:**

- Modify only files whose defects are exposed by verification.

- [ ] **Step 1: Run every automated check from the foundation plan**

Run all Node commands and both Python commands listed in Foundation Task 7.

Expected: all exit 0; asset report shows `approved=120, planned=0` and a frame count between 550 and 650.

- [ ] **Step 2: Measure packaged artwork size**

Run:

```powershell
$files = Get-ChildItem -LiteralPath 'entry/src/main/resources/base/media' -Filter 'ex_*.webp'
$bytes = ($files | Measure-Object -Property Length -Sum).Sum
Write-Output ("files=" + $files.Count)
Write-Output ("bytes=" + $bytes)
if ($bytes -gt 125829120) { throw 'guidance artwork exceeds 120 MiB' }
```

Expected: 550–650 files and no threshold error. If over 120 MB (125,829,120 bytes), reprocess from the retained mother sheets at a lower dimension or WebP quality, then repeat visual checks; do not remove frames.

- [ ] **Step 3: Build the HAP**

In DevEco Studio, select `Build > Build Hap(s)/APP(s) > Build Hap(s)` for `entry`.

Expected: `hvigor BUILD SUCCESSFUL`; no new artwork-related warning or error.

- [ ] **Step 4: Device/emulator matrix**

Check light/dark × Auto/Female/Male. Open at least one simple and one compound action from every body part. Verify card/detail gender consistency, 2/3/4-frame swipe behavior, caption sync, fallback for a custom action, and no cropped body/equipment.

- [ ] **Step 5: Confirm rollout verification state**

Run `git status --short` and verify no uncommitted manifest, generated mapping, WebP, model, UI, or verifier file from Tasks 1–10 remains. If verification exposed a defect, return to the owning task, repeat that task's checks, and use its exact scoped commit command.

---

### Task 12: Remove the superseded 360 exercise SVGs safely

**Files:**

- Create then remove after use: `.work/retire-exercise-svg.mjs`
- Delete: for every catalog ID, exactly the three exercise files ending in `_card.svg`, `_start.svg`, and `_end.svg` under `entry/src/main/resources/base/media/`.
- Modify: `tools/exercises/generate.mjs`
- Modify: `tools/exercises/svg.mjs`
- Modify: `tools/verify_catalog.mjs`

- [ ] **Step 1: Make legacy presence fail the final test**

Add a final verifier assertion that counts `ex_*.svg` and requires zero, while continuing to require `part_*.svg`.

Run: `node tools/verify_catalog.mjs`

Expected: FAIL and report 360 legacy exercise SVGs.

- [ ] **Step 2: Dry-run an exact deletion list**

The temporary Node script must read catalog IDs, construct only these exact paths for `card`, `start`, and `end`, resolve each path, verify it remains inside the media directory, and print all 360 paths without deleting.

Run: `node .work/retire-exercise-svg.mjs --dry-run`

Expected: exactly 360 unique existing paths; no part illustration path.

- [ ] **Step 3: Delete the validated exact paths**

Run: `node .work/retire-exercise-svg.mjs --apply`

Expected: exactly 360 files removed. Do not use a recursive delete or a broad filesystem target.

- [ ] **Step 4: Retire the old SVG generator path**

Remove exercise-SVG emission, the legacy `artworkEts()` generator, and the `writeFileSync(... 'exerciseArtwork.ets')` call from `tools/exercises/generate.mjs`. Keep catalog/detail generation. Delete `tools/exercises/svg.mjs` only if `rg -n "svg.mjs|renderExerciseSvg|buildScene" tools entry` shows no remaining consumer.

- [ ] **Step 5: Run final verification**

```powershell
node tools/verify_catalog.mjs
node tools/verify_project.mjs
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/verify_guidance_assets.py --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media --require-all
```

Expected: all PASS; `ex_*.svg=0`; part SVG fallback assets remain.

- [ ] **Step 6: Build the HAP once more**

In DevEco Studio, build the `entry` HAP.

Expected: `hvigor BUILD SUCCESSFUL` without missing-resource errors.

- [ ] **Step 7: Commit the recoverable cleanup**

```powershell
git add -- entry/src/main/resources/base/media tools/exercises/generate.mjs tools/exercises/svg.mjs tools/verify_catalog.mjs
git commit -m "chore: remove superseded exercise svg artwork"
```

Confirm `git show --stat HEAD` lists only the validated SVG removals and generator/verifier updates.
