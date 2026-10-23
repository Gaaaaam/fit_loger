# 训练部位分类图片升级 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the picker’s nine SVG illustrations with consistent, transparent, realistic 3D muscle illustrations.

**Architecture:** Generate nine independent raster assets using the built-in imagegen tool and existing exercise-guidance images as style references. Export 640 × 480 WebP with alpha, then change only BODY_PARTS image resources. Existing partFallback resources remain independent.

**Tech Stack:** ArkTS resource mapping, built-in imagegen, Sharp for deterministic resizing/encoding and preview rendering, existing Node verification scripts.

**Spec:** User-approved plan in this chat (2026-10-23): nine neutral models, cool gray body, green target muscles, transparent background, existing two-column layout and labels.

## Global Constraints

- Files: `part_<key>_v2.webp`, 640 × 480, alpha preserved; no text in images.
- Keys: chest, shoulder, back, arm, glute, leg, abs, core, cardio.
- Abdomen emphasizes rectus abdominis; core emphasizes obliques and lateral trunk stability.
- No changes to model-gender preferences, picker interaction, old SVG fallback, or pre-existing user edits.
- Work in the current checkout: guidance reference images and pending related changes are already here. No commits or branch operations are required for this asset update.

## Review Focus

- Recognizable muscle regions at 100-pixel display height.
- True alpha with clean edges on both theme backgrounds.
- Distinguishable abdomen/core composition and emphasis.
- Nine unique valid resources with unchanged persisted keys.
- Existing custom-exercise artwork fallback remains available.

## Task 1: Generate and inspect assets

- [x] Generate chest, abs, core first and inspect anatomy, lighting, scale, and alpha.
- [x] Generate shoulder, back, arm, glute, leg, cardio with the accepted chest image as a consistency reference.
- [x] Export WebP assets and save exact prompts and source provenance in `tools/artwork/body_parts_v2.json`.

## Task 2: Integrate and verify

- [x] Update category resource checks to require v2 WebP; observe expected failure before mapping replacement.
- [x] Update BODY_PARTS mapping; retain existing SVG fallback resources.
- [x] Update preview renderer and HTML for v2 images, labels, descriptions, and both themes at actual picker dimensions.
- [x] Run category check, WebP decode/alpha/dimension checks, relevant existing checks, project check, and visual review.

## Baseline and rulings

- Category check passes before changes.
- Project check has a pre-existing signing-password configuration failure; do not change signing as part of this task.
- Ruling: Reuse the current checkout instead of a new worktree because the approved style references and pending guidance changes are uncommitted here; touching only the approved mapping, verification, preview, and new assets preserves the user’s active work.
- Ruling: Asset replacement is reversible and adds no app behavior; use existing meaningful resource/category checks and image inspection rather than adding implementation-mirroring tests.

## Progress

- Approved plan recorded; existing picker and shared fallback consumers inspected.
- All nine assets generated with built-in imagegen; total 243,152 bytes (237.5 KiB).
- Nine WebP files decoded successfully: 640 × 480, real alpha spanning 0–255. Exact prompts and original paths are in the manifest.
- RED: category verification rejected old `part_chest` mapping. GREEN: updated category verification passes for all nine v2 resources and retained SVG fallback files.
- Preview renderer now writes versioned `preview-v2*.png` and `preview-v2.html`, keeping the old comparison previews. Native sandbox writes to the preview directory were denied; the same authorized rendering command succeeded with sandbox escalation.
- Inspected `preview-v2-themes.png`: all nine cards readable at 100-pixel image height on both themes, abdomen/core distinct, no background rectangles.
- Full static suite at this point: 10 of 14 checks pass. Concurrent unrelated cardio edits caused failures in `verify_cardio_persistence.mjs` and `verify_workout_modes.mjs` (test loader lacks CARDIO_SELECT), `verify_catalog.mjs` (new cardio_treadmill SVG missing), and `verify_project.mjs` (expects schema v3). This task did not edit the repository, schema, catalog, or those test loaders.
- Existing `RecordType` additions in types.ets belong to concurrent work; only BODY_PARTS image values were changed by this task.
- No device or HarmonyOS build tool was available on PATH; native-device interaction was not exercised. BodyPartSheet interaction code is unchanged.
- Independent read-only review: clean approval; all nine resources and both preview themes inspected, no actionable findings. Concurrent cardio changes excluded from the review. No deferred artwork issues.
- Final rerun: 11 of 14 checks pass. `verify_cardio_persistence.mjs` now passes as concurrent work progresses. Remaining unrelated failures: `verify_catalog.mjs` (missing cardio_treadmill card SVG), `verify_project.mjs` (schema-v3 assertion), `verify_workout_modes.mjs` (CARDIO_SELECT test-loader reference). Category artwork verification remains green.
