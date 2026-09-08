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
  { id: 'chest_bb_bench', partKey: 'chest', name: '杠铃卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '平板卧推,杠铃平板卧推', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_db_bench', partKey: 'chest', name: '哑铃卧推', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '哑铃平板卧推', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_incline_bench', partKey: 'chest', name: '上斜卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '上斜杠铃卧推,上斜推胸', primaryMuscles: 'upper_chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_fly', partKey: 'chest', name: '飞鸟', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '哑铃飞鸟,平板飞鸟', primaryMuscles: 'chest', secondaryMuscles: '' },
  { id: 'chest_cable_crossover', partKey: 'chest', name: '绳索夹胸', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '龙门架夹胸,绳索交叉夹胸', primaryMuscles: 'chest', secondaryMuscles: '' },
  { id: 'chest_dip', partKey: 'chest', name: '双杠臂屈伸', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '双杠撑体,胸部双杠', primaryMuscles: 'chest', secondaryMuscles: 'triceps' },
  { id: 'chest_pushup', partKey: 'chest', name: '俯卧撑', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '标准俯卧撑', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_decline_bench', partKey: 'chest', name: '下斜杠铃卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '下斜卧推', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_incline_db_press', partKey: 'chest', name: '上斜哑铃卧推', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '上斜哑铃推胸', primaryMuscles: 'upper_chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_decline_db_press', partKey: 'chest', name: '下斜哑铃卧推', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '下斜哑铃推胸', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_incline_fly', partKey: 'chest', name: '上斜哑铃飞鸟', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '上斜飞鸟', primaryMuscles: 'upper_chest', secondaryMuscles: '' },
  { id: 'chest_machine_press', partKey: 'chest', name: '器械推胸', equipment: 'machine', movementPattern: 'push', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '坐姿推胸器,固定器械卧推', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_pec_deck', partKey: 'chest', name: '蝴蝶机夹胸', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '蝴蝶机,器械夹胸', primaryMuscles: 'chest', secondaryMuscles: '' },
  { id: 'chest_close_pushup', partKey: 'chest', name: '窄距俯卧撑', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '钻石俯卧撑,窄手俯卧撑', primaryMuscles: 'chest', secondaryMuscles: 'triceps' },
  { id: 'chest_incline_pushup', partKey: 'chest', name: '上斜俯卧撑', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '手高脚低俯卧撑', primaryMuscles: 'chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_decline_pushup', partKey: 'chest', name: '下斜俯卧撑', equipment: 'bodyweight', movementPattern: 'push', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '脚高手低俯卧撑', primaryMuscles: 'upper_chest', secondaryMuscles: 'triceps,front_delt' },
  { id: 'chest_pullover', partKey: 'chest', name: '哑铃过顶', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '哑铃拉力器,仰卧过顶', primaryMuscles: 'chest', secondaryMuscles: 'lats' },
  { id: 'shoulder_bb_press', partKey: 'shoulder', name: '杠铃推举', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '站姿推举,军事推举', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_db_press', partKey: 'shoulder', name: '哑铃推举', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '站姿哑铃推举', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_lateral_raise', partKey: 'shoulder', name: '侧平举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '侧举,哑铃侧平举', primaryMuscles: 'side_delt', secondaryMuscles: '' },
  { id: 'shoulder_front_raise', partKey: 'shoulder', name: '前平举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '前举', primaryMuscles: 'front_delt', secondaryMuscles: '' },
  { id: 'shoulder_reverse_fly', partKey: 'shoulder', name: '反向飞鸟', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '后束飞鸟,俯身飞鸟', primaryMuscles: 'rear_delt', secondaryMuscles: '' },
  { id: 'shoulder_face_pull', partKey: 'shoulder', name: '面拉', equipment: 'cable', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '面部牵引,绳索面拉', primaryMuscles: 'rear_delt', secondaryMuscles: 'upper_back' },
  { id: 'shoulder_seated_bb_press', partKey: 'shoulder', name: '坐姿杠铃推举', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '坐姿推举,靠背推举', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_arnold', partKey: 'shoulder', name: '阿诺德推举', equipment: 'dumbbell', movementPattern: 'push', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '阿诺推举,旋转推举', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps,side_delt' },
  { id: 'shoulder_machine_press', partKey: 'shoulder', name: '器械推举', equipment: 'machine', movementPattern: 'push', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '推肩器', primaryMuscles: 'front_delt', secondaryMuscles: 'triceps' },
  { id: 'shoulder_cable_lateral', partKey: 'shoulder', name: '绳索侧平举', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 1, aliases: '绳索侧举', primaryMuscles: 'side_delt', secondaryMuscles: '' },
  { id: 'shoulder_cable_rear_fly', partKey: 'shoulder', name: '绳索后束飞鸟', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '绳索反向飞鸟', primaryMuscles: 'rear_delt', secondaryMuscles: 'upper_back' },
  { id: 'shoulder_machine_reverse_fly', partKey: 'shoulder', name: '器械反向飞鸟', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '反向蝴蝶机,后束器械', primaryMuscles: 'rear_delt', secondaryMuscles: 'upper_back' },
  { id: 'shoulder_bent_over_raise', partKey: 'shoulder', name: '俯身侧平举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '俯身侧举', primaryMuscles: 'rear_delt', secondaryMuscles: '' },
  { id: 'shoulder_cable_front', partKey: 'shoulder', name: '绳索前平举', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '绳索前举', primaryMuscles: 'front_delt', secondaryMuscles: '' },
  { id: 'back_pullup', partKey: 'back', name: '引体向上', equipment: 'bodyweight', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '正手引体', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_lat_pulldown', partKey: 'back', name: '高位下拉', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '下拉,背阔肌下拉', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_bb_row', partKey: 'back', name: '杠铃划船', equipment: 'barbell', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '俯身划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps,rear_delt' },
  { id: 'back_db_row', partKey: 'back', name: '哑铃划船', equipment: 'dumbbell', movementPattern: 'pull', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '单臂划船,单手哑铃划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_seated_row', partKey: 'back', name: '坐姿划船', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '坐姿绳索划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_deadlift', partKey: 'back', name: '硬拉', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '传统硬拉', primaryMuscles: 'posterior_chain', secondaryMuscles: 'back,glute' },
  { id: 'back_chinup', partKey: 'back', name: '反手引体', equipment: 'bodyweight', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '反握引体向上', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_wide_pulldown', partKey: 'back', name: '宽握下拉', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '宽握高位下拉', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_close_pulldown', partKey: 'back', name: '窄握下拉', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '对握下拉,V 把下拉', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_reverse_pulldown', partKey: 'back', name: '反握下拉', equipment: 'machine', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '反手下拉', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'back_chest_supported_row', partKey: 'back', name: '胸托划船', equipment: 'dumbbell', movementPattern: 'pull', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '上斜划船,靠胸划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps,rear_delt' },
  { id: 'back_straight_arm_pulldown', partKey: 'back', name: '直臂下拉', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '直臂下压,背阔直臂下拉', primaryMuscles: 'lats', secondaryMuscles: '' },
  { id: 'back_hyperextension', partKey: 'back', name: '背伸', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '罗马椅,挺身,超伸', primaryMuscles: 'erector_spinae', secondaryMuscles: 'glute' },
  { id: 'back_tbar_row', partKey: 'back', name: 'T 杠划船', equipment: 'barbell', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: 'T杠,地雷管划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps,upper_back' },
  { id: 'back_inverted_row', partKey: 'back', name: '反向划船', equipment: 'bodyweight', movementPattern: 'pull', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '水平引体,桌下划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps,upper_back' },
  { id: 'back_one_arm_cable_row', partKey: 'back', name: '单臂绳索划船', equipment: 'cable', movementPattern: 'pull', weightStep: 5, isBodyweight: 0, isUnilateral: 1, aliases: '单手高位划船', primaryMuscles: 'lats', secondaryMuscles: 'biceps' },
  { id: 'arm_bb_curl', partKey: 'arm', name: '杠铃弯举', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '站姿杠铃弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_db_curl', partKey: 'arm', name: '哑铃弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '站姿哑铃弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_hammer_curl', partKey: 'arm', name: '锤式弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '中立弯举,锤击弯举', primaryMuscles: 'brachialis', secondaryMuscles: 'biceps' },
  { id: 'arm_pushdown', partKey: 'arm', name: '绳索下压', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '下压,肱三头下压', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_skull_crusher', partKey: 'arm', name: '仰卧臂屈伸', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '颅骨粉碎者,躺式臂屈伸', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_incline_curl', partKey: 'arm', name: '上斜弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '上斜哑铃弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_preacher_curl', partKey: 'arm', name: '牧师凳弯举', equipment: 'ezbar', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '托臂弯举,牧师椅', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_cable_curl', partKey: 'arm', name: '绳索弯举', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '低位绳索弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_concentration_curl', partKey: 'arm', name: '集中弯举', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '专注弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_overhead_extension', partKey: 'arm', name: '过顶臂屈伸', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '颈后臂屈伸,过头屈伸', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_one_arm_pushdown', partKey: 'arm', name: '单臂下压', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 1, aliases: '单手绳索下压', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_kickback', partKey: 'arm', name: '臂屈伸踢后', equipment: 'dumbbell', movementPattern: 'isolation', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '肱三头踢腿,俯身臂屈伸', primaryMuscles: 'triceps', secondaryMuscles: '' },
  { id: 'arm_wrist_curl', partKey: 'arm', name: '腕弯举', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '前臂弯举', primaryMuscles: 'forearm', secondaryMuscles: '' },
  { id: 'arm_reverse_wrist', partKey: 'arm', name: '反向腕弯举', equipment: 'barbell', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '前臂伸腕', primaryMuscles: 'forearm', secondaryMuscles: '' },
  { id: 'arm_ez_curl', partKey: 'arm', name: '曲杆弯举', equipment: 'ezbar', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: 'EZ 杠弯举,弯杆弯举', primaryMuscles: 'biceps', secondaryMuscles: '' },
  { id: 'arm_close_grip_bench', partKey: 'arm', name: '窄距卧推', equipment: 'barbell', movementPattern: 'push', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '窄握卧推', primaryMuscles: 'triceps', secondaryMuscles: 'chest' },
  { id: 'glute_hip_thrust', partKey: 'glute', name: '臀推', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '髋推,杠铃臀推', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_rdl', partKey: 'glute', name: '罗马尼亚硬拉', equipment: 'barbell', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: 'RDL,罗马尼亚拉', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_bridge', partKey: 'glute', name: '臀桥', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 1, isUnilateral: 0, aliases: '桥式,仰卧举髋', primaryMuscles: 'glute', secondaryMuscles: '' },
  { id: 'glute_abduction', partKey: 'glute', name: '髋外展', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '外展机,蝴蝶外展', primaryMuscles: 'glute_medius', secondaryMuscles: '' },
  { id: 'glute_single_leg_thrust', partKey: 'glute', name: '单腿臀推', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 1, isUnilateral: 1, aliases: '单腿髋推', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_single_leg_bridge', partKey: 'glute', name: '单腿臀桥', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 2.5, isBodyweight: 1, isUnilateral: 1, aliases: '单腿桥', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_cable_kickback', partKey: 'glute', name: '绳索后踢', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 1, aliases: '绳索踢腿,髋伸绳索', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_donkey_kick', partKey: 'glute', name: '跪姿髋伸', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '驴踢,跪姿后踢', primaryMuscles: 'glute', secondaryMuscles: '' },
  { id: 'glute_side_lying_abduction', partKey: 'glute', name: '侧卧外展', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '侧卧抬腿', primaryMuscles: 'glute_medius', secondaryMuscles: '' },
  { id: 'glute_band_lateral_walk', partKey: 'glute', name: '弹力带侧步', equipment: 'band', movementPattern: 'isolation', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '怪兽步,横走', primaryMuscles: 'glute_medius', secondaryMuscles: '' },
  { id: 'glute_clamshell', partKey: 'glute', name: '蚌式开合', equipment: 'band', movementPattern: 'isolation', weightStep: 0, isBodyweight: 0, isUnilateral: 1, aliases: '蚌式,侧卧开膝', primaryMuscles: 'glute_medius', secondaryMuscles: '' },
  { id: 'glute_pull_through', partKey: 'glute', name: '绳索拉穿', equipment: 'cable', movementPattern: 'hinge', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '穿拉,胯下拉', primaryMuscles: 'glute', secondaryMuscles: 'hamstring' },
  { id: 'glute_frog_pump', partKey: 'glute', name: '蛙式臀桥', equipment: 'bodyweight', movementPattern: 'hinge', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '蛙泵,蛙式桥', primaryMuscles: 'glute', secondaryMuscles: '' },
  { id: 'leg_squat', partKey: 'leg', name: '杠铃深蹲', equipment: 'barbell', movementPattern: 'squat', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '背蹲,深蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_press', partKey: 'leg', name: '腿举', equipment: 'machine', movementPattern: 'squat', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '倒蹬,腿部推举', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_extension', partKey: 'leg', name: '腿屈伸', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '踢腿器,伸膝', primaryMuscles: 'quad', secondaryMuscles: '' },
  { id: 'leg_curl', partKey: 'leg', name: '腿弯举', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '俯卧腿弯举', primaryMuscles: 'hamstring', secondaryMuscles: '' },
  { id: 'leg_lunge', partKey: 'leg', name: '箭步蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '弓步,前箭步', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_calf_raise', partKey: 'leg', name: '提踵', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '器械提踵', primaryMuscles: 'calf', secondaryMuscles: '' },
  { id: 'leg_front_squat', partKey: 'leg', name: '前蹲', equipment: 'barbell', movementPattern: 'squat', weightStep: 2.5, isBodyweight: 0, isUnilateral: 0, aliases: '前杠深蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_goblet_squat', partKey: 'leg', name: '高脚杯深蹲', equipment: 'kettlebell', movementPattern: 'squat', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '酒杯蹲,壶铃深蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_split_squat', partKey: 'leg', name: '分腿蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '原地分腿蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_bulgarian_split', partKey: 'leg', name: '保加利亚分腿蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '后脚抬高分腿蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_step_up', partKey: 'leg', name: '登阶', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '上台阶,踏步', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_hack_squat', partKey: 'leg', name: '哈克深蹲', equipment: 'machine', movementPattern: 'squat', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: 'Hack 蹲,倒蹬深蹲器', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_seated_curl', partKey: 'leg', name: '坐姿腿弯举', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '坐姿腘绳弯举', primaryMuscles: 'hamstring', secondaryMuscles: '' },
  { id: 'leg_standing_calf', partKey: 'leg', name: '站姿提踵', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '站立提踵', primaryMuscles: 'calf', secondaryMuscles: '' },
  { id: 'leg_seated_calf', partKey: 'leg', name: '坐姿提踵', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '坐姿小腿', primaryMuscles: 'calf', secondaryMuscles: '' },
  { id: 'leg_walking_lunge', partKey: 'leg', name: '行走箭步蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '走步弓箭步', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_reverse_lunge', partKey: 'leg', name: '后箭步蹲', equipment: 'dumbbell', movementPattern: 'lunge', weightStep: 2, isBodyweight: 0, isUnilateral: 1, aliases: '后退弓步', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'leg_sumo_squat', partKey: 'leg', name: '相扑深蹲', equipment: 'dumbbell', movementPattern: 'squat', weightStep: 2, isBodyweight: 0, isUnilateral: 0, aliases: '宽距深蹲,犁式蹲', primaryMuscles: 'quad', secondaryMuscles: 'glute' },
  { id: 'abs_crunch', partKey: 'abs', name: '卷腹', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '仰卧起坐（卷腹）', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_reverse_crunch', partKey: 'abs', name: '反向卷腹', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '反向卷', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_leg_raise', partKey: 'abs', name: '仰卧举腿', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '躺姿举腿', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_machine_crunch', partKey: 'abs', name: '器械卷腹', equipment: 'machine', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '卷腹机', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_cable_crunch', partKey: 'abs', name: '绳索卷腹', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '跪姿绳索卷腹', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_hanging_knee', partKey: 'abs', name: '悬垂举膝', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '悬垂屈膝', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_hanging_leg', partKey: 'abs', name: '悬垂举腿', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '悬垂直腿', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_alt_crunch', partKey: 'abs', name: '交替卷腹', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '交叉卷腹,异侧卷腹', primaryMuscles: 'abs', secondaryMuscles: 'obliques' },
  { id: 'abs_heel_touch', partKey: 'abs', name: '触踵', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '交替触踵,左右摸脚', primaryMuscles: 'abs', secondaryMuscles: 'obliques' },
  { id: 'abs_flutter_kick', partKey: 'abs', name: '交替踢腿', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '扑打踢,剪刀踢', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_decline_crunch', partKey: 'abs', name: '下斜卷腹', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '下斜板卷腹', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'abs_v_up', partKey: 'abs', name: 'V 字起', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: 'V 起,折叠起', primaryMuscles: 'abs', secondaryMuscles: '' },
  { id: 'core_dead_bug', partKey: 'core', name: '死虫式', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '死亡虫', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'core_bird_dog', partKey: 'core', name: '鸟狗式', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '四足对侧伸', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'core_shoulder_tap', partKey: 'core', name: '支撑交替触肩', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '平板支撑拍肩', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'core_pallof', partKey: 'core', name: '抗旋转推', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '帕洛夫推,动态抗旋转', primaryMuscles: 'core', secondaryMuscles: 'obliques' },
  { id: 'core_side_plank_hip', partKey: 'core', name: '侧支撑提髋', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '侧桥抬髋', primaryMuscles: 'core', secondaryMuscles: 'obliques' },
  { id: 'core_up_down', partKey: 'core', name: '支撑起落', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '平板起落,从肘到掌', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'core_russian_twist', partKey: 'core', name: '俄罗斯转体', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '俄式扭转,坐姿转体', primaryMuscles: 'core', secondaryMuscles: 'obliques' },
  { id: 'core_woodchop', partKey: 'core', name: '伐木', equipment: 'cable', movementPattern: 'isolation', weightStep: 5, isBodyweight: 0, isUnilateral: 0, aliases: '绳索劈砍,木斩', primaryMuscles: 'core', secondaryMuscles: 'obliques' },
  { id: 'core_hollow_rock', partKey: 'core', name: '空心体摇摆', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '空心石头,船式摇摆', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'core_body_saw', partKey: 'core', name: '身体锯', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '平板前后滑', primaryMuscles: 'core', secondaryMuscles: '' },
  { id: 'cardio_jump_rope', partKey: 'cardio', name: '跳绳（按次数）', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '跳绳', primaryMuscles: 'cardio', secondaryMuscles: '' },
  { id: 'cardio_jumping_jack', partKey: 'cardio', name: '开合跳（按次数）', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '开合跳,跳跃开合', primaryMuscles: 'cardio', secondaryMuscles: '' },
  { id: 'cardio_mountain_climber', partKey: 'cardio', name: '登山跑（按次数）', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 1, aliases: '登山者,快速交替登阶', primaryMuscles: 'cardio', secondaryMuscles: 'core' },
  { id: 'cardio_burpee', partKey: 'cardio', name: '波比跳（按次数）', equipment: 'bodyweight', movementPattern: 'isolation', weightStep: 0, isBodyweight: 1, isUnilateral: 0, aliases: '立卧撑跳,Burpee', primaryMuscles: 'cardio', secondaryMuscles: '' }
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
