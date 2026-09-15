# Exercise Guidance Foundation and Quality Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the gender-selection, variable-frame artwork pipeline, app UI, and six-exercise quality gate needed before full-catalog generation.

**Architecture:** Keep generation metadata and image-processing tools under `tools/exercises`, and keep runtime selection in a small pure ArkTS module. Add a generated guidance-artwork table alongside the legacy SVG table so the six quality-gate exercises use the new carousel while all other actions keep working through the old start/end fallback.

**Tech Stack:** HarmonyOS NEXT API 20, ArkTS/ArkUI, Preferences, Node.js verification scripts, bundled Python 3 with Pillow/WebP, built-in ImageGen tool.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-guidance-artwork-design.md`

## Global Constraints

- Preserve all unrelated dirty-worktree changes; execute in an isolated worktree created at execution time.
- Use built-in ImageGen, not the CLI/API fallback.
- Every quality-gate exercise receives one female sheet and one male sheet.
- Final images contain no text, numbers, arrows, logos, watermarks, or decorative gym background.
- Final resources are WebP quality 82. For example, frame 1 of the female squat is `ex_leg_squat_female_01.webp`; every other file follows the same ID, gender, and two-digit frame suffix convention.
- New frames must show the full person and all exercise equipment with safe margins.
- Missing or invalid guidance artwork must fall back to existing SVG artwork or the part illustration.
- Keep the existing 360 exercise SVG files during this plan.
- Do not add generated mother sheets to Git; keep them under `.work/exercise-guidance/` and in the built-in generator's default directory.
- Do not commit `build-profile.json5`, signing paths, passwords, or unrelated workspace files.
- `Swiper` uses `indicator(...)`, `loop(false)`, and `onChange(...)`; `indicatorStyle` is deprecated. Reference: [Huawei ArkUI Swiper](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V5/ts-container-swiper-V5).
- WebP is supported as a HarmonyOS media resource. Reference: [Huawei resource categories](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V2/resource-categories-and-access-0000001544463977-V2).

---

## File Structure

**Create**

- `entry/src/main/ets/common/ExerciseArtworkLogic.ets` — pure preference parsing and deterministic gender selection.
- `entry/src/main/ets/components/ExerciseGuidanceCarousel.ets` — one-frame-at-a-time guidance carousel.
- `entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets` — generated resource table for approved WebP assets.
- `tools/verify_exercise_artwork_logic.mjs` — Node tests for pure logic and settings source contracts.
- `tools/verify_exercise_guidance_ui.mjs` — source-level UI contract checks.
- `tools/exercises/guidance.json` — frame plans, captions, camera notes, muscle notes, and approval state.
- `tools/exercises/guidance_prompt.mjs` — builds the final prompt for one exercise and gender.
- `tools/exercises/generate_guidance_mapping.mjs` — generates the ArkTS resource table from approved manifest entries.
- `tools/exercises/process_guidance_sheet.py` — deterministic sheet slicing and WebP conversion.
- `tools/exercises/test_process_guidance_sheet.py` — Pillow tests for 2-, 3-, and 4-frame layouts.
- `tools/exercises/verify_guidance_assets.py` — file, decode, dimension, and frame-count validation.

**Modify**

- `entry/src/main/ets/common/AppSettings.ets` — persist the model preference.
- `entry/src/main/ets/pages/MinePage.ets` — expose Auto/Female/Male selection.
- `entry/src/main/ets/model/exerciseArtwork.ets` — add new guidance lookup with legacy fallback.
- `entry/src/main/ets/components/ExerciseSheet.ets` — use selected gender for card and embedded detail.
- `entry/src/main/ets/components/ExerciseInfoView.ets` — render the carousel.
- `entry/src/main/ets/pages/DayDetailPage.ets` — load the preference once and pass it to both sheet and detail views.
- `tools/verify_catalog.mjs` — validate the six transitional WebP mappings while retaining legacy checks.
- `tools/verify_project.mjs` — require the new files and UI contracts.
- `.gitignore` — ignore `/.superpowers/` if not already ignored; `.work/` is already ignored.

---

### Task 1: Pure gender-selection logic

**Files:**

- Create: `entry/src/main/ets/common/ExerciseArtworkLogic.ets`
- Create: `tools/verify_exercise_artwork_logic.mjs`

**Interfaces:**

- Produces: `ExerciseModelPreference = 'auto' | 'female' | 'male'`
- Produces: `ExerciseModelGender = 'female' | 'male'`
- Produces: `toExerciseModelPreference(value: string): ExerciseModelPreference`
- Produces: `autoGenderForExercise(exerciseId: string): ExerciseModelGender`
- Produces: `resolveExerciseModelGender(preference: ExerciseModelPreference, exerciseId: string): ExerciseModelGender`
- Produces: `safeArtworkFrameIndex(index: number, frameCount: number): number`

- [ ] **Step 1: Write the failing Node tests**

Create a loader in `tools/verify_exercise_artwork_logic.mjs` using the same `stripTypeScriptTypes` and `runInNewContext` pattern as `tools/verify_catalog.mjs`. Add these assertions:

```javascript
assert.equal(toExerciseModelPreference('female'), 'female');
assert.equal(toExerciseModelPreference('male'), 'male');
assert.equal(toExerciseModelPreference('AUTO'), 'auto');
assert.equal(toExerciseModelPreference(''), 'auto');
assert.equal(resolveExerciseModelGender('female', 'leg_squat'), 'female');
assert.equal(resolveExerciseModelGender('male', 'leg_squat'), 'male');
assert.equal(
  resolveExerciseModelGender('auto', 'leg_squat'),
  resolveExerciseModelGender('auto', 'leg_squat')
);
assert(['female', 'male'].includes(autoGenderForExercise('chest_bb_bench')));
assert.equal(safeArtworkFrameIndex(-1, 3), 0);
assert.equal(safeArtworkFrameIndex(8, 3), 0);
assert.equal(safeArtworkFrameIndex(2, 3), 2);
assert.equal(safeArtworkFrameIndex(0, 0), 0);
```

Load `EXERCISE_CATALOG` and assert that Auto produces at least 40 female and 40 male results across the 120 built-ins.

- [ ] **Step 2: Run the test and verify RED**

Run: `node tools/verify_exercise_artwork_logic.mjs`

Expected: FAIL because `ExerciseArtworkLogic.ets` does not exist.

- [ ] **Step 3: Implement the smallest pure logic module**

Use a stable 31-based character hash without randomness:

```typescript
export type ExerciseModelPreference = 'auto' | 'female' | 'male';
export type ExerciseModelGender = 'female' | 'male';

