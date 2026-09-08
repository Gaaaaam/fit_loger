import { ExerciseDef, findExercise } from '../model/exerciseCatalog';
import { extraSearchText, findExerciseDetail } from '../model/exerciseDetails';
import { MuscleKey, toMuscleKey } from '../model/muscleTypes';

export class RecommendItem {
  id: string = '';
  name: string = '';
  role: string = 'primary';
  addedToday: boolean = false;
}

export class BatchPlan {
  ok: boolean = true;
  error: string = '';
  toInsert: string[] = [];
}

export class HitNode {
  name: string = '';
  parentNames: string[] = [];
  distance: number = 0;
}

export interface ExtraMuscleLink {
  exerciseId: string;
  muscle: MuscleKey;
  role: string;
}

export const DRAG_THRESHOLD: number = 8;
export const DEFAULT_CAMERA_DISTANCE: number = 2.55;
export const MIN_CAMERA_DISTANCE: number = 1.15;
export const MAX_CAMERA_DISTANCE: number = 4.2;
export const MIN_PITCH: number = -0.42;
export const MAX_PITCH: number = 0.58;

export const EXTRA_MUSCLE_LINKS: ExtraMuscleLink[] = [
  { exerciseId: 'back_bb_row', muscle: 'upper_back', role: 'primary' },
  { exerciseId: 'back_db_row', muscle: 'upper_back', role: 'primary' },
  { exerciseId: 'back_seated_row', muscle: 'upper_back', role: 'primary' },
  { exerciseId: 'arm_hammer_curl', muscle: 'forearm', role: 'primary' },
  { exerciseId: 'glute_rdl', muscle: 'hamstrings', role: 'primary' },
  { exerciseId: 'glute_rdl', muscle: 'erector_spinae', role: 'secondary' },
  { exerciseId: 'shoulder_bb_press', muscle: 'side_delt', role: 'secondary' },
  { exerciseId: 'shoulder_db_press', muscle: 'side_delt', role: 'secondary' },
  { exerciseId: 'shoulder_reverse_fly', muscle: 'upper_back', role: 'secondary' },
  { exerciseId: 'shoulder_reverse_fly', muscle: 'traps', role: 'secondary' },
  { exerciseId: 'back_seated_row', muscle: 'rear_delt', role: 'secondary' },
  { exerciseId: 'back_seated_row', muscle: 'traps', role: 'secondary' },
  { exerciseId: 'leg_lunge', muscle: 'glute_med', role: 'secondary' },
  { exerciseId: 'shoulder_face_pull', muscle: 'traps', role: 'secondary' },
  { exerciseId: 'back_bb_row', muscle: 'traps', role: 'secondary' },
  { exerciseId: 'back_deadlift', muscle: 'traps', role: 'secondary' },
  { exerciseId: 'back_deadlift', muscle: 'hamstrings', role: 'secondary' },
  { exerciseId: 'back_deadlift', muscle: 'glute_max', role: 'secondary' },
  { exerciseId: 'arm_hammer_curl', muscle: 'forearm', role: 'secondary' },
  { exerciseId: 'arm_bb_curl', muscle: 'forearm', role: 'secondary' },
  { exerciseId: 'back_bb_row', muscle: 'forearm', role: 'secondary' },
  { exerciseId: 'back_deadlift', muscle: 'forearm', role: 'secondary' },
  { exerciseId: 'abs_crunch', muscle: 'obliques', role: 'secondary' },
  { exerciseId: 'core_dead_bug', muscle: 'obliques', role: 'secondary' },
  { exerciseId: 'core_bird_dog', muscle: 'obliques', role: 'secondary' },
  { exerciseId: 'core_shoulder_tap', muscle: 'obliques', role: 'secondary' }
];

export function muscleFromNodeName(raw: string): MuscleKey | null {
  let name: string = raw;
  const slash: number = name.lastIndexOf('/');
  if (slash >= 0) {
    name = name.substring(slash + 1);
  }
  if (name.indexOf('pick_') !== 0) {
    return null;
  }
  let key: string = name.substring(5);
  if (key.endsWith('_L') || key.endsWith('_R')) {
    key = key.substring(0, key.length - 2);
  }
  return toMuscleKey(key);
}

export function muscleFromNodeChain(names: string[]): MuscleKey | null {
  for (let i = 0; i < names.length; i++) {
    const key: MuscleKey | null = muscleFromNodeName(names[i]);
    if (key !== null) {
      return key;
    }
  }
  return null;
}

