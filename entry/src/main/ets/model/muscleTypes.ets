export type WorkoutViewMode = 'part' | 'exercise';

export type MuscleKey =
  'chest' |
  'front_delt' |
  'side_delt' |
  'rear_delt' |
  'traps' |
  'upper_back' |
  'lats' |
  'erector_spinae' |
  'biceps' |
  'triceps' |
  'forearm' |
  'rectus_abdominis' |
  'obliques' |
  'glute_max' |
  'glute_med' |
  'quads' |
  'hamstrings' |
  'calves';

export interface MuscleInfo {
  key: MuscleKey;
  name: string;
}

export const MUSCLE_REGIONS: MuscleInfo[] = [
  { key: 'chest', name: '胸肌' },
  { key: 'front_delt', name: '肩前束' },
  { key: 'side_delt', name: '肩中束' },
  { key: 'rear_delt', name: '肩后束' },
  { key: 'traps', name: '斜方肌' },
  { key: 'upper_back', name: '上背肌群' },
  { key: 'lats', name: '背阔肌' },
  { key: 'erector_spinae', name: '竖脊肌' },
  { key: 'biceps', name: '肱二头肌' },
  { key: 'triceps', name: '肱三头肌' },
  { key: 'forearm', name: '前臂' },
  { key: 'rectus_abdominis', name: '腹直肌' },
  { key: 'obliques', name: '腹斜肌' },
  { key: 'glute_max', name: '臀大肌' },
  { key: 'glute_med', name: '臀中肌' },
  { key: 'quads', name: '股四头肌' },
  { key: 'hamstrings', name: '腘绳肌' },
  { key: 'calves', name: '小腿' }
];

export function toWorkoutViewMode(value: string): WorkoutViewMode {
  if (value === 'exercise') {
    return 'exercise';
  }
  return 'part';
}

export function toMuscleKey(value: string): MuscleKey | null {
  for (let i = 0; i < MUSCLE_REGIONS.length; i++) {
    if (MUSCLE_REGIONS[i].key === value) {
      return MUSCLE_REGIONS[i].key;
    }
  }
  return null;
}

export function muscleName(key: string): string {
  for (let i = 0; i < MUSCLE_REGIONS.length; i++) {
    if (MUSCLE_REGIONS[i].key === key) {
      return MUSCLE_REGIONS[i].name;
    }
  }
  return key;
}