export function toExerciseModelPreference(value: string): ExerciseModelPreference {
  if (value === 'female' || value === 'male') {
    return value;
  }
  return 'auto';
}

export function autoGenderForExercise(exerciseId: string): ExerciseModelGender {
  let hash: number = 0;
  for (let i = 0; i < exerciseId.length; i++) {
    hash = (hash * 31 + exerciseId.charCodeAt(i)) & 0x7fffffff;
  }
  return hash % 2 === 0 ? 'female' : 'male';
}

export function resolveExerciseModelGender(
  preference: ExerciseModelPreference,
  exerciseId: string
): ExerciseModelGender {
  return preference === 'auto' ? autoGenderForExercise(exerciseId) : preference;
}

export function safeArtworkFrameIndex(index: number, frameCount: number): number {
  return frameCount > 0 && index >= 0 && index < frameCount ? index : 0;
}
```

- [ ] **Step 4: Run the test and verify GREEN**

Run: `node tools/verify_exercise_artwork_logic.mjs`

Expected: PASS and print both Auto distribution counts.

- [ ] **Step 5: Commit only this task**

```powershell
git add -- entry/src/main/ets/common/ExerciseArtworkLogic.ets tools/verify_exercise_artwork_logic.mjs
git commit -m "feat: add exercise model selection logic"
```

---

### Task 2: Persist and edit the model preference

**Files:**

- Modify: `entry/src/main/ets/common/AppSettings.ets`
- Modify: `entry/src/main/ets/pages/MinePage.ets`
- Modify: `tools/verify_exercise_artwork_logic.mjs`

**Interfaces:**

- Consumes: `ExerciseModelPreference`, `toExerciseModelPreference`
- Produces: `AppSettings.loadExerciseModelPreference(): Promise<ExerciseModelPreference>`
- Produces: `AppSettings.saveExerciseModelPreference(preference: ExerciseModelPreference): Promise<void>`

- [ ] **Step 1: Add failing source-contract assertions**

Read both ArkTS files in `tools/verify_exercise_artwork_logic.mjs` and assert:

```javascript
assert(appSettings.includes("const KEY_EXERCISE_MODEL_GENDER: string = 'exercise_model_gender'"));
assert(appSettings.includes('loadExerciseModelPreference'));
assert(appSettings.includes('saveExerciseModelPreference'));
assert(minePage.includes("Text('动作模特')"));
assert(minePage.includes("'自动混合'"));
assert(minePage.includes("'女性模特'"));
assert(minePage.includes("'男性模特'"));
```

- [ ] **Step 2: Run and verify RED**

Run: `node tools/verify_exercise_artwork_logic.mjs`

Expected: FAIL on the missing preference key.

- [ ] **Step 3: Implement Preferences storage**

Add imports from `ExerciseArtworkLogic.ets`, the exact key above, and:

```typescript
static async loadExerciseModelPreference(): Promise<ExerciseModelPreference> {
  if (AppSettings.store === null) {
    return 'auto';
  }
  const value: preferences.ValueType = await AppSettings.prefs().get(
    KEY_EXERCISE_MODEL_GENDER,
    'auto'
  );
  return typeof value === 'string' ? toExerciseModelPreference(value) : 'auto';
}