export function pickVisibleMuscle(hits: HitNode[]): MuscleKey | null {
  if (hits.length === 0) {
    return null;
  }
  const copy: HitNode[] = [];
  for (let i = 0; i < hits.length; i++) {
    copy.push(hits[i]);
  }
  copy.sort((a: HitNode, b: HitNode) => {
    return a.distance - b.distance;
  });
  const nearest: HitNode = copy[0];
  const names: string[] = [nearest.name];
  for (let i = 0; i < nearest.parentNames.length; i++) {
    names.push(nearest.parentNames[i]);
  }
  return muscleFromNodeChain(names);
}

export function isDragGesture(dx: number, dy: number, threshold: number): boolean {
  return dx * dx + dy * dy > threshold * threshold;
}

export function clampPitch(pitch: number): number {
  if (pitch < MIN_PITCH) {
    return MIN_PITCH;
  }
  if (pitch > MAX_PITCH) {
    return MAX_PITCH;
  }
  return pitch;
}

export function clampDistance(distance: number): number {
  if (distance < MIN_CAMERA_DISTANCE) {
    return MIN_CAMERA_DISTANCE;
  }
  if (distance > MAX_CAMERA_DISTANCE) {
    return MAX_CAMERA_DISTANCE;
  }
  return distance;
}

export function canPanAfterZoom(distance: number): boolean {
  return distance < DEFAULT_CAMERA_DISTANCE - 0.04;
}

export function wrapYaw(yaw: number): number {
  const tau: number = Math.PI * 2;
  let value: number = yaw % tau;
  if (value < 0) {
    value += tau;
  }
  return value;
}

export function keysFromLegacyField(field: string): MuscleKey[] {
  if (field.length === 0) {
    return [];
  }
  const parts: string[] = field.split(',');
  const keys: MuscleKey[] = [];
  const seen: Map<string, boolean> = new Map();
  for (let i = 0; i < parts.length; i++) {
    const mapped: MuscleKey | null = mapLegacyMuscleToken(parts[i].trim());
    if (mapped === null) {
      continue;
    }
    if (seen.get(mapped) === true) {
      continue;
    }
    seen.set(mapped, true);
    keys.push(mapped);
  }
  return keys;
}

export function mapLegacyMuscleToken(token: string): MuscleKey | null {
  if (token === 'chest' || token === 'upper_chest') {
    return 'chest';
  }
  if (token === 'front_delt') {
    return 'front_delt';
  }
  if (token === 'side_delt') {
    return 'side_delt';
  }
  if (token === 'rear_delt') {
    return 'rear_delt';
  }
  if (token === 'traps') {
    return 'traps';
  }
  if (token === 'upper_back' || token === 'back') {
    return 'upper_back';
  }
  if (token === 'lats') {
    return 'lats';
  }
  if (token === 'erector_spinae' || token === 'posterior_chain') {
    return 'erector_spinae';
  }
  if (token === 'biceps' || token === 'brachialis') {
    return 'biceps';
  }
  if (token === 'triceps') {
    return 'triceps';
  }
  if (token === 'forearm') {
    return 'forearm';
  }
  if (token === 'abs' || token === 'core' || token === 'rectus_abdominis') {
    return 'rectus_abdominis';
  }
  if (token === 'obliques') {
    return 'obliques';
  }
  if (token === 'glute' || token === 'glute_max') {
    return 'glute_max';
  }
  if (token === 'glute_medius' || token === 'glute_med') {
    return 'glute_med';
  }
  if (token === 'quad' || token === 'quads') {
    return 'quads';
  }
  if (token === 'hamstring' || token === 'hamstrings') {
    return 'hamstrings';
  }
  if (token === 'calf' || token === 'calves') {
    return 'calves';
  }
  return null;
}

export function primaryKeysOf(def: ExerciseDef): MuscleKey[] {
  // Presets use stable IDs, independent of old database seeds and traditional body-part labels.
  // Unmapped custom actions stay available through all-actions/search without guessed anatomy.
  const preset: ExerciseDef | null = findExercise(def.id);
  if (preset === null) {
    return [];
  }
  if (def.id === 'core_bird_dog') {
    return ['erector_spinae'];
  }
  return mergeKeys(keysFromLegacyField(preset.primaryMuscles), extraKeys(def.id, 'primary'));
}

export function secondaryKeysOf(def: ExerciseDef): MuscleKey[] {
  const preset: ExerciseDef | null = findExercise(def.id);
  if (preset === null) {
    return [];
  }
  return mergeKeys(keysFromLegacyField(preset.secondaryMuscles), extraKeys(def.id, 'secondary'));
}

