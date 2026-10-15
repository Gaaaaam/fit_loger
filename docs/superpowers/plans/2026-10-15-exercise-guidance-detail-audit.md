# Exercise Guidance Detail Audit and Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inspect all 120 existing actions, both genders and all 590 packaged frames, publish an evidence-backed defect checklist, and repair every confirmed instructional error.

**Architecture:** Freeze the actual production WebPs at baseline `61e39bc`, audit them against catalog semantics, and maintain explicit per-action/gender coverage. Independent read-only auditors cover disjoint body parts; one implementer at a time repairs confirmed mother sheets, slices only affected genders, and submits the result for independent visual review.

**Tech Stack:** Built-in ImageGen, Python 3.12/Pillow/WebP, Node.js verification, existing ArkTS resource mapping.

**Spec:** `docs/superpowers/specs/2026-09-15-exercise-guidance-artwork-design.md`; user-requested full fine-detail re-audit, including the seated-curl pad/leg occlusion defect.

**Approval and current gate:** The user approved the full audit-and-repair plan. Task 1 is complete: 120 actions, 240 groups and590 production frames; baseline204 PASS /30 DEFECT /6 UNCERTAIN. Task2 is in progress: male DB-row02 independently accepted at`0ce998d`, one confirmed group closed and29 remain open; six uncertainties retained. Other589 production hashes remain baseline-identical. Task3 final regression has not started; this is not whole-goal completion.

## Global Constraints

- Audit exactly 120 actions, 240 action/gender groups and 590 current production frames; no sampling-only completion claim.
- Production WebPs, not possibly divergent candidate mother sheets, are the audit authority.
- Use built-in ImageGen only. Stop generation on 429; no CLI/API substitution.
- Preserve all prior versions and unrelated work. Do not remove legacy SVGs, change signing files, merge, publish, or deploy.
- Preserve approved gray training clothes, natural proportions, flat project-green muscle tint, neutral background, and no in-image text/arrows/logos.
- Keep existing frame counts, captions, card indices and resource names unless a verified semantic defect requires a documented change.
- Inspect native-resolution frame details and cross-stage continuity, then inspect decoded production frames at 320px/panel after each repair.
- Only regenerate failing action/gender sources and only recut their declared frames.
- File integrity tests do not establish anatomical or instructional correctness.

## Review Focus

- Near/far limbs: trace each hip-knee-ankle or shoulder-elbow-wrist chain and ensure a pad/bar does not pass between limbs incorrectly.
- Load/contact: verify both intended feet, hands, back, thighs and ankles contact their actual supports without penetration or floating.
- Apparatus continuity: trace cable-to-handle and pivot-to-lever-to-pad paths across every stage, including stack movement when exposed.
- Instruction semantics: compare grip, laterality, phase order and range of motion to catalog and manifest, with primary references for uncertainty.
- False acceptance: a correct silhouette, 320px thumbnail, or passing asset verifier must not conceal contradictory full-size mechanics.

## Files and responsibilities

- `docs/superpowers/reviews/2026-10-15-exercise-guidance-detail-audit.md`: human-readable defect checklist, evidence and repair state.
- `.superpowers/sdd/2026-10-15-exercise-guidance-detail-audit/`: progress, immutable baseline inventory, audit coverage and independent reports.
- `.work/exercise-guidance/detail-audit-2026-10-15/`: views decoded from actual packaged WebPs; no generated substitute pixels.
- Existing `.work/exercise-guidance/<id>/`: retained mother originals and versioned repair candidates.
- `entry/src/main/resources/base/media/ex_<id>_<gender>_<nn>.webp`: only accepted affected production frames.

### Task 1: Full read-only audit and explicit defect checklist

**Files:** Create the baseline inventory, three disjoint auditor reports, root audit report, and the human-readable checklist above.

**Interfaces:** Consumes `guidance.json`, `curated.json`, and all declared production WebPs. Produces one coverage row per action/gender, with `PASS`, `DEFECT`, or `UNCERTAIN`, exact inspected frame numbers, source hashes, and concrete observations.

- [x] Freeze SHA-256/dimensions/captions for all 590 files; assert 120 unique IDs, 240 groups, and exact declared-file coverage.
- [x] Compare deterministic canonical mother crops with packaged bytes and record divergence instead of silently auditing the wrong source.
- [x] Audit chest/shoulder, back/arm, and leg/glute in disjoint read-only agent groups; root audits abs/core/cardio.
- [x] Inspect every frame at native resolution and compare stages; record contact/grip/limb/gear observations for every group, even when passing.
- [x] Resolve uncertain observations by native detail inspection and primary instructional references; retain unresolved uncertainty explicitly.
- [x] Publish every confirmed defect with action, gender, frames, exact failure, evidence, severity, and open repair status. Include both seated-curl second frames.
- [x] Verify coverage has 240 unique reviewed groups, 590 inspected frame references, and no unreviewed group. Commit the checklist without changing production assets.

### Task 2: Repair confirmed instructional defects

**Files:** Modify only failing mother candidates and their production WebPs; update checklist and repair reports. Change manifest/mapping only if an actual semantic correction requires it.

**Interfaces:** Consumes Task 1 confirmed defect rows. Produces accepted source hashes, actual production hashes, and independent per-finding verdicts.

- [ ] Start with the seated-curl pair: preserve thigh restraint and fixed machine geometry; both distal calves/Achilles must contact the same roller on its correct side throughout the curl, without the roller threading between legs.
- [ ] For each failing gender, save a versioned original, record a single targeted edit prompt, and use built-in ImageGen on the inspected local target.
- [ ] Inspect the entire candidate and all stages, not only the changed region; reject new grip, limb, contact, lever or cropping errors.
- [ ] Slice only that accepted action/gender with existing `process_sheet`; independently inspect every decoded replacement at native and 320px sizes.
- [ ] Re-review each defect as addressed/not-addressed with evidence; keep the same implementer for scoped fix rounds and escalate after repeated failures.
- [ ] Verify all untouched baseline production hashes remain identical and commit only accepted fixes plus their checklist updates.

### Task 3: Final coverage and regression gate

**Files:** Final checklist, coverage and review reports; production changes only if the final review exposes a remaining defect.

**Interfaces:** Consumes complete Task 1 coverage and Task 2 repair verdicts. Produces a zero-open-confirmed-defect report or an explicit truthful unresolved list.

- [ ] Assert all 240 groups/590 frames have recorded inspection evidence and every confirmed defect has independent closure; no uncertain row is counted as passed.
- [ ] Run `node tools/exercises/guidance_prompt.mjs --check --require-all`, asset verifier `--require-all`, Python processor tests, all 14 project Node checks, and `git diff --check`.
- [ ] Reconcile exact changed-resource scope and unchanged hashes against baseline; execute actual generated mapping to verify 120 IDs and frame/card selection for all preferences.
- [ ] Obtain a fresh whole-change review of checklist completeness, corrected mechanics, actual replacement WebPs and regressions; resolve findings before completion.
- [ ] Report real completed coverage, fixed defects, remaining limitations and exact saved paths. Do not imply a new HAP/device verification.