static async saveExerciseModelPreference(preference: ExerciseModelPreference): Promise<void> {
  if (AppSettings.store === null) {
    return;
  }
  await AppSettings.prefs().put(KEY_EXERCISE_MODEL_GENDER, preference);
  await AppSettings.prefs().flush();
}
```

- [ ] **Step 4: Add the Mine-page control**

Add `@State exerciseModelPreference: ExerciseModelPreference = 'auto'`, load it in `load()`, and add a private setter that updates state only after preserving the previous value for rollback on save failure. Render three equal-width choices using the existing light/dark segmented-control visual pattern, with labels `自动混合`, `女性模特`, and `男性模特`.

- [ ] **Step 5: Run and verify GREEN**

Run: `node tools/verify_exercise_artwork_logic.mjs`

Expected: PASS.

- [ ] **Step 6: Commit only the settings change**

```powershell
git add -- entry/src/main/ets/common/AppSettings.ets entry/src/main/ets/pages/MinePage.ets tools/verify_exercise_artwork_logic.mjs
git commit -m "feat: add exercise model preference"
```

---

### Task 3: Guidance manifest, prompt builder, sheet processor, and mapping generator

**Files:**

- Create: `tools/exercises/guidance.json`
- Create: `tools/exercises/guidance_prompt.mjs`
- Create: `tools/exercises/process_guidance_sheet.py`
- Create: `tools/exercises/test_process_guidance_sheet.py`
- Create: `tools/exercises/verify_guidance_assets.py`
- Create: `tools/exercises/generate_guidance_mapping.mjs`
- Create: `entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets`

**Interfaces:**

- `guidance.json` entries: `id`, `frameCount`, `layout`, `captions`, `cardFrameIndex`, `view`, `equipmentNotes`, `muscleNotes`, `status`
- `layout`: `horizontal-2 | horizontal-3 | grid-4`
- `status`: `planned | approved`
- `process_guidance_sheet.py --manifest PATH --sheet-root DIR --out-dir DIR [--part PART] [--contact-sheet DIR]`
- `verify_guidance_assets.py --manifest PATH --media DIR [--require-all] [--part PART]`
- `generate_guidance_mapping.mjs --manifest PATH --media DIR --out PATH`

- [ ] **Step 1: Write failing Pillow tests for exact crops**

In `test_process_guidance_sheet.py`, create synthetic 1536×1024 PNGs in `tempfile.TemporaryDirectory()`:

```python
def test_horizontal_2_splits_equal_columns(self):
    image = Image.new("RGB", (1536, 1024))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, 767, 1023), fill="red")
    draw.rectangle((768, 0, 1535, 1023), fill="blue")
    # process -> two WebP files, both 768x1024, center pixels red and blue

