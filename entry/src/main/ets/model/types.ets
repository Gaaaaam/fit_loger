export type PartKey = 'chest' | 'shoulder' | 'back' | 'arm' | 'glute' | 'leg' | 'abs' | 'core' | 'cardio';

export type SetStatus = 'planned' | 'done';

export type DayDotKind = 'trained' | 'planned' | 'rest' | 'empty';

export type Technique = 'drop' | 'ramp' | 'rest_pause' | 'amrap';

export type Equipment = 'barbell' | 'dumbbell' | 'machine' | 'cable' | 'bodyweight' |
  'band' | 'kettlebell' | 'ezbar' | 'other';

export type MovementPattern = 'push' | 'pull' | 'hinge' | 'squat' | 'lunge' | 'carry' | 'isolation';

export interface BodyPartInfo {
  key: PartKey;
  name: string;
  description: string;
  image: Resource;
}

export interface EquipmentInfo {
  key: Equipment;
  name: string;
}

export const BODY_PARTS: BodyPartInfo[] = [
  { key: 'chest', name: '胸', description: '胸部推举与夹胸', image: $r('app.media.part_chest') },
  { key: 'shoulder', name: '肩', description: '肩部推举与侧平举', image: $r('app.media.part_shoulder') },
  { key: 'back', name: '背', description: '背部拉力与划船', image: $r('app.media.part_back') },
  { key: 'arm', name: '手臂', description: '肱二头肌与肱三头肌', image: $r('app.media.part_arm') },
  { key: 'glute', name: '臀部', description: '髋伸展与臀部训练', image: $r('app.media.part_glute') },
  { key: 'leg', name: '腿', description: '大腿与小腿训练', image: $r('app.media.part_leg') },
  { key: 'abs', name: '腹部', description: '卷腹、举腿等腹肌训练', image: $r('app.media.part_abs') },
  { key: 'core', name: '核心', description: '躯干稳定与抗旋转', image: $r('app.media.part_core') },
  { key: 'cardio', name: '有氧', description: '心肺耐力训练', image: $r('app.media.part_cardio') }
];

export const EQUIPMENT_OPTIONS: EquipmentInfo[] = [
  { key: 'barbell', name: '杠铃' },
  { key: 'dumbbell', name: '哑铃' },
  { key: 'machine', name: '器械' },
  { key: 'cable', name: '绳索' },
  { key: 'bodyweight', name: '自重' },
  { key: 'band', name: '弹力带' },
  { key: 'kettlebell', name: '壶铃' },
  { key: 'ezbar', name: '曲杆' },
  { key: 'other', name: '其他' }
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
  if (value === 'abs') {
    return 'abs';
  }
  if (value === 'core') {
    return 'core';
  }
  if (value === 'cardio') {
    return 'cardio';
  }
  return 'chest';
}

export function toSetStatus(value: string): SetStatus {
  if (value === 'planned') {
    return 'planned';
  }
  return 'done';
}

export function toDayDotKind(value: string): DayDotKind {
  if (value === 'trained') {
    return 'trained';
  }
  if (value === 'planned') {
    return 'planned';
  }
  if (value === 'rest') {
    return 'rest';
  }
  return 'empty';
}

export function toEquipment(value: string): Equipment {
  if (value === 'barbell') {
    return 'barbell';
  }
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
  if (value === 'band') {
    return 'band';
  }
  if (value === 'kettlebell') {
    return 'kettlebell';
  }
  if (value === 'ezbar') {
    return 'ezbar';
  }
  return 'other';
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
