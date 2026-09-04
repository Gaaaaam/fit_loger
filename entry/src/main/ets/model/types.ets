export type PartKey = 'chest' | 'shoulder' | 'back' | 'arm' | 'glute' | 'leg';

export type SetStatus = 'planned' | 'done';

export type Technique = 'drop' | 'ramp' | 'rest_pause' | 'amrap';

export type Equipment = 'barbell' | 'dumbbell' | 'machine' | 'cable' | 'bodyweight';

export type MovementPattern = 'push' | 'pull' | 'hinge' | 'squat' | 'lunge' | 'carry' | 'isolation';

export interface BodyPartInfo {
  key: PartKey;
  name: string;
}

export interface EquipmentInfo {
  key: Equipment;
  name: string;
}

export const BODY_PARTS: BodyPartInfo[] = [
  { key: 'chest', name: '胸' },
  { key: 'shoulder', name: '肩' },
  { key: 'back', name: '背' },
  { key: 'arm', name: '手臂' },
  { key: 'glute', name: '臀部' },
  { key: 'leg', name: '腿' }
];

export const EQUIPMENT_OPTIONS: EquipmentInfo[] = [
  { key: 'barbell', name: '杠铃' },
  { key: 'dumbbell', name: '哑铃' },
  { key: 'machine', name: '器械' },
  { key: 'cable', name: '绳索' },
  { key: 'bodyweight', name: '自重' }
];

export const RIR_OPTIONS: number[] = [0, 1, 3];

export function partName(key: string): string {
  for (let i = 0; i < BODY_PARTS.length; i++) {
    if (BODY_PARTS[i].key === key) {
      return BODY_PARTS[i].name;
    }
  }
  return key;
}

export function toPartKey(value: string): PartKey {
  if (value === 'shoulder') {
    return 'shoulder';
  }
  if (value === 'back') {
    return 'back';
  }
  if (value === 'arm') {
    return 'arm';
  }
  if (value === 'glute') {
    return 'glute';
  }
  if (value === 'leg') {
    return 'leg';
  }
  return 'chest';
}

export function toSetStatus(value: string): SetStatus {
  if (value === 'planned') {
    return 'planned';
  }
  return 'done';
}

export function toEquipment(value: string): Equipment {
  if (value === 'dumbbell') {
    return 'dumbbell';
  }
  if (value === 'machine') {
    return 'machine';
  }
  if (value === 'cable') {
    return 'cable';
  }
  if (value === 'bodyweight') {
    return 'bodyweight';
  }
  return 'barbell';
}

export function equipmentName(key: string): string {
  for (let i = 0; i < EQUIPMENT_OPTIONS.length; i++) {
    if (EQUIPMENT_OPTIONS[i].key === key) {
      return EQUIPMENT_OPTIONS[i].name;
    }
  }
  return key;
}

export function rirLabel(rir: number): string {
  if (rir === 0) {
    return '练到力竭';
  }
  if (rir === 1) {
    return '还能做 1-2 下';
  }
  if (rir === 3) {
    return '还能做 3 下以上';
  }
  return '';
}

export function tagChipLabel(isWarmup: number, technique: string): string {
  if (isWarmup === 1) {
    return '热身';
  }
  if (technique === 'drop') {
    return '递减';
  }
  if (technique === 'ramp') {
    return '递增';
  }
  if (technique === 'rest_pause') {
    return '休息暂停';
  }
  if (technique === 'amrap') {
    return 'AMRAP';
  }
  return '';
}

export function isDefaultTag(isWarmup: number, technique: string): boolean {
  return isWarmup === 0 && technique.length === 0;
}