def test_horizontal_3_splits_equal_columns(self):
    # three 512x1024 color bands -> three WebP files

def test_grid_4_splits_quadrants_in_reading_order(self):
    # four 768x512 quadrants -> 01 top-left, 02 top-right, 03 bottom-left, 04 bottom-right

def test_contact_sheet_keeps_frame_order_at_320_px(self):
    # process two synthetic frames -> one preview with two 320px-wide panels in order
```

Also assert output names exactly match `ex_leg_squat_female_01.webp` and WebP format is reported by Pillow.

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -m unittest tools.exercises.test_process_guidance_sheet -v
```

Expected: FAIL because `process_guidance_sheet.py` is missing.

- [ ] **Step 3: Implement deterministic slicing and WebP output**

Expose testable `frame_boxes`, `process_sheet`, `process_manifest`, and `build_contact_sheet` functions. The core crop logic is:

```python
def frame_boxes(width: int, height: int, layout: str) -> list[tuple[int, int, int, int]]:
    if layout == "horizontal-2":
        return [(0, 0, width // 2, height), (width // 2, 0, width, height)]
    if layout == "horizontal-3":
        one = width // 3
        return [(0, 0, one, height), (one, 0, one * 2, height), (one * 2, 0, width, height)]
    if layout == "grid-4":
        half_w, half_h = width // 2, height // 2
        return [(0, 0, half_w, half_h), (half_w, 0, width, half_h),
                (0, half_h, half_w, height), (half_w, half_h, width, height)]
    raise ValueError(f"unsupported layout: {layout}")
```

Reject dimensions that cannot split cleanly for the selected layout. Save RGB WebP with `quality=82`, `method=6`, and no EXIF metadata. `process_manifest` must use the manifest's literal ID, gender, layout, and expected sheet paths rather than discovering arbitrary files:

```python
def process_manifest(manifest_path: Path, sheet_root: Path, out_dir: Path,
                     part: str | None = None) -> list[Path]:
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))["exercises"]
    outputs: list[Path] = []
    for entry in entries:
        if part is not None and entry["partKey"] != part:
            continue
        for gender in ("female", "male"):
            sheet = sheet_root / entry["id"] / f"{gender}-sheet.png"
            outputs.extend(process_sheet(sheet, entry["id"], gender,
                                         entry["layout"], out_dir))
    return outputs
```

Wire argparse for the exact documented options. When `--contact-sheet DIR` is supplied, write previews to that directory without changing the production WebP files.

- [ ] **Step 4: Run and verify GREEN**

Run the unittest command from Step 2.

Expected: 4 tests PASS.

- [ ] **Step 5: Create the six-entry manifest**

Use these exact plans:

| ID | Frames | Layout | Captions | Card frame |
| --- | ---: | --- | --- | ---: |
| `chest_bb_bench` | 3 | `horizontal-3` | 稳定起始；控制下放；推起结束 | 1 |
| `leg_squat` | 3 | `horizontal-3` | 站立起始；控制下蹲；底部换向 | 2 |
| `back_deadlift` | 3 | `horizontal-3` | 地面起始；贴身拉起；站立锁定 | 1 |
| `shoulder_arnold` | 3 | `horizontal-3` | 掌心相对起始；旋转推起；头顶结束 | 1 |
| `core_bird_dog` | 2 | `horizontal-2` | 四点支撑；对侧伸展 | 1 |
| `cardio_burpee` | 4 | `grid-4` | 下蹲撑地；后跳成平板；收腿回蹲；向上跳起 | 3 |

