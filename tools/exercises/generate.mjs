import { mkdirSync, writeFileSync, readdirSync, unlinkSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { EXERCISES, SOURCE } from './data.mjs';
import { renderExerciseSvg } from './svg.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '../..');
const media = join(root, 'entry/src/main/resources/base/media');
const model = join(root, 'entry/src/main/ets/model');
const raw = join(root, 'entry/src/main/resources/rawfile/exercises');
const toolsOut = join(root, 'tools/exercises');

const PARTS = ['chest', 'shoulder', 'back', 'arm', 'glute', 'leg', 'abs', 'core', 'cardio'];
const EQUIPMENT = ['barbell', 'dumbbell', 'machine', 'cable', 'bodyweight', 'band', 'kettlebell', 'ezbar', 'other'];
const PATTERNS = ['push', 'pull', 'hinge', 'squat', 'lunge', 'carry', 'isolation'];
const EXISTING_IDS = [
  'chest_bb_bench', 'chest_db_bench', 'chest_incline_bench', 'chest_fly', 'chest_cable_crossover', 'chest_dip', 'chest_pushup',
  'shoulder_bb_press', 'shoulder_db_press', 'shoulder_lateral_raise', 'shoulder_front_raise', 'shoulder_reverse_fly', 'shoulder_face_pull',
  'back_pullup', 'back_lat_pulldown', 'back_bb_row', 'back_db_row', 'back_seated_row', 'back_deadlift',
  'arm_bb_curl', 'arm_db_curl', 'arm_hammer_curl', 'arm_pushdown', 'arm_skull_crusher',
  'glute_hip_thrust', 'glute_rdl', 'glute_bridge', 'glute_abduction',
  'leg_squat', 'leg_press', 'leg_extension', 'leg_curl', 'leg_lunge', 'leg_calf_raise',
  'abs_crunch', 'abs_reverse_crunch', 'abs_leg_raise',
  'core_dead_bug', 'core_bird_dog', 'core_shoulder_tap',
  'cardio_jump_rope', 'cardio_jumping_jack'
];

function fail(message) {
  throw new Error(message);
}

function q(text) {
  return `'${String(text).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
}

function qArr(items) {
  return `[${items.map(q).join(', ')}]`;
}

function validate() {
  if (EXERCISES.length < 100 || EXERCISES.length > 150) {
    fail(`catalog size ${EXERCISES.length} not in 100-150`);
  }
  const ids = EXERCISES.map((item) => item.id);
  if (new Set(ids).size !== ids.length) {
    fail('duplicate exercise ids');
  }
  for (const id of EXISTING_IDS) {
    if (!ids.includes(id)) {
      fail(`missing existing id ${id}`);
    }
  }
  const names = new Map();
  for (const item of EXERCISES) {
    if (!PARTS.includes(item.partKey)) fail(`bad part ${item.id}`);
    if (!EQUIPMENT.includes(item.equipment)) fail(`bad equipment ${item.id}`);
    if (!PATTERNS.includes(item.movementPattern)) fail(`bad pattern ${item.id}`);
    if (!item.name || !item.englishName) fail(`missing names ${item.id}`);
    if (!item.startPosition || item.steps.length < 2 || item.cues.length < 1 || !item.counting) {
      fail(`incomplete copy ${item.id}`);
    }
    if (!item.pose || !item.pose.family) fail(`missing pose ${item.id}`);
    const key = `${item.partKey}:${item.name}`;
    if (names.has(key)) fail(`duplicate name ${item.name}`);
    names.set(key, item.id);
  }
  for (const part of PARTS) {
    if (!EXERCISES.some((item) => item.partKey === part)) fail(`missing part ${part}`);
  }
}

function catalogEts() {
  const rows = EXERCISES.map((item) => {
    const aliases = item.aliases.join(',');
    return `  { id: ${q(item.id)}, partKey: ${q(item.partKey)}, name: ${q(item.name)}, equipment: ${q(item.equipment)}, ` +
      `movementPattern: ${q(item.movementPattern)}, weightStep: ${item.weightStep}, isBodyweight: ${item.isBodyweight}, ` +
      `isUnilateral: ${item.isUnilateral}, aliases: ${q(aliases)}, primaryMuscles: ${q(item.primaryMuscles)}, ` +
      `secondaryMuscles: ${q(item.secondaryMuscles)} }`;
  });
  return `import { Equipment, MovementPattern, PartKey } from './types';

export interface ExerciseDef {
  id: string;
  partKey: PartKey;
  name: string;
  equipment: Equipment;
  movementPattern: MovementPattern;
  weightStep: number;
  isBodyweight: number;
  isUnilateral: number;
  aliases: string;
  primaryMuscles: string;
  secondaryMuscles: string;
}

export const EXERCISE_CATALOG: ExerciseDef[] = [
${rows.join(',\n')}
];

export function exercisesOf(partKey: PartKey): ExerciseDef[] {
  const result: ExerciseDef[] = [];
  for (let i = 0; i < EXERCISE_CATALOG.length; i++) {
    if (EXERCISE_CATALOG[i].partKey === partKey) {
      result.push(EXERCISE_CATALOG[i]);
    }
  }
  return result;
}

export function exerciseName(exerciseId: string): string {
  for (let i = 0; i < EXERCISE_CATALOG.length; i++) {
    if (EXERCISE_CATALOG[i].id === exerciseId) {
      return EXERCISE_CATALOG[i].name;
    }
  }
  return exerciseId;
}

export function findExercise(exerciseId: string): ExerciseDef | null {
  for (let i = 0; i < EXERCISE_CATALOG.length; i++) {
    if (EXERCISE_CATALOG[i].id === exerciseId) {
      return EXERCISE_CATALOG[i];
    }
  }
  return null;
}
`;
}

function detailsEts() {
  const rows = EXERCISES.map((item) => {
    return `  { id: ${q(item.id)}, englishName: ${q(item.englishName)}, aliases: ${qArr(item.aliases)}, ` +
      `primaryMusclesZh: ${q(item.primaryMusclesZh)}, secondaryMusclesZh: ${q(item.secondaryMusclesZh)}, ` +
      `difficulty: ${q(item.difficulty)}, startPosition: ${q(item.startPosition)}, steps: ${qArr(item.steps)}, ` +
      `cues: ${qArr(item.cues)}, counting: ${q(item.counting)}, sourceName: ${q(SOURCE.name)}, ` +
      `sourceId: ${q(item.sourceId)}, sourceCommit: ${q(SOURCE.commit)} }`;
  });
  return `export interface ExerciseDetail {
  id: string;
  englishName: string;
  aliases: string[];
  primaryMusclesZh: string;
  secondaryMusclesZh: string;
  difficulty: string;
  startPosition: string;
  steps: string[];
  cues: string[];
  counting: string;
  sourceName: string;
  sourceId: string;
  sourceCommit: string;
}

export const EXERCISE_DETAILS: ExerciseDetail[] = [
${rows.join(',\n')}
];

export function findExerciseDetail(exerciseId: string): ExerciseDetail | null {
  for (let i = 0; i < EXERCISE_DETAILS.length; i++) {
    if (EXERCISE_DETAILS[i].id === exerciseId) {
      return EXERCISE_DETAILS[i];
    }
  }
  return null;
}

export function extraSearchText(detail: ExerciseDetail | null): string {
  if (detail === null) {
    return '';
  }
  let text: string = detail.englishName;
  for (let i = 0; i < detail.aliases.length; i++) {
    text = text + ' ' + detail.aliases[i];
  }
  return text;
}

export function difficultyLabel(value: string): string {
  if (value === 'intermediate') {
    return '中级';
  }
  if (value === 'advanced') {
    return '高级';
  }
  return '初级';
}
`;
}

function artworkEts() {
  const rows = EXERCISES.map((item) => {
    const base = `ex_${item.id}`;
    return `  { id: ${q(item.id)}, card: $r('app.media.${base}_card'), start: $r('app.media.${base}_start'), end: $r('app.media.${base}_end') }`;
  });
  return `import { PartKey } from './types';

export interface ExerciseArtwork {
  id: string;
  card: Resource;
  start: Resource;
  end: Resource;
}

export const EXERCISE_ARTWORK: ExerciseArtwork[] = [
${rows.join(',\n')}
];

export function artworkOf(exerciseId: string): ExerciseArtwork | null {
  for (let i = 0; i < EXERCISE_ARTWORK.length; i++) {
    if (EXERCISE_ARTWORK[i].id === exerciseId) {
      return EXERCISE_ARTWORK[i];
    }
  }
  return null;
}

export function cardImageOf(exerciseId: string, partKey: PartKey): Resource {
  const art: ExerciseArtwork | null = artworkOf(exerciseId);
  if (art !== null) {
    return art.card;
  }
  return partFallback(partKey);
}

export function partFallback(partKey: PartKey): Resource {
  if (partKey === 'shoulder') {
    return $r('app.media.part_shoulder');
  }
  if (partKey === 'back') {
    return $r('app.media.part_back');
  }
  if (partKey === 'arm') {
    return $r('app.media.part_arm');
  }
  if (partKey === 'glute') {
    return $r('app.media.part_glute');
  }
  if (partKey === 'leg') {
    return $r('app.media.part_leg');
  }
  if (partKey === 'abs') {
    return $r('app.media.part_abs');
  }
  if (partKey === 'core') {
    return $r('app.media.part_core');
  }
  if (partKey === 'cardio') {
    return $r('app.media.part_cardio');
  }
  return $r('app.media.part_chest');
}
`;
}

function curatedJson() {
  return JSON.stringify({
    source: SOURCE,
    count: EXERCISES.length,
    exercises: EXERCISES.map((item) => ({
      id: item.id,
      existing: item.existing,
      partKey: item.partKey,
      name: item.name,
      englishName: item.englishName,
      aliases: item.aliases,
      equipment: item.equipment,
      movementPattern: item.movementPattern,
      weightStep: item.weightStep,
      isBodyweight: item.isBodyweight,
      isUnilateral: item.isUnilateral,
      primaryMuscles: item.primaryMuscles,
      secondaryMuscles: item.secondaryMuscles,
      primaryMusclesZh: item.primaryMusclesZh,
      secondaryMusclesZh: item.secondaryMusclesZh,
      difficulty: item.difficulty,
      startPosition: item.startPosition,
      steps: item.steps,
      cues: item.cues,
      counting: item.counting,
      sourceId: item.sourceId,
      pose: item.pose
    }))
  }, null, 2);
}

function attribution() {
  return `# 动作资料来源

精选动作的名称、器械、肌群与步骤参考 [yuhonas/free-exercise-db](${SOURCE.url}) 公开数据仓库，固定上游提交 \`${SOURCE.commit}\`。

该仓库以 Unlicense 发布，允许复制、修改、分发和商业使用。维护者已说明无法确认库内照片是否免版税，因此本应用**不使用**上游照片，全部动作配图为原创矢量示意图。

- 数据许可：${SOURCE.licenseUrl}
- 照片说明：https://github.com/yuhonas/free-exercise-db/issues/2#issuecomment-1609681281

无对应上游条目的动作（如部分核心与有氧）保留原有 ID，并补充原创中文说明。
`;
}

function licenseText() {
  return `This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

Upstream: ${SOURCE.url} @ ${SOURCE.commit}
Photos from the upstream library are NOT included.
`;
}

validate();
mkdirSync(raw, { recursive: true });
mkdirSync(media, { recursive: true });

for (const name of readdirSync(media)) {
  if (name.startsWith('ex_') && name.endsWith('.svg')) {
    unlinkSync(join(media, name));
  }
}

for (const item of EXERCISES) {
  for (const phase of ['card', 'start', 'end']) {
    writeFileSync(join(media, `ex_${item.id}_${phase}.svg`), renderExerciseSvg(item, phase), 'utf8');
  }
}

writeFileSync(join(model, 'exerciseCatalog.ets'), catalogEts(), 'utf8');
writeFileSync(join(model, 'exerciseDetails.ets'), detailsEts(), 'utf8');
writeFileSync(join(model, 'exerciseArtwork.ets'), artworkEts(), 'utf8');
writeFileSync(join(toolsOut, 'curated.json'), curatedJson(), 'utf8');
writeFileSync(join(raw, 'ATTRIBUTION.md'), attribution(), 'utf8');
writeFileSync(join(raw, 'LICENSE.txt'), licenseText(), 'utf8');

const byPart = {};
for (const part of PARTS) {
  byPart[part] = EXERCISES.filter((item) => item.partKey === part).length;
}
console.log(`Generated ${EXERCISES.length} exercises`, byPart);
console.log(`SVG files: ${EXERCISES.length * 3}`);
