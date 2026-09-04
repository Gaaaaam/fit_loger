export type PartKey = 'chest' | 'shoulder' | 'back' | 'arm' | 'glute' | 'leg';

export type SetTag = 'warmup' | 'working' | 'drop' | 'ramp';

export interface BodyPartInfo {
  key: PartKey;
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

export const SET_TAG_OPTIONS: string[] = ['热身', '正式', '递减', '递增'];

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

export function tagToLabel(tag: SetTag): string {
  if (tag === 'warmup') {
    return '热身';
  }
  if (tag === 'drop') {
    return '递减';
  }
  if (tag === 'ramp') {
    return '递增';
  }
  return '正式';
}

export function labelToTag(label: string): SetTag {
  if (label === '热身') {
    return 'warmup';
  }
  if (label === '递减') {
    return 'drop';
  }
  if (label === '递增') {
    return 'ramp';
  }
  return 'working';
}

export function tagToIndex(tag: SetTag): number {
  if (tag === 'warmup') {
    return 0;
  }
  if (tag === 'working') {
    return 1;
  }
  if (tag === 'drop') {
    return 2;
  }
  return 3;
}

export function indexToTag(index: number): SetTag {
  if (index === 0) {
    return 'warmup';
  }
  if (index === 2) {
    return 'drop';
  }
  if (index === 3) {
    return 'ramp';
  }
  return 'working';
}

export function toSetTag(value: string): SetTag {
  if (value === 'warmup' || value === 'drop' || value === 'ramp' || value === 'working') {
    return value;
  }
  return 'working';
}