Set every initial `status` to `planned`.

- [ ] **Step 6: Implement and test the prompt builder**

`guidance_prompt.mjs` must load `curated.json`, join the manifest entry by ID, and print the final `scientific-educational` prompt. It must include the selected gender, exact captions as stage semantics, full-body/equipment constraints, target muscle notes, consistent identity/camera/lighting, neutral background, and the shared avoid list.

For a single exercise/gender it must print JSON containing `id`, `gender`, `sheetPath`, and `prompt`; `sheetPath` must be the exact `.work/exercise-guidance/<catalog ID>/<female or male>-sheet.png` destination. Add `--jobs --part chest` support that prints one JSON line per planned gender job for the requested part.

Add a `--check` mode that verifies all six prompts contain `no text`, `no watermark`, the gender, layout, and every caption. Run:

```powershell
node tools/exercises/guidance_prompt.mjs --check
node tools/exercises/guidance_prompt.mjs leg_squat female
```

Expected: check PASS; the second command prints one complete prompt.

- [ ] **Step 7: Implement manifest/resource validation and mapping generation**

`verify_guidance_assets.py` must reject duplicate IDs, invalid layouts, caption-count mismatches, out-of-range card indices, missing female/male files for `approved` entries, undecodable WebP, or dimensions below 384×384.

`generate_guidance_mapping.mjs` must emit explicit resource calls such as `$r('app.media.ex_leg_squat_female_01')` only for `approved` entries and begin with:

```typescript
export interface GeneratedGuidanceArtwork {
  id: string;
  femaleFrames: Resource[];
  maleFrames: Resource[];
  frameCaptions: string[];
  cardFrameIndex: number;
}
```

With all six entries still planned, generate an empty array and verify it imports structurally.

- [ ] **Step 8: Commit tooling and manifest**

```powershell
git add -- tools/exercises/guidance.json tools/exercises/guidance_prompt.mjs tools/exercises/process_guidance_sheet.py tools/exercises/test_process_guidance_sheet.py tools/exercises/verify_guidance_assets.py tools/exercises/generate_guidance_mapping.mjs entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets
git commit -m "feat: add exercise guidance asset pipeline"
```

---

### Task 4: Generate and approve the six representative exercises

**Files:**

- Modify: `tools/exercises/guidance.json`
- Create: `entry/src/main/resources/base/media/ex_{quality-gate ids}_{female|male}_{01..04}.webp`
- Regenerate: `entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets`

**Interfaces:**

- Consumes: prompt builder, built-in ImageGen, sheet processor, validator, mapping generator
- Produces: 36 WebP files: `(3 + 3 + 3 + 3 + 2 + 4) × 2`

- [ ] **Step 1: Verify the quality-gate is initially incomplete**

Run:

```powershell
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/verify_guidance_assets.py --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media
```

Expected: PASS for planned entries but report `approved=0, planned=6`.

- [ ] **Step 2: Generate exactly 12 mother sheets with built-in ImageGen**

For each ID in this exact order—`chest_bb_bench`, `leg_squat`, `back_deadlift`, `shoulder_arnold`, `core_bird_dog`, `cardio_burpee`—run the prompt builder once for `female` and once for `male`, then pass each printed prompt unchanged to one built-in ImageGen call.

Copy each returned image from its reported `$CODEX_HOME/generated_images/...` path to these exact destinations:

