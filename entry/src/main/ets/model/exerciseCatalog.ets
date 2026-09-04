import { Equipment, MovementPattern, PartKey } from './types';

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
  { id: 'chest_bb_bench', partKey: 'chest', name: '杠铃卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_db_bench', partKey: 'chest', name: '哑铃卧推', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_incline_bench', partKey: 'chest', name: '上斜卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'upper_chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_fly', partKey: 'chest', name: '飞鸟', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: '' },
  { id: 'chest_cable_crossover', partKey: 'chest', name: '绳索夹胸', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: '' },
  { id: 'chest_dip', partKey: 'chest', name: '双杠臂屈伸', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: 'triceps' },
  { id: 'chest_pushup', partKey: 'chest', name: '俯卧撑', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },

  { id: 'shoulder_bb_press', partKey: 'shoulder', name: '杠铃推举', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_db_press', partKey: 'shoulder', name: '哑铃推举', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_lateral_raise', partKey: 'shoulder', name: '侧平举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'side_delt', secondaryMuscles: '' },
  { id: 'shoulder_front_raise', partKey: 'shoulder', name: '前平举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'front_delt', secondaryMuscles: '' },
  { id: 'shoulder_reverse_fly', partKey: 'shoulder', name: '反向飞鸟', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'rear_delt', secondaryMuscles: '' },
  { id: 'shoulder_face_pull', partKey: 'shoulder', name: '面拉', equipment: 'cable', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'rear_delt', secondaryMuscles: 'upper_back' },

  { id: 'back_pullup', partKey: 'back', name: '引体向上', equipment: 'bodyweight', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_lat_pulldown', partKey: 'back', name: '高位下拉', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_bb_row', partKey: 'back', name: '杠铃划船', equipment: 'barbell', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'lats', secondaryMuscles: 'biceps,rear_delt' },
  { id: 'back_db_row', partKey: 'back', name: '哑铃划船', equipment: 'dumbbell', movementPattern: 'pull', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_seated_row', partKey: 'back', name: '坐姿划船', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_deadlift', partKey: 'back', name: '硬拉', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'posterior_chain', secondaryMuscles: 'back,glute' },

  { id: 'arm_bb_curl', partKey: 'arm', name: '杠铃弯举', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_db_curl', partKey: 'arm', name: '哑铃弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_hammer_curl', partKey: 'arm', name: '锤式弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'brachialis', secondaryMuscles: 'biceps' },
  { id: 'arm_pushdown', partKey: 'arm', name: '绳索下压', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_skull_crusher', partKey: 'arm', name: '仰卧臂屈伸', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'triceps', secondaryMuscles: '' },

  { id: 'glute_hip_thrust', partKey: 'glute', name: '臀推', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_rdl', partKey: 'glute', name: '罗马尼亚硬拉', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_bridge', partKey: 'glute', name: '臀桥', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '', primaryMuscles: 'glute', secondaryMuscles: '' },
  { id: 'glute_abduction', partKey: 'glute', name: '髋外展', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'glute_medius', secondaryMuscles: '' },

  { id: 'leg_squat', partKey: 'leg', name: '杠铃深蹲', equipment: 'barbell', movementPattern: 'squat', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_press', partKey: 'leg', name: '腿举', equipment: 'machine', movementPattern: 'squat', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_extension', partKey: 'leg', name: '腿屈伸', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'quad', secondaryMuscles: '' },
  { id: 'leg_curl', partKey: 'leg', name: '腿弯举', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'hamstring', secondaryMuscles: '' },
  { id: 'leg_lunge', partKey: 'leg', name: '箭步蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_calf_raise', partKey: 'leg', name: '提踵', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '', primaryMuscles: 'calf', secondaryMuscles: '' }
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