export function recommendForMuscle(muscle: MuscleKey, defs: ExerciseDef[],
  addedIds: string[]): RecommendItem[] {
  const primary: RecommendItem[] = [];
  const secondary: RecommendItem[] = [];
  const seen: Map<string, boolean> = new Map();
  for (let i = 0; i < defs.length; i++) {
    const def: ExerciseDef = defs[i];
    if (seen.get(def.id) !== true && hasKey(primaryKeysOf(def), muscle)) {
      primary.push(toRecommend(def, 'primary', addedIds));
      seen.set(def.id, true);
    }
  }
  for (let i = 0; i < defs.length; i++) {
    const def: ExerciseDef = defs[i];
    if (seen.get(def.id) === true) {
      continue;
    }
    if (hasKey(secondaryKeysOf(def), muscle)) {
      secondary.push(toRecommend(def, 'secondary', addedIds));
      seen.set(def.id, true);
    }
  }
  return primary.concat(secondary);
}

export function filterExercises(defs: ExerciseDef[], query: string, addedIds: string[]): RecommendItem[] {
  const result: RecommendItem[] = [];
  for (let i = 0; i < defs.length; i++) {
    const extra: string = extraSearchText(findExerciseDetail(defs[i].id));
    if (!matchesSearch(defs[i].name, defs[i].aliases, query, extra)) {
      continue;
    }
    result.push(toRecommend(defs[i], '', addedIds));
  }
  return result;
}

export function matchesSearch(name: string, aliases: string, query: string, extra: string = ''): boolean {
  const q: string = query.trim().toLowerCase();
  if (q.length === 0) {
    return true;
  }
  if (name.toLowerCase().indexOf(q) >= 0) {
    return true;
  }
  if (aliases.toLowerCase().indexOf(q) >= 0) {
    return true;
  }
  if (extra.toLowerCase().indexOf(q) >= 0) {
    return true;
  }
  return false;
}

export function toggleSelected(selected: string[], exerciseId: string, addedToday: boolean): string[] {
  if (addedToday) {
    return selected.slice();
  }
  const next: string[] = [];
  let found: boolean = false;
  for (let i = 0; i < selected.length; i++) {
    if (selected[i] === exerciseId) {
      found = true;
    } else {
      next.push(selected[i]);
    }
  }
  if (!found) {
    next.push(exerciseId);
  }
  return next;
}

export function isSelected(selected: string[], exerciseId: string): boolean {
  for (let i = 0; i < selected.length; i++) {
    if (selected[i] === exerciseId) {
      return true;
    }
  }
  return false;
}

export function planBatchAdd(requested: string[], alreadyOnDay: string[], validIds: string[]): BatchPlan {
  const plan: BatchPlan = new BatchPlan();
  const valid: Map<string, boolean> = new Map();
  for (let i = 0; i < validIds.length; i++) {
    valid.set(validIds[i], true);
  }
  const already: Map<string, boolean> = new Map();
  for (let i = 0; i < alreadyOnDay.length; i++) {
    already.set(alreadyOnDay[i], true);
  }
  const queued: Map<string, boolean> = new Map();
  for (let i = 0; i < requested.length; i++) {
    const id: string = requested[i];
    if (valid.get(id) !== true) {
      plan.ok = false;
      plan.error = '动作不存在';
      plan.toInsert = [];
      return plan;
    }
    if (already.get(id) === true) {
      continue;
    }
    if (queued.get(id) === true) {
      continue;
    }
    queued.set(id, true);
    plan.toInsert.push(id);
  }
  return plan;
}

function extraKeys(exerciseId: string, role: string): MuscleKey[] {
  const keys: MuscleKey[] = [];
  for (let i = 0; i < EXTRA_MUSCLE_LINKS.length; i++) {
    if (EXTRA_MUSCLE_LINKS[i].exerciseId === exerciseId && EXTRA_MUSCLE_LINKS[i].role === role) {
      keys.push(EXTRA_MUSCLE_LINKS[i].muscle);
    }
  }
  return keys;
}

function mergeKeys(base: MuscleKey[], extra: MuscleKey[]): MuscleKey[] {
  const result: MuscleKey[] = [];
  const seen: Map<string, boolean> = new Map();
  for (let i = 0; i < base.length; i++) {
    if (seen.get(base[i]) === true) {
      continue;
    }
    seen.set(base[i], true);
    result.push(base[i]);
  }
  for (let i = 0; i < extra.length; i++) {
    if (seen.get(extra[i]) === true) {
      continue;
    }
    seen.set(extra[i], true);
    result.push(extra[i]);
  }
  return result;
}

function hasKey(keys: MuscleKey[], muscle: MuscleKey): boolean {
  for (let i = 0; i < keys.length; i++) {
    if (keys[i] === muscle) {
      return true;
    }
  }
  return false;
}

function toRecommend(def: ExerciseDef, role: string, addedIds: string[]): RecommendItem {
  const item: RecommendItem = new RecommendItem();
  item.id = def.id;
  item.name = def.name;
  item.role = role;
  item.addedToday = isSelected(addedIds, def.id);
  return item;
}