```text
.work/exercise-guidance/chest_bb_bench/female-sheet.png
.work/exercise-guidance/chest_bb_bench/male-sheet.png
.work/exercise-guidance/leg_squat/female-sheet.png
.work/exercise-guidance/leg_squat/male-sheet.png
.work/exercise-guidance/back_deadlift/female-sheet.png
.work/exercise-guidance/back_deadlift/male-sheet.png
.work/exercise-guidance/shoulder_arnold/female-sheet.png
.work/exercise-guidance/shoulder_arnold/male-sheet.png
.work/exercise-guidance/core_bird_dog/female-sheet.png
.work/exercise-guidance/core_bird_dog/male-sheet.png
.work/exercise-guidance/cardio_burpee/female-sheet.png
.work/exercise-guidance/cardio_burpee/male-sheet.png
```

Do not use one call to generate distinct exercises and do not use CLI fallback.

- [ ] **Step 3: Inspect every mother sheet before slicing**

Use `view_image` on all 12 sheets. Check stage order, full-body/equipment framing, anatomy, grips, contact points, target muscles, consistent person/clothes/equipment, and absence of text/watermarks. Regenerate only the failing sheet with one targeted prompt change.

- [ ] **Step 4: Slice approved sheets**

Process all 12 sheets from the six-entry manifest in one deterministic run:

```powershell
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/process_guidance_sheet.py --manifest tools/exercises/guidance.json --sheet-root .work/exercise-guidance --out-dir entry/src/main/resources/base/media
```

Expected: 36 WebP resources with exact names.

- [ ] **Step 5: Inspect mobile-size contact sheets**

Extend `process_guidance_sheet.py` with `--contact-sheet` to compose the final frames at 320 px per frame without changing the production files. Save previews under `.work/exercise-guidance/contact-sheets/` and inspect all six gender pairs with `view_image`.

- [ ] **Step 6: Mark only accepted entries approved**

Change each passing manifest entry from `planned` to `approved`, run the validator, then regenerate the mapping:

```powershell
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/verify_guidance_assets.py --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media
node tools/exercises/generate_guidance_mapping.mjs --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media --out entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets
```

Expected: `approved=6, planned=0, frames=36`; generated ArkTS has six entries.

- [ ] **Step 7: Commit accepted assets and metadata only**

```powershell
git add -- tools/exercises/guidance.json entry/src/main/ets/model/exerciseGuidanceArtwork.generated.ets entry/src/main/resources/base/media/ex_chest_bb_bench_*.webp entry/src/main/resources/base/media/ex_leg_squat_*.webp entry/src/main/resources/base/media/ex_back_deadlift_*.webp entry/src/main/resources/base/media/ex_shoulder_arnold_*.webp entry/src/main/resources/base/media/ex_core_bird_dog_*.webp entry/src/main/resources/base/media/ex_cardio_burpee_*.webp
git commit -m "feat: add representative exercise guidance artwork"
```

---

### Task 5: Transitional artwork model with legacy fallback

**Files:**

- Modify: `entry/src/main/ets/model/exerciseArtwork.ets`
- Modify: `tools/verify_catalog.mjs`

**Interfaces:**

- Consumes: `GENERATED_GUIDANCE_ARTWORK`, `resolveExerciseModelGender`, `safeArtworkFrameIndex`
- Produces: `guidanceArtworkOf(exerciseId: string): GeneratedGuidanceArtwork | null`
- Produces: `guidanceFramesOf(exerciseId: string, partKey: PartKey, preference: ExerciseModelPreference): Resource[]`
- Produces: `guidanceCaptionsOf(exerciseId: string): string[]`
- Produces: `cardImageOf(exerciseId: string, partKey: PartKey, preference?: ExerciseModelPreference): Resource`

- [ ] **Step 1: Extend catalog verification and verify RED**

Load `exerciseArtwork.ets` with dependencies for `$r`, generated guidance entries, and selection logic. Assert:

