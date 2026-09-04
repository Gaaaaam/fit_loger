import { PartKey } from './types';

export interface ExerciseDef {
  id: string;
  partKey: PartKey;
  name: string;
}

export const EXERCISE_CATALOG: ExerciseDef[] = [
  { id: 'chest_bb_bench', partKey: 'chest', name: '杠铃卧推' },
  { id: 'chest_db_bench', partKey: 'chest', name: '哑铃卧推' },
  { id: 'chest_incline_bench', partKey: 'chest', name: '上斜卧推' },
  { id: 'chest_fly', partKey: 'chest', name: '飞鸟' },
  { id: 'chest_cable_crossover', partKey: 'chest', name: '绳索夹胸' },
  { id: 'chest_dip', partKey: 'chest', name: '双杠臂屈伸' },
  { id: 'chest_pushup', partKey: 'chest', name: '俯卧撑' },

  { id: 'shoulder_bb_press', partKey: 'shoulder', name: '杠铃推举' },
  { id: 'shoulder_db_press', partKey: 'shoulder', name: '哑铃推举' },
  { id: 'shoulder_lateral_raise', partKey: 'shoulder', name: '侧平举' },
  { id: 'shoulder_front_raise', partKey: 'shoulder', name: '前平举' },
  { id: 'shoulder_reverse_fly', partKey: 'shoulder', name: '反向飞鸟' },
  { id: 'shoulder_face_pull', partKey: 'shoulder', name: '面拉' },

  { id: 'back_pullup', partKey: 'back', name: '引体向上' },
  { id: 'back_lat_pulldown', partKey: 'back', name: '高位下拉' },
  { id: 'back_bb_row', partKey: 'back', name: '杠铃划船' },
  { id: 'back_db_row', partKey: 'back', name: '哑铃划船' },
  { id: 'back_seated_row', partKey: 'back', name: '坐姿划船' },
  { id: 'back_deadlift', partKey: 'back', name: '硬拉' },

  { id: 'arm_bb_curl', partKey: 'arm', name: '杠铃弯举' },
  { id: 'arm_db_curl', partKey: 'arm', name: '哑铃弯举' },
  { id: 'arm_hammer_curl', partKey: 'arm', name: '锤式弯举' },
  { id: 'arm_pushdown', partKey: 'arm', name: '绳索下压' },
  { id: 'arm_skull_crusher', partKey: 'arm', name: '仰卧臂屈伸' },

  { id: 'glute_hip_thrust', partKey: 'glute', name: '臀推' },
  { id: 'glute_rdl', partKey: 'glute', name: '罗马尼亚硬拉' },
  { id: 'glute_bridge', partKey: 'glute', name: '臀桥' },
  { id: 'glute_abduction', partKey: 'glute', name: '髋外展' },

  { id: 'leg_squat', partKey: 'leg', name: '杠铃深蹲' },
  { id: 'leg_press', partKey: 'leg', name: '腿举' },
  { id: 'leg_extension', partKey: 'leg', name: '腿屈伸' },
  { id: 'leg_curl', partKey: 'leg', name: '腿弯举' },
  { id: 'leg_lunge', partKey: 'leg', name: '箭步蹲' },
  { id: 'leg_calf_raise', partKey: 'leg', name: '提踵' }
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