```javascript
assert.equal(guidanceFramesOf('leg_squat', 'leg', 'female').length, 3);
assert.equal(guidanceFramesOf('leg_squat', 'leg', 'male').length, 3);
assert.deepEqual(guidanceCaptionsOf('core_bird_dog'), ['四点支撑', '对侧伸展']);
assert.equal(guidanceFramesOf('chest_db_bench', 'chest', 'female').length, 2);
assert.equal(guidanceCaptionsOf('chest_db_bench').length, 2);
assert(cardImageOf('leg_squat', 'leg', 'female').includes('female_03'));
assert(cardImageOf('usr_1', 'leg', 'female').includes('part_leg'));
```

Run: `node tools/verify_catalog.mjs`

Expected: FAIL because `guidanceFramesOf` is missing.

- [ ] **Step 2: Implement lookup and fallback**

For approved guidance entries, choose `femaleFrames` or `maleFrames`. For legacy built-ins, return `[start, end]` with captions `['起始', '结束']`. For custom/missing actions, return `[partFallback(partKey)]` with caption `['动作示意']`. Keep the original `ExerciseArtwork` table until the rollout plan removes it.

- [ ] **Step 3: Run and verify GREEN**

Run: `node tools/verify_catalog.mjs`

Expected: PASS for six WebP entries and all 120 legacy entries.

- [ ] **Step 4: Commit model integration**

```powershell
git add -- entry/src/main/ets/model/exerciseArtwork.ets tools/verify_catalog.mjs
git commit -m "feat: add variable-frame guidance artwork lookup"
```

---

### Task 6: Guidance carousel and component integration

**Files:**

- Create: `entry/src/main/ets/components/ExerciseGuidanceCarousel.ets`
- Modify: `entry/src/main/ets/components/ExerciseInfoView.ets`
- Modify: `entry/src/main/ets/components/ExerciseSheet.ets`
- Modify: `entry/src/main/ets/pages/DayDetailPage.ets`
- Create: `tools/verify_exercise_guidance_ui.mjs`
- Modify: `tools/verify_project.mjs`

**Interfaces:**

- `ExerciseGuidanceCarousel`: props `frames: Resource[]`, `captions: string[]`
- `ExerciseInfoView`: optional prop `modelPreference: ExerciseModelPreference = 'auto'`
- `ExerciseSheet`: receives one `ExerciseModelPreference` and passes it to card and detail lookups
- `DayDetailPage`: loads one `ExerciseModelPreference` and passes it to every `ExerciseSheet` and `ExerciseInfoView` instance

- [ ] **Step 1: Write failing UI contract checks**

In `verify_exercise_guidance_ui.mjs`, read the three component files and assert:

```javascript
assert(carousel.includes('export struct ExerciseGuidanceCarousel'));
assert(carousel.includes('Swiper()'));
assert(carousel.includes('.loop(false)'));
assert(carousel.includes('.indicator('));
assert(carousel.includes('.onChange((index: number)'));
assert(carousel.includes("Text('第 '"));
assert(info.includes('ExerciseGuidanceCarousel'));
assert(!info.includes("Text('起始')"));
assert(!info.includes("Text('结束')"));
assert(sheet.includes('modelPreference'));
assert(dayDetail.includes('loadExerciseModelPreference'));
assert(dayDetail.includes('modelPreference: this.exerciseModelPreference'));
```

- [ ] **Step 2: Run and verify RED**

Run: `node tools/verify_exercise_guidance_ui.mjs`

Expected: FAIL because the carousel file is missing.

- [ ] **Step 3: Implement the isolated carousel**

Use a single-page `Swiper`, keep the index in component state, render every frame with `ImageFit.Contain`, and show the matching caption and `第 N / M 步`. Required structure:

```typescript
@Component
export struct ExerciseGuidanceCarousel {
  @Prop frames: Resource[] = [];
  @Prop captions: string[] = [];
  @State currentIndex: number = 0;

  build() {
    Column({ space: 8 }) {
      Swiper() {
        ForEach(this.frames, (frame: Resource, index: number) => {
          Image(frame)
            .width('100%')
            .height(280)
            .objectFit(ImageFit.Contain)
            .accessibilityText(this.captions[index] || '动作示意')
        }, (_frame: Resource, index: number) => `${index}`)
      }
      .loop(false)
      .indicator(this.frames.length > 1)
      .onChange((index: number) => { this.currentIndex = index; })

      Text('第 ' + (this.currentIndex + 1) + ' / ' + this.frames.length + ' 步')
      Text(this.captions[this.currentIndex] || '动作示意')
    }
  }
}
```

Clamp/reset `currentIndex` when the exercise changes so an index from a 4-frame action cannot address a 2-frame action.

- [ ] **Step 4: Integrate preference loading and carousel use**

`DayDetailPage` adds `@State exerciseModelPreference: ExerciseModelPreference = 'auto'`, loads it from `AppSettings` during page appearance, and passes it to both `ExerciseSheet` and its direct `ExerciseInfoView`. `ExerciseSheet` passes the same prop into its embedded `ExerciseInfoView`. Replace the old two-column image row with the carousel and keep all textual detail sections below it.

- [ ] **Step 5: Run and verify GREEN**

Run:

```powershell
node tools/verify_exercise_guidance_ui.mjs
node tools/verify_catalog.mjs
node tools/verify_project.mjs
```

Expected: all three PASS.

- [ ] **Step 6: Commit the UI slice**

```powershell
git add -- entry/src/main/ets/components/ExerciseGuidanceCarousel.ets entry/src/main/ets/components/ExerciseInfoView.ets entry/src/main/ets/components/ExerciseSheet.ets entry/src/main/ets/pages/DayDetailPage.ets tools/verify_exercise_guidance_ui.mjs tools/verify_project.mjs
git commit -m "feat: show exercise guidance as a carousel"
```

---

### Task 7: Foundation verification and quality-gate review

**Files:**

- Modify only if checks expose a defect in files from Tasks 1–6.

**Interfaces:**

- Produces: a documented go/no-go result for full catalog rollout.

- [ ] **Step 1: Run the full Node verification suite**

```powershell
node tools/verify_project.mjs
node tools/verify_v1_logic.mjs
node tools/verify_calendar.mjs
node tools/verify_catalog.mjs
node tools/verify_categories.mjs
node tools/verify_editing.mjs
node tools/verify_workout_modes.mjs
node tools/verify_muscle.mjs
node tools/verify_scene.mjs
node tools/verify_batch_add.mjs
node tools/verify_trend_logic.mjs
node tools/verify_trend_guide.mjs
node tools/verify_exercise_artwork_logic.mjs
node tools/verify_exercise_guidance_ui.mjs
```

Expected: every command exits 0.

- [ ] **Step 2: Run Pillow and asset verification**

```powershell
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -m unittest tools.exercises.test_process_guidance_sheet -v
& 'C:\Users\26017\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/exercises/verify_guidance_assets.py --manifest tools/exercises/guidance.json --media entry/src/main/resources/base/media
```

Expected: tests PASS and asset report is `approved=6, planned=0, frames=36`.

- [ ] **Step 3: Build the HAP**

In DevEco Studio, open the project and select `Build > Build Hap(s)/APP(s) > Build Hap(s)` for the `entry` module.

Expected: `hvigor BUILD SUCCESSFUL`; pre-existing deprecation warnings may remain, but no new error or warning may reference the new artwork files.

- [ ] **Step 4: Perform the UI quality gate on a device or emulator**

Verify all six actions in light and dark themes. For each action, test Auto/Female/Male, card/detail consistency, every swipe, indicator, `第 N / M 步`, caption sync, and full-body/equipment visibility. Record failures by exercise ID and gender; regenerate only the failing mother sheet, then repeat Steps 1–4.

- [ ] **Step 5: Confirm the quality-gate state**

Run `git status --short` and verify no uncommitted file from Tasks 1–6 remains. If a defect required a correction, return to that task's named file list, repeat its tests, and use that task's exact scoped commit command. Full-catalog rollout begins only when the worktree is clean for all files owned by this plan.
