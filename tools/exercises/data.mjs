export const SOURCE = {
  name: 'free-exercise-db',
  url: 'https://github.com/yuhonas/free-exercise-db',
  commit: 'a859101d633a01c4a1a920d6a8ce41dabba0705f',
  license: 'Unlicense',
  licenseUrl: 'https://github.com/yuhonas/free-exercise-db/blob/main/LICENSE.md',
  photoNote: 'Upstream photos are not used. Artwork is original vector illustration.'
};

const EXISTING = new Set([
  'chest_bb_bench', 'chest_db_bench', 'chest_incline_bench', 'chest_fly', 'chest_cable_crossover', 'chest_dip', 'chest_pushup',
  'shoulder_bb_press', 'shoulder_db_press', 'shoulder_lateral_raise', 'shoulder_front_raise', 'shoulder_reverse_fly', 'shoulder_face_pull',
  'back_pullup', 'back_lat_pulldown', 'back_bb_row', 'back_db_row', 'back_seated_row', 'back_deadlift',
  'arm_bb_curl', 'arm_db_curl', 'arm_hammer_curl', 'arm_pushdown', 'arm_skull_crusher',
  'glute_hip_thrust', 'glute_rdl', 'glute_bridge', 'glute_abduction',
  'leg_squat', 'leg_press', 'leg_extension', 'leg_curl', 'leg_lunge', 'leg_calf_raise',
  'abs_crunch', 'abs_reverse_crunch', 'abs_leg_raise',
  'core_dead_bug', 'core_bird_dog', 'core_shoulder_tap',
  'cardio_jump_rope', 'cardio_jumping_jack'
]);

function stepOf(eq, part) {
  if (eq === 'dumbbell' || eq === 'kettlebell') return 2;
  if (eq === 'cable' || eq === 'machine') return 5;
  if (eq === 'bodyweight' || eq === 'band') return (part === 'abs' || part === 'core' || part === 'cardio') ? 0 : 2.5;
  return 2.5;
}

function e(id, part, name, en, eq, pattern, spec) {
  const isBody = eq === 'bodyweight' || spec.isBodyweight === 1 ? 1 : 0;
  return {
    id,
    existing: EXISTING.has(id),
    partKey: part,
    name,
    englishName: en,
    aliases: spec.aliases || [],
    equipment: eq,
    movementPattern: pattern,
    weightStep: spec.weightStep != null ? spec.weightStep : stepOf(eq, part),
    isBodyweight: spec.isBodyweight != null ? spec.isBodyweight : (eq === 'bodyweight' ? 1 : 0),
    isUnilateral: spec.isUnilateral || 0,
    primaryMuscles: spec.pm,
    secondaryMuscles: spec.sm || '',
    primaryMusclesZh: spec.pmZh,
    secondaryMusclesZh: spec.smZh || '无特别强调',
    difficulty: spec.diff || 'beginner',
    startPosition: spec.start,
    steps: spec.steps,
    cues: spec.cues,
    counting: spec.count,
    sourceId: spec.src || '',
    pose: spec.pose
  };
}

export const EXERCISES = [
  e('chest_bb_bench', 'chest', '杠铃卧推', 'Barbell Bench Press', 'barbell', 'push', {
    aliases: ['平板卧推', '杠铃平板卧推'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Barbell_Bench_Press_-_Medium_Grip',
    start: '仰卧于平板凳，双脚踩实地面，杠铃位于眼睛上方，双手略宽于肩握住杠铃。',
    steps: ['收肩胛、挺胸，将杠铃移到乳头线上方。', '吸气下放，肘部约呈 45–70 度，杠铃轻触胸部。', '呼气将杠铃垂直推起至手臂伸直，不要过度弹胸。'],
    cues: ['肩胛持续后收下沉，臀部不要离开凳面。', '手腕与前臂保持竖直，不要翻腕。'],
    count: '杠铃下放至胸再推起至手臂伸直，计 1 次。',
    pose: { family: 'bench_press', kit: 'barbell', incline: 0, cardPhase: 0.15 }
  }),
  e('chest_db_bench', 'chest', '哑铃卧推', 'Dumbbell Bench Press', 'dumbbell', 'push', {
    aliases: ['哑铃平板卧推'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Dumbbell_Bench_Press',
    start: '坐在平板凳一端，双手持哑铃置于膝上，再躺下将哑铃举至胸口上方。',
    steps: ['哑铃位于肩正上方，掌心相对或朝前。', '屈肘下放至上臂与地面接近平行。', '将哑铃沿弧线推回至胸上方，顶端可轻微内收。'],
    cues: ['下放时控制速度，避免肩部向前滚。', '底部不要过度开肘。'],
    count: '两侧哑铃同时下放再推起，计 1 次。',
    pose: { family: 'bench_press', kit: 'dumbbell', incline: 0, cardPhase: 0.18 }
  }),
  e('chest_incline_bench', 'chest', '上斜卧推', 'Incline Barbell Bench Press', 'barbell', 'push', {
    aliases: ['上斜杠铃卧推', '上斜推胸'], pm: 'upper_chest', sm: 'triceps,front_delt', pmZh: '胸大肌上部', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Barbell_Incline_Bench_Press_-_Medium_Grip',
    start: '将凳面调至约 30–45 度，仰卧后双脚踩实，杠铃位于锁骨上方。',
    steps: ['解开杠铃，移到上胸部上方。', '下放至锁骨与乳头之间。', '沿斜面推起至手臂伸直。'],
    cues: ['角度不宜过高，以免变成推肩。', '肩胛贴凳，不要耸肩。'],
    count: '杠铃触碰上胸再推直，计 1 次。',
    pose: { family: 'bench_press', kit: 'barbell', incline: 28, cardPhase: 0.18 }
  }),
  e('chest_fly', 'chest', '飞鸟', 'Dumbbell Flyes', 'dumbbell', 'isolation', {
    aliases: ['哑铃飞鸟', '平板飞鸟'], pm: 'chest', sm: '', pmZh: '胸大肌', smZh: '前束',
    src: 'Dumbbell_Flyes',
    start: '仰卧平板凳，双手持哑铃于胸口上方，肘微屈。',
    steps: ['保持肘部固定微屈，向两侧打开。', '直到胸部有拉伸感、上臂接近水平。', '用胸肌将哑铃沿弧线夹回上方。'],
    cues: ['不要把飞鸟做成推举，肘角全程几乎不变。', '底部不要低于肩太多。'],
    count: '双臂打开再夹拢至胸上，计 1 次。',
    pose: { family: 'fly', kit: 'dumbbell', incline: 0, cardPhase: 0.2 }
  }),
  e('chest_cable_crossover', 'chest', '绳索夹胸', 'Cable Crossover', 'cable', 'isolation', {
    aliases: ['龙门架夹胸', '绳索交叉夹胸'], pm: 'chest', sm: '', pmZh: '胸大肌', smZh: '前束',
    src: 'Cable_Crossover',
    start: '站在龙门架中间，双手各握高位手柄，向前迈一步成弓步，肘微屈。',
    steps: ['略前倾，双手由两侧向身前下方夹拢。', '在身体中线短暂交会或接近。', '控制回到两侧拉伸位。'],
    cues: ['用胸口发力，不要靠甩臂。', '肩胛保持稳定。'],
    count: '双手夹至身前再回到两侧，计 1 次。',
    pose: { family: 'fly', kit: 'cable', incline: 0, cardPhase: 0.75 }
  }),
  e('chest_dip', 'chest', '双杠臂屈伸', 'Chest Dip', 'bodyweight', 'push', {
    aliases: ['双杠撑体', '胸部双杠'], pm: 'chest', sm: 'triceps', pmZh: '胸大肌', smZh: '肱三头肌',
    diff: 'intermediate', src: 'Dips_-_Chest_Version', weightStep: 2.5, isBodyweight: 1,
    start: '双手撑住双杠，手臂伸直，身体略前倾，屈膝离地。',
    steps: ['前倾躯干，屈肘下放至上臂接近平行。', '胸部有拉伸后，推起至手臂伸直。', '不要用腿大幅借力晃动。'],
    cues: ['更前倾、肘略外展偏胸；更直立偏肱三头。', '肩不要过度下沉超过舒适范围。'],
    count: '下放至底部再撑起至手臂伸直，计 1 次。可负重。',
    pose: { family: 'dip', cardPhase: 0.2 }
  }),
  e('chest_pushup', 'chest', '俯卧撑', 'Push-Up', 'bodyweight', 'push', {
    aliases: ['标准俯卧撑'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌', smZh: '肱三头肌、前束',
    src: 'Pushups', weightStep: 2.5, isBodyweight: 1,
    start: '俯撑，双手约肩宽，身体从头到踝成一条直线。',
    steps: ['收腹，屈肘下放至胸部接近地面。', '推起至手臂伸直，肩胛不要塌陷。', '全程保持躯干稳定。'],
    cues: ['髋不要先塌或先抬。', '手掌均匀推地。'],
    count: '胸部接近地面再撑直，计 1 次。',
    pose: { family: 'pushup', cardPhase: 0.2 }
  }),
  e('chest_decline_bench', 'chest', '下斜杠铃卧推', 'Decline Barbell Bench Press', 'barbell', 'push', {
    aliases: ['下斜卧推'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌下部', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Decline_Barbell_Bench_Press',
    start: '仰卧下斜凳，小腿固定，杠铃位于下胸上方。',
    steps: ['解开杠铃至下胸上方。', '下放至下胸部。', '垂直推起至手臂伸直。'],
    cues: ['头低脚高，注意杠铃路径不要滑向颈部。', '不要借助反弹。'],
    count: '杠铃触下胸再推直，计 1 次。',
    pose: { family: 'bench_press', kit: 'barbell', incline: -18, cardPhase: 0.18 }
  }),
  e('chest_incline_db_press', 'chest', '上斜哑铃卧推', 'Incline Dumbbell Press', 'dumbbell', 'push', {
    aliases: ['上斜哑铃推胸'], pm: 'upper_chest', sm: 'triceps,front_delt', pmZh: '胸大肌上部', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Incline_Dumbbell_Press',
    start: '上斜凳 30–45 度，双手持哑铃躺好，哑铃位于上胸两侧。',
    steps: ['哑铃推至上胸上方。', '屈肘下放至上臂接近平行。', '再沿斜面推起。'],
    cues: ['手腕稳定，底部保持胸廓打开。', '避免过度挺腰。'],
    count: '两侧同时下放再推起，计 1 次。',
    pose: { family: 'bench_press', kit: 'dumbbell', incline: 28, cardPhase: 0.18 }
  }),
  e('chest_decline_db_press', 'chest', '下斜哑铃卧推', 'Decline Dumbbell Bench Press', 'dumbbell', 'push', {
    aliases: ['下斜哑铃推胸'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌下部', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Decline_Dumbbell_Bench_Press',
    start: '仰卧下斜凳并固定下肢，双手持哑铃于下胸上方。',
    steps: ['屈肘下放至下胸两侧。', '推起至手臂伸直。', '控制哑铃不要向头侧滑。'],
    cues: ['肩胛贴凳。', '底部停稳再推。'],
    count: '两侧同时完成一次下放与推起，计 1 次。',
    pose: { family: 'bench_press', kit: 'dumbbell', incline: -18, cardPhase: 0.2 }
  }),
  e('chest_incline_fly', 'chest', '上斜哑铃飞鸟', 'Incline Dumbbell Flyes', 'dumbbell', 'isolation', {
    aliases: ['上斜飞鸟'], pm: 'upper_chest', sm: '', pmZh: '胸大肌上部', smZh: '前束',
    src: 'Incline_Dumbbell_Flyes',
    start: '上斜仰卧，双手持哑铃于上胸上方，肘微屈。',
    steps: ['向两侧打开至上胸拉伸。', '保持肘角，沿弧线夹回。', '顶端不要把哑铃撞在一起。'],
    cues: ['动作像拥抱，不是推举。', '重量应轻于卧推。'],
    count: '双臂打开再夹拢，计 1 次。',
    pose: { family: 'fly', kit: 'dumbbell', incline: 28, cardPhase: 0.2 }
  }),
  e('chest_machine_press', 'chest', '器械推胸', 'Machine Bench Press', 'machine', 'push', {
    aliases: ['坐姿推胸器', '固定器械卧推'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌', smZh: '肱三头肌、前束',
    src: 'Machine_Bench_Press',
    start: '坐在推胸器上，背部贴靠垫，把手约在胸中部高度。',
    steps: ['握住把手，推至手臂接近伸直。', '控制回到胸部有拉伸的位置。', '不要在底部完全放松肩胛。'],
    cues: ['座椅高度使手柄对齐乳头线。', '双脚踩实。'],
    count: '把手推远再回到胸口，计 1 次。',
    pose: { family: 'bench_press', kit: 'machine', incline: 8, cardPhase: 0.7 }
  }),
  e('chest_pec_deck', 'chest', '蝴蝶机夹胸', 'Pec Deck / Butterfly', 'machine', 'isolation', {
    aliases: ['蝴蝶机', '器械夹胸'], pm: 'chest', sm: '', pmZh: '胸大肌', smZh: '前束',
    src: 'Butterfly',
    start: '坐在蝴蝶机上，前臂贴靠垫或握住把手，肘与肩同高。',
    steps: ['将两侧挡臂向身体中线夹拢。', '在胸口前短暂停留。', '控制打开至胸部拉伸。'],
    cues: ['肩不要耸起。', '用胸而不是用手推垫。'],
    count: '夹拢再打开一次，计 1 次。',
    pose: { family: 'pecdeck', kind: 'pecdeck', cardPhase: 0.7 }
  }),
  e('chest_close_pushup', 'chest', '窄距俯卧撑', 'Close-Grip Push-Up', 'bodyweight', 'push', {
    aliases: ['钻石俯卧撑', '窄手俯卧撑'], pm: 'chest', sm: 'triceps', pmZh: '胸大肌', smZh: '肱三头肌',
    src: 'Push-Ups_-_Close_Triceps_Position', weightStep: 2.5, isBodyweight: 1,
    start: '俯撑，双手间距小于肩宽，可接近成钻石形。',
    steps: ['屈肘贴近躯干下放。', '胸部接近手后再撑起。', '肘不要大幅外展。'],
    cues: ['更强调肱三头与胸内侧。', '肩保持稳定。'],
    count: '下放再撑起，计 1 次。',
    pose: { family: 'pushup', close: true, cardPhase: 0.2 }
  }),
  e('chest_incline_pushup', 'chest', '上斜俯卧撑', 'Incline Push-Up', 'bodyweight', 'push', {
    aliases: ['手高脚低俯卧撑'], pm: 'chest', sm: 'triceps,front_delt', pmZh: '胸大肌', smZh: '肱三头肌、前束',
    src: 'Incline_Push-Up', weightStep: 2.5, isBodyweight: 1,
    start: '双手撑在稳固的凳面或台阶上，身体成直线，脚在地面。',
    steps: ['屈肘下放至胸部接近支撑面。', '推起至手臂伸直。', '难度随支撑面降低而增加。'],
    cues: ['适合作为标准俯卧撑的退阶。', '髋不要折断。'],
    count: '胸部接近支撑面再撑直，计 1 次。',
    pose: { family: 'pushup', incline: true, cardPhase: 0.25 }
  }),
  e('chest_decline_pushup', 'chest', '下斜俯卧撑', 'Decline Push-Up', 'bodyweight', 'push', {
    aliases: ['脚高手低俯卧撑'], pm: 'upper_chest', sm: 'triceps,front_delt', pmZh: '胸大肌上部', smZh: '肱三头肌、前束',
    diff: 'intermediate', src: 'Decline_Push-Up', weightStep: 2.5, isBodyweight: 1,
    start: '双脚放在凳上，双手撑地，身体成直线。',
    steps: ['屈肘下放至头和胸接近地面。', '推起至手臂伸直。', '不要塌腰。'],
    cues: ['脚越高越难，先用低凳。', '肩不要过度前移超过手腕太多。'],
    count: '下放再撑起，计 1 次。',
    pose: { family: 'pushup', decline: true, cardPhase: 0.2 }
  }),
  e('chest_pullover', 'chest', '哑铃过顶', 'Dumbbell Pullover', 'dumbbell', 'isolation', {
    aliases: ['哑铃拉力器', '仰卧过顶'], pm: 'chest', sm: 'lats', pmZh: '胸大肌', smZh: '背阔肌',
    src: 'Bent-Arm_Dumbbell_Pullover',
    start: '上背横躺凳面或仰卧平板，双手托住一只哑铃于胸口上方。',
    steps: ['微屈肘，将哑铃向头后下方放。', '至胸与背有拉伸后，拉回至胸口上方。', '髋保持稳定。'],
    cues: ['不要过度塌腰。', '肘角基本固定。'],
    count: '哑铃放到头后下方再拉回，计 1 次。',
    pose: { family: 'pullover', kind: 'pullover', cardPhase: 0.2 }
  }),

  e('shoulder_bb_press', 'shoulder', '杠铃推举', 'Barbell Shoulder Press', 'barbell', 'push', {
    aliases: ['站姿推举', '军事推举'], pm: 'front_delt', sm: 'triceps', pmZh: '三角肌前束', smZh: '肱三头肌',
    diff: 'intermediate', src: 'Barbell_Shoulder_Press',
    start: '站立，杠铃置于锁骨上方，双手略宽于肩，核心收紧。',
    steps: ['将杠铃沿面部前方推至头顶上方。', '头部略前移让杠铃到头顶后侧。', '控制下放至锁骨上方。'],
    cues: ['不要过度后仰把腰椎当杠杆。', '肘不要过度后展。'],
    count: '从锁骨推至头顶再放回，计 1 次。',
    pose: { family: 'press', kit: 'barbell', cardPhase: 0.85 }
  }),
  e('shoulder_db_press', 'shoulder', '哑铃推举', 'Dumbbell Shoulder Press', 'dumbbell', 'push', {
    aliases: ['站姿哑铃推举'], pm: 'front_delt', sm: 'triceps', pmZh: '三角肌前束', smZh: '肱三头肌',
    src: 'Dumbbell_Shoulder_Press',
    start: '站立或坐姿，双手持哑铃至耳侧，掌心朝前。',
    steps: ['将哑铃向上推至手臂接近伸直。', '顶端不要猛撞。', '控制放到耳侧。'],
    cues: ['核心绷紧，避免晃肩。', '手腕保持中立。'],
    count: '两侧同时推起再放下，计 1 次。',
    pose: { family: 'press', kit: 'dumbbell', cardPhase: 0.85 }
  }),
  e('shoulder_lateral_raise', 'shoulder', '侧平举', 'Side Lateral Raise', 'dumbbell', 'isolation', {
    aliases: ['侧举', '哑铃侧平举'], pm: 'side_delt', sm: '', pmZh: '三角肌中束', smZh: '斜方肌上部（尽量减少）',
    src: 'Side_Lateral_Raise',
    start: '站立，双手持哑铃于体侧，肘微屈。',
    steps: ['将哑铃向两侧抬至接近肩高。', '短暂停留。', '控制放回体侧。'],
    cues: ['小指略高于拇指，像倒水。', '不要借甩腰和耸肩。'],
    count: '双臂抬至肩高再放下，计 1 次。',
    pose: { family: 'raise', dir: 'side', kit: 'dumbbell', cardPhase: 0.85 }
  }),
  e('shoulder_front_raise', 'shoulder', '前平举', 'Front Dumbbell Raise', 'dumbbell', 'isolation', {
    aliases: ['前举'], pm: 'front_delt', sm: '', pmZh: '三角肌前束', smZh: '胸大肌上部',
    src: 'Front_Dumbbell_Raise',
    start: '站立，哑铃置于大腿前方，肘微屈。',
    steps: ['将哑铃抬至眼前约肩高。', '可交替或同时。', '控制放回。'],
    cues: ['不要摆动躯干。', '顶端不超过眼睛太多。'],
    count: '双臂同时完成一次抬放计 1 次；左右交替时一侧来回计 1 次，左右各完成记为 1 组内的两次。',
    pose: { family: 'raise', dir: 'front', kit: 'dumbbell', cardPhase: 0.85 }
  }),
  e('shoulder_reverse_fly', 'shoulder', '反向飞鸟', 'Reverse Flyes', 'dumbbell', 'isolation', {
    aliases: ['后束飞鸟', '俯身飞鸟'], pm: 'rear_delt', sm: '', pmZh: '三角肌后束', smZh: '上背',
    src: 'Reverse_Flyes',
    start: '髋铰链俯身，背部接近平行地面，双手持哑铃自然下垂。',
    steps: ['肘微屈，向两侧打开至与肩同高。', '挤压后束。', '控制放回。'],
    cues: ['不要用斜方猛提。', '躯干保持不动。'],
    count: '双臂打开再合拢，计 1 次。',
    pose: { family: 'raise', dir: 'rear', kit: 'dumbbell', cardPhase: 0.8 }
  }),
  e('shoulder_face_pull', 'shoulder', '面拉', 'Face Pull', 'cable', 'pull', {
    aliases: ['面部牵引', '绳索面拉'], pm: 'rear_delt', sm: 'upper_back', pmZh: '三角肌后束', smZh: '上背、外旋肌群',
    src: 'Face_Pull',
    start: '绳索调至头上或面部高度，握住绳索两端，后退至手臂伸直。',
    steps: ['将绳索拉向面部，肘向外上方。', '手向外分开，外旋肩。', '控制回到前方。'],
    cues: ['想象把绳子撕开。', '不要做成高位下拉。'],
    count: '拉至面部再放回，计 1 次。',
    pose: { family: 'facepull', kind: 'facepull', cardPhase: 0.8 }
  }),
  e('shoulder_seated_bb_press', 'shoulder', '坐姿杠铃推举', 'Seated Barbell Military Press', 'barbell', 'push', {
    aliases: ['坐姿推举', '靠背推举'], pm: 'front_delt', sm: 'triceps', pmZh: '三角肌前束', smZh: '肱三头肌',
    diff: 'intermediate', src: 'Seated_Barbell_Military_Press',
    start: '坐在有靠背的凳上，杠铃从架上取至锁骨上方。',
    steps: ['沿面部推至头顶。', '控制下放。', '背部贴靠垫，减少借力。'],
    cues: ['比站姿更隔离肩部。', '不要挺腰离开靠垫。'],
    count: '推至头顶再放回锁骨，计 1 次。',
    pose: { family: 'press', kit: 'barbell', sit: true, cardPhase: 0.85 }
  }),
  e('shoulder_arnold', 'shoulder', '阿诺德推举', 'Arnold Press', 'dumbbell', 'push', {
    aliases: ['阿诺推举', '旋转推举'], pm: 'front_delt', sm: 'triceps,side_delt', pmZh: '三角肌前束', smZh: '中束、肱三头肌',
    diff: 'intermediate', src: 'Arnold_Dumbbell_Press',
    start: '坐姿，哑铃置于胸前，掌心朝向自己。',
    steps: ['一边外旋一边向上推。', '至头顶时掌心朝前。', '原路旋转放回胸前。'],
    cues: ['旋转要平滑，不要甩肘。', '重量应轻于普通推举。'],
    count: '从胸前推至头顶再转回，计 1 次。',
    pose: { family: 'press', kit: 'dumbbell', arnold: true, sit: true, cardPhase: 0.7 }
  }),
  e('shoulder_machine_press', 'shoulder', '器械推举', 'Machine Shoulder Press', 'machine', 'push', {
    aliases: ['推肩器'], pm: 'front_delt', sm: 'triceps', pmZh: '三角肌前束', smZh: '肱三头肌',
    src: 'Machine_Shoulder_Military_Press',
    start: '坐在推肩器上，把手约在耳侧。',
    steps: ['向上推至手臂接近伸直。', '控制回到耳侧。', '不要耸肩顶起。'],
    cues: ['座椅高度让起始点在下颌到耳之间。', '背部贴垫。'],
    count: '推起再落下，计 1 次。',
    pose: { family: 'press', kit: 'machine', sit: true, cardPhase: 0.85 }
  }),
  e('shoulder_cable_lateral', 'shoulder', '绳索侧平举', 'Cable Lateral Raise', 'cable', 'isolation', {
    aliases: ['绳索侧举'], pm: 'side_delt', sm: '', pmZh: '三角肌中束', smZh: '无特别强调',
    src: 'Cable_Seated_Lateral_Raise', isUnilateral: 1,
    start: '侧向低位绳索站立，外侧手握住手柄，置于体前或体侧。',
    steps: ['将手柄向外上方抬至肩高。', '停留片刻。', '控制放回。'],
    cues: ['可单臂进行以便更专注。', '身体不要倾斜借力。'],
    count: '单侧抬起再放下计 1 次；左右各做相同次数为一组。',
    pose: { family: 'raise', dir: 'side', kit: 'cable', cardPhase: 0.85 }
  }),
  e('shoulder_cable_rear_fly', 'shoulder', '绳索后束飞鸟', 'Cable Rear Delt Fly', 'cable', 'isolation', {
    aliases: ['绳索反向飞鸟'], pm: 'rear_delt', sm: 'upper_back', pmZh: '三角肌后束', smZh: '上背',
    src: 'Cable_Rear_Delt_Fly',
    start: '站在龙门架中间，双手交叉握住对侧高位或中位手柄。',
    steps: ['向两侧打开至与肩同线。', '挤压后束。', '控制回到身前。'],
    cues: ['肘微屈固定。', '不要做成扩胸过度挺腰。'],
    count: '打开再合拢，计 1 次。',
    pose: { family: 'raise', dir: 'rear', kit: 'cable', cardPhase: 0.8 }
  }),
  e('shoulder_machine_reverse_fly', 'shoulder', '器械反向飞鸟', 'Reverse Machine Flyes', 'machine', 'isolation', {
    aliases: ['反向蝴蝶机', '后束器械'], pm: 'rear_delt', sm: 'upper_back', pmZh: '三角肌后束', smZh: '上背',
    src: 'Reverse_Machine_Flyes',
    start: '面向后束飞鸟机坐下，胸部贴靠垫，握住把手。',
    steps: ['向后打开双臂。', '在后束收缩位停留。', '控制回到前方。'],
    cues: ['胸贴垫，减少借力。', '不要耸肩。'],
    count: '打开再回到前方，计 1 次。',
    pose: { family: 'raise', dir: 'rear', kit: 'machine', cardPhase: 0.8 }
  }),
  e('shoulder_bent_over_raise', 'shoulder', '俯身侧平举', 'Bent-Over Lateral Raise', 'dumbbell', 'isolation', {
    aliases: ['俯身侧举'], pm: 'rear_delt', sm: '', pmZh: '三角肌后束', smZh: '中束',
    src: 'Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench',
    start: '俯身或额头抵凳，双手持哑铃下垂。',
    steps: ['向两侧抬至与肩同高。', '顶峰收缩后束。', '缓慢放下。'],
    cues: ['重量要轻。', '像把哑铃推向远处而不是向上甩。'],
    count: '双臂抬起再放下，计 1 次。',
    pose: { family: 'raise', dir: 'rear', kit: 'dumbbell', cardPhase: 0.82 }
  }),
  e('shoulder_cable_front', 'shoulder', '绳索前平举', 'Cable Front Raise', 'cable', 'isolation', {
    aliases: ['绳索前举'], pm: 'front_delt', sm: '', pmZh: '三角肌前束', smZh: '无特别强调',
    src: '',
    start: '背对或侧向低位绳索，双手或单手握住手柄置于大腿前。',
    steps: ['将手柄向前上方抬至肩高。', '停留。', '控制放回。'],
    cues: ['绳索提供连续张力。', '不要甩腰。'],
    count: '抬至肩高再放下，计 1 次。单手做则左右各计。',
    pose: { family: 'raise', dir: 'front', kit: 'cable', cardPhase: 0.85 }
  }),

  e('back_pullup', 'back', '引体向上', 'Pull-Up', 'bodyweight', 'pull', {
    aliases: ['正手引体'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    diff: 'intermediate', src: 'Pullups', weightStep: 2.5, isBodyweight: 1,
    start: '正手握杠，双手约肩宽或略宽，身体悬垂，肩下沉。',
    steps: ['将胸部拉向杠，肘向后下方。', '下颌过杠或胸部接近杠。', '控制放到悬垂。'],
    cues: ['避免大幅甩腿。', '顶峰不要耸肩缩成一团。'],
    count: '下颌过杠再放到手臂伸直，计 1 次。可负重。',
    pose: { family: 'pull', hanging: true, wide: true, cardPhase: 0.75 }
  }),
  e('back_lat_pulldown', 'back', '高位下拉', 'Lat Pulldown', 'machine', 'pull', {
    aliases: ['下拉', '背阔肌下拉'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: 'Wide-Grip_Lat_Pulldown',
    start: '坐在下拉器上，大腿固定，双手握住横杆。',
    steps: ['将杆拉至锁骨或上胸。', '肘向两侧后下方。', '控制回到高位拉伸。'],
    cues: ['躯干可略后倾，不要大幅后倒甩。', '用背发力而不是只弯肘。'],
    count: '拉至上胸再放回高位，计 1 次。',
    pose: { family: 'pull', hanging: false, wide: true, cardPhase: 0.8 }
  }),
  e('back_bb_row', 'back', '杠铃划船', 'Bent-Over Barbell Row', 'barbell', 'pull', {
    aliases: ['俯身划船'], pm: 'lats', sm: 'biceps,rear_delt', pmZh: '背阔肌', smZh: '肱二头肌、后束',
    diff: 'intermediate', src: 'Bent_Over_Barbell_Row',
    start: '髋铰链俯身，背部接近平坦，杠铃悬于小腿前。',
    steps: ['将杠铃拉向下腹或髋上。', '挤压背部。', '控制放到手臂伸直。'],
    cues: ['脊柱中立，不要上下甩躯干。', '拉向髋更偏背阔，拉向胸口更偏上背。'],
    count: '拉至躯干再放直，计 1 次。',
    pose: { family: 'row', kit: 'barbell', cardPhase: 0.8 }
  }),
  e('back_db_row', 'back', '哑铃划船', 'One-Arm Dumbbell Row', 'dumbbell', 'pull', {
    aliases: ['单臂划船', '单手哑铃划船'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: 'One-Arm_Dumbbell_Row', isUnilateral: 1,
    start: '一侧手膝撑凳，另一手持哑铃自然下垂，背部平坦。',
    steps: ['将哑铃拉向髋侧。', '肘贴近身体。', '控制放到底部拉伸。'],
    cues: ['不要转腰甩动。', '肩胛向后下方收。'],
    count: '单侧拉起再放下计 1 次；左右各完成相同次数为一组。',
    pose: { family: 'row', kit: 'dumbbell', cardPhase: 0.8 }
  }),
  e('back_seated_row', 'back', '坐姿划船', 'Seated Cable Row', 'machine', 'pull', {
    aliases: ['坐姿绳索划船'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌、上背',
    src: 'Seated_Cable_Rows',
    start: '坐在划船器上，双脚踩踏板，握住把手，手臂伸直。',
    steps: ['将把手拉向腹部。', '挺胸收肩胛。', '控制前伸至背阔拉伸，不要过度含胸圆背。'],
    cues: ['拉的时候躯干基本直立。', '不要用下背大幅后仰。'],
    count: '拉至腹再伸直，计 1 次。',
    pose: { family: 'row', kit: 'machine', cardPhase: 0.8 }
  }),
  e('back_deadlift', 'back', '硬拉', 'Barbell Deadlift', 'barbell', 'hinge', {
    aliases: ['传统硬拉'], pm: 'posterior_chain', sm: 'back,glute', pmZh: '后链、竖脊肌', smZh: '背部、臀大肌',
    diff: 'advanced', src: 'Barbell_Deadlift',
    start: '杠铃贴近小腿，髋低于肩，背平坦，双手握杠。',
    steps: ['蹬地伸髋将杠铃拉起至站直。', '顶端髋膝伸展，不要过度后仰。', '髋先向后，控制放回地面。'],
    cues: ['杠铃贴腿走。', '这是髋主导，不是蹲起。'],
    count: '从地面拉至站直再放回，计 1 次。',
    pose: { family: 'hinge', kit: 'barbell', cardPhase: 0.85 }
  }),
  e('back_chinup', 'back', '反手引体', 'Chin-Up', 'bodyweight', 'pull', {
    aliases: ['反握引体向上'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    diff: 'intermediate', src: 'Chin-Up', weightStep: 2.5, isBodyweight: 1,
    start: '反手握杠，双手约肩宽，悬垂。',
    steps: ['将身体拉起，下颌过杠。', '比正手更募集肱二头。', '控制下降。'],
    cues: ['肩先下沉再屈肘。', '避免甩动。'],
    count: '下颌过杠再放到伸直，计 1 次。',
    pose: { family: 'pull', hanging: true, wide: false, cardPhase: 0.75 }
  }),
  e('back_wide_pulldown', 'back', '宽握下拉', 'Wide-Grip Lat Pulldown', 'machine', 'pull', {
    aliases: ['宽握高位下拉'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: 'Wide-Grip_Lat_Pulldown',
    start: '双手宽握横杆，坐稳固定大腿。',
    steps: ['将杆拉至锁骨。', '肘指向两侧下方。', '控制回高位。'],
    cues: ['宽握更强调背阔外侧。', '不要拉到脑后。'],
    count: '拉至锁骨再放回，计 1 次。',
    pose: { family: 'pull', hanging: false, wide: true, cardPhase: 0.82 }
  }),
  e('back_close_pulldown', 'back', '窄握下拉', 'Close-Grip Lat Pulldown', 'machine', 'pull', {
    aliases: ['对握下拉', 'V 把下拉'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: 'Close-Grip_Front_Lat_Pulldown',
    start: '使用 V 把或窄距握杆，坐稳。',
    steps: ['将把手拉向下胸。', '肘贴近身体向前下方。', '控制回到高位。'],
    cues: ['行程可以更长。', '胸挺起。'],
    count: '拉至下胸再放回，计 1 次。',
    pose: { family: 'pull', hanging: false, wide: false, cardPhase: 0.82 }
  }),
  e('back_reverse_pulldown', 'back', '反握下拉', 'Reverse-Grip Lat Pulldown', 'machine', 'pull', {
    aliases: ['反手下拉'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: '',
    start: '反手握住下拉杆，约肩宽，坐稳。',
    steps: ['拉至上胸。', '肘向后。', '控制回高位。'],
    cues: ['肱二头参与更多。', '腕保持中立舒适。'],
    count: '拉至上胸再放回，计 1 次。',
    pose: { family: 'pull', hanging: false, wide: false, cardPhase: 0.82 }
  }),
  e('back_chest_supported_row', 'back', '胸托划船', 'Chest-Supported Row', 'dumbbell', 'pull', {
    aliases: ['上斜划船', '靠胸划船'], pm: 'lats', sm: 'biceps,rear_delt', pmZh: '背阔肌', smZh: '肱二头肌、后束',
    src: 'Dumbbell_Incline_Row',
    start: '俯卧于上斜凳，胸部贴靠，双手持哑铃下垂。',
    steps: ['将哑铃拉向髋或凳侧。', '挤压上背。', '控制放下。'],
    cues: ['减少下背借力。', '头保持中立。'],
    count: '两侧同时拉起再放下，计 1 次。',
    pose: { family: 'row', kit: 'dumbbell', supported: true, cardPhase: 0.8 }
  }),
  e('back_straight_arm_pulldown', 'back', '直臂下拉', 'Straight-Arm Pulldown', 'cable', 'isolation', {
    aliases: ['直臂下压', '背阔直臂下拉'], pm: 'lats', sm: '', pmZh: '背阔肌', smZh: '胸大肌（长头）',
    src: 'Straight-Arm_Pulldown',
    start: '面对高位绳索，双手握住横杆或绳索，手臂伸直微屈，躯干略前倾。',
    steps: ['将手柄沿弧线拉向大腿。', '背阔收缩。', '控制回到头前上方。'],
    cues: ['肘几乎伸直，不是下压肱三头。', '不要甩腰。'],
    count: '拉至大腿再回到高位，计 1 次。',
    pose: { family: 'straightarm', kind: 'straightarm', cardPhase: 0.75 }
  }),
  e('back_hyperextension', 'back', '背伸', 'Back Extension', 'bodyweight', 'hinge', {
    aliases: ['罗马椅', '挺身', '超伸'], pm: 'erector_spinae', sm: 'glute', pmZh: '竖脊肌', smZh: '臀大肌、腘绳肌',
    src: 'Hyperextensions_Back_Extensions', weightStep: 2.5, isBodyweight: 1,
    start: '俯卧于罗马椅，髋垫在髋关节处，上身悬空，双手交叉于胸前。',
    steps: ['下放至躯干与地面约 45–70 度。', '伸髋将躯干抬至与腿成直线。', '不要过度后仰挤压腰椎。'],
    cues: ['用臀和后链，不是猛甩头。', '可抱杠铃片加重。'],
    count: '躯干抬至与腿一条线再放下，计 1 次。',
    pose: { family: 'hyper', kind: 'hyper', cardPhase: 0.85 }
  }),
  e('back_tbar_row', 'back', 'T 杠划船', 'T-Bar Row', 'barbell', 'pull', {
    aliases: ['T杠', '地雷管划船'], pm: 'lats', sm: 'biceps,upper_back', pmZh: '背阔肌', smZh: '上背、肱二头肌',
    diff: 'intermediate', src: 'T-Bar_Row_with_Handle',
    start: '跨站在 T 杠或杠铃一端，俯身握住把手，背平坦。',
    steps: ['将重量拉向胸口。', '挤压中上背。', '控制放下。'],
    cues: ['髋铰链固定。', '不要靠站起来借力。'],
    count: '拉至胸再放直，计 1 次。',
    pose: { family: 'row', kit: 'tbar', cardPhase: 0.8 }
  }),
  e('back_inverted_row', 'back', '反向划船', 'Inverted Row', 'bodyweight', 'pull', {
    aliases: ['水平引体', '桌下划船'], pm: 'lats', sm: 'biceps,upper_back', pmZh: '背阔肌', smZh: '上背、肱二头肌',
    src: 'Inverted_Row', weightStep: 2.5, isBodyweight: 1,
    start: '身体仰卧在低杠下，双手正握，身体成直线，脚踩地或伸直。',
    steps: ['将胸部拉向杠。', '全身保持板状。', '控制放到手臂伸直。'],
    cues: ['脚越前、身体越水平越难。', '髋不要先掉。'],
    count: '胸接近杠再放直，计 1 次。',
    pose: { family: 'inverted', kind: 'inverted', cardPhase: 0.8 }
  }),
  e('back_one_arm_cable_row', 'back', '单臂绳索划船', 'One-Arm Cable Row', 'cable', 'pull', {
    aliases: ['单手高位划船'], pm: 'lats', sm: 'biceps', pmZh: '背阔肌', smZh: '肱二头肌',
    src: 'Kneeling_Single-Arm_High_Pulley_Row', isUnilateral: 1,
    start: '侧向或面对中高位绳索，单手握住手柄，对侧可跪姿或站稳。',
    steps: ['将手柄拉向髋侧或下肋。', '肘向后，躯干少转。', '控制放到手臂伸直后换边。'],
    cues: ['不要大幅转腰。', '拉向髋更偏背阔。'],
    count: '单侧拉起再放直计 1 次；左右各做相同次数为一组。',
    pose: { family: 'row', kit: 'cable', cardPhase: 0.8 }
  }),

  e('arm_bb_curl', 'arm', '杠铃弯举', 'Barbell Curl', 'barbell', 'isolation', {
    aliases: ['站姿杠铃弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '前臂',
    src: 'Barbell_Curl',
    start: '站立，双手反握杠铃于大腿前，肘贴体侧。',
    steps: ['屈肘将杠铃弯至肩前。', '顶端挤压肱二头。', '控制放回。'],
    cues: ['肘不要向前大幅移动。', '不要甩腰。'],
    count: '弯至肩前再放直，计 1 次。',
    pose: { family: 'curl', kit: 'barbell', cardPhase: 0.75 }
  }),
  e('arm_db_curl', 'arm', '哑铃弯举', 'Dumbbell Bicep Curl', 'dumbbell', 'isolation', {
    aliases: ['站姿哑铃弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '前臂',
    src: 'Dumbbell_Bicep_Curl',
    start: '站立，双手持哑铃于体侧，掌心朝前或先朝内再旋外。',
    steps: ['屈肘弯起哑铃。', '可同时或交替。', '控制放下。'],
    cues: ['上臂保持不动。', '底部完全伸展但不甩。'],
    count: '双臂同时完成一次计 1 次；交替时一侧来回计 1 次，左右各一次记两次。',
    pose: { family: 'curl', kit: 'dumbbell', cardPhase: 0.75 }
  }),
  e('arm_hammer_curl', 'arm', '锤式弯举', 'Hammer Curl', 'dumbbell', 'isolation', {
    aliases: ['中立弯举', '锤击弯举'], pm: 'brachialis', sm: 'biceps', pmZh: '肱肌', smZh: '肱二头肌、前臂',
    src: 'Alternate_Hammer_Curl',
    start: '站立，哑铃中立握（掌心相对）于体侧。',
    steps: ['保持中立握屈肘弯起。', '顶端不要内旋。', '控制放下。'],
    cues: ['更打到肱肌和前臂。', '肘贴肋。'],
    count: '同时完成一次计 1 次；交替按单侧计。',
    pose: { family: 'curl', kit: 'dumbbell', cardPhase: 0.75 }
  }),
  e('arm_pushdown', 'arm', '绳索下压', 'Triceps Pushdown', 'cable', 'isolation', {
    aliases: ['下压', '肱三头下压'], pm: 'triceps', sm: '', pmZh: '肱三头肌', smZh: '无特别强调',
    src: 'Cable_Incline_Pushdown',
    start: '面对高位绳索，握住直杆或绳索，肘贴体侧。',
    steps: ['将手柄向下压至手臂伸直。', '挤压肱三头。', '控制回到约 90 度。'],
    cues: ['上臂固定。', '不要含胸甩肩。'],
    count: '压直再回到屈肘，计 1 次。',
    pose: { family: 'pushdown', kind: 'pushdown', cardPhase: 0.8 }
  }),
  e('arm_skull_crusher', 'arm', '仰卧臂屈伸', 'EZ-Bar Skullcrusher', 'barbell', 'isolation', {
    aliases: ['颅骨粉碎者', '躺式臂屈伸'], pm: 'triceps', sm: '', pmZh: '肱三头肌', smZh: '无特别强调',
    diff: 'intermediate', src: 'EZ-Bar_Skullcrusher',
    start: '仰卧，双手持曲杆于胸口上方，手臂伸直。',
    steps: ['只屈肘，将杠放到前额或头后。', '伸肘推回。', '上臂指向天花板基本不动。'],
    cues: ['重量居中，保护肘。', '可放到头后以增加拉伸。'],
    count: '屈肘放下再伸直，计 1 次。',
    pose: { family: 'skull', kind: 'skull', cardPhase: 0.2 }
  }),
  e('arm_incline_curl', 'arm', '上斜弯举', 'Incline Dumbbell Curl', 'dumbbell', 'isolation', {
    aliases: ['上斜哑铃弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌（长头）', smZh: '前臂',
    src: 'Incline_Dumbbell_Curl',
    start: '仰卧于 45–60 度上斜凳，双手持哑铃自然下垂。',
    steps: ['在拉伸位屈肘弯起。', '顶端挤压。', '完全放回拉伸。'],
    cues: ['肩不要向前卷。', '比站姿更难借力。'],
    count: '两侧同时弯起再放下，计 1 次。',
    pose: { family: 'curl', kit: 'dumbbell', cardPhase: 0.7 }
  }),
  e('arm_preacher_curl', 'arm', '牧师凳弯举', 'Preacher Curl', 'ezbar', 'isolation', {
    aliases: ['托臂弯举', '牧师椅'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '前臂',
    src: 'Preacher_Curl',
    start: '坐在牧师凳上，上臂贴靠斜垫，握住曲杆，手臂伸展。',
    steps: ['屈肘将杠弯起。', '不要完全锁死底部若肘不适。', '控制下放。'],
    cues: ['上臂始终贴垫。', '底部慢放。'],
    count: '弯起再放下，计 1 次。',
    pose: { family: 'curl', kit: 'ezbar', preacher: true, cardPhase: 0.7 }
  }),
  e('arm_cable_curl', 'arm', '绳索弯举', 'Cable Bicep Curl', 'cable', 'isolation', {
    aliases: ['低位绳索弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '前臂',
    src: 'Standing_Biceps_Cable_Curl',
    start: '面对低位绳索，反握直杆或手柄，肘贴体侧。',
    steps: ['弯起至肩前。', '绳索保持连续张力。', '控制放回。'],
    cues: ['不要前后晃。', '可使用绳索做锤式。'],
    count: '弯起再放直，计 1 次。',
    pose: { family: 'curl', kit: 'cable', cardPhase: 0.75 }
  }),
  e('arm_concentration_curl', 'arm', '集中弯举', 'Concentration Curl', 'dumbbell', 'isolation', {
    aliases: ['专注弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '无特别强调',
    src: 'Concentration_Curls', isUnilateral: 1,
    start: '坐姿，肘抵在同侧大腿内侧，手持哑铃下垂。',
    steps: ['屈肘将哑铃弯向肩。', '挤压后缓慢放下。', '躯干不要晃。'],
    cues: ['非常隔离。', '视线可看肱二头。'],
    count: '单侧弯起再放下计 1 次；换边做满相同次数。',
    pose: { family: 'concentration', kind: 'concentration', cardPhase: 0.7 }
  }),
  e('arm_overhead_extension', 'arm', '过顶臂屈伸', 'Overhead Triceps Extension', 'dumbbell', 'isolation', {
    aliases: ['颈后臂屈伸', '过头屈伸'], pm: 'triceps', sm: '', pmZh: '肱三头肌（长头）', smZh: '无特别强调',
    src: 'Dumbbell_One-Arm_Triceps_Extension',
    start: '坐姿或站姿，双手或单手将哑铃举过头顶，手臂伸直。',
    steps: ['屈肘将哑铃放到头后。', '伸肘推回头顶。', '肘指向前上方，不要大幅外展。'],
    cues: ['核心收紧。', '单手做则左右分别计次。'],
    count: '双侧同时做时下放再伸直计 1 次；单手则单侧计 1 次。',
    pose: { family: 'ohext', kind: 'ohext', kit: 'dumbbell', cardPhase: 0.25 }
  }),
  e('arm_one_arm_pushdown', 'arm', '单臂下压', 'One-Arm Cable Pushdown', 'cable', 'isolation', {
    aliases: ['单手绳索下压'], pm: 'triceps', sm: '', pmZh: '肱三头肌', smZh: '无特别强调',
    src: 'Cable_One_Arm_Tricep_Extension', isUnilateral: 1,
    start: '侧向或面对高位绳索，单手握住手柄，肘贴肋。',
    steps: ['将手柄向下压直。', '挤压后控制回 90 度。', '完成一侧再换边。'],
    cues: ['可掌心向下或中立。', '上臂锁死。'],
    count: '单侧压直再回到屈肘计 1 次；左右各做相同次数。',
    pose: { family: 'pushdown', kind: 'pushdown', cardPhase: 0.8 }
  }),
  e('arm_kickback', 'arm', '臂屈伸踢后', 'Tricep Kickback', 'dumbbell', 'isolation', {
    aliases: ['肱三头踢腿', '俯身臂屈伸'], pm: 'triceps', sm: '', pmZh: '肱三头肌', smZh: '无特别强调',
    src: 'Tricep_Dumbbell_Kickback', isUnilateral: 1,
    start: '俯身，上臂贴体侧与地面平行，手持哑铃，肘屈 90 度。',
    steps: ['伸肘将哑铃向后踢直至手臂伸直。', '挤压肱三头。', '屈肘回到 90 度。'],
    cues: ['上臂始终平行地面。', '重量宜轻。'],
    count: '单侧伸直再屈回计 1 次；左右分别计。',
    pose: { family: 'kickback_arm', kind: 'kickback_arm', cardPhase: 0.85 }
  }),
  e('arm_wrist_curl', 'arm', '腕弯举', 'Wrist Curl', 'barbell', 'isolation', {
    aliases: ['前臂弯举'], pm: 'forearm', sm: '', pmZh: '前臂屈肌', smZh: '无特别强调',
    src: 'Palms-Up_Barbell_Wrist_Curl_Over_A_Bench',
    start: '前臂放在凳上或大腿上，手腕伸出，反握杠铃或哑铃。',
    steps: ['向上弯腕。', '可在底部让杠略滚动至手指再卷回。', '控制放下。'],
    cues: ['小幅度，不要甩肘。', '重量不要过大。'],
    count: '弯腕再放下，计 1 次。',
    pose: { family: 'wrist', kind: 'wrist', cardPhase: 0.7 }
  }),
  e('arm_reverse_wrist', 'arm', '反向腕弯举', 'Reverse Wrist Curl', 'barbell', 'isolation', {
    aliases: ['前臂伸腕'], pm: 'forearm', sm: '', pmZh: '前臂伸肌', smZh: '无特别强调',
    src: 'Palms-Down_Wrist_Curl_Over_A_Bench',
    start: '前臂支撑，正握杠铃，手腕伸出凳沿。',
    steps: ['向上伸腕。', '控制放回。', '幅度小于屈腕。'],
    cues: ['重量明显轻于腕弯举。', '前臂贴实。'],
    count: '伸腕再放下，计 1 次。',
    pose: { family: 'wrist', kind: 'wrist', cardPhase: 0.7 }
  }),
  e('arm_ez_curl', 'arm', '曲杆弯举', 'EZ-Bar Curl', 'ezbar', 'isolation', {
    aliases: ['EZ 杠弯举', '弯杆弯举'], pm: 'biceps', sm: '', pmZh: '肱二头肌', smZh: '前臂',
    src: 'EZ-Bar_Curl',
    start: '站立，握住曲杆斜把，杠置于大腿前。',
    steps: ['屈肘弯起。', '曲杆减少腕部压力。', '控制放下。'],
    cues: ['选自己舒服的斜握角度。', '肘贴体侧。'],
    count: '弯起再放直，计 1 次。',
    pose: { family: 'curl', kit: 'ezbar', cardPhase: 0.75 }
  }),
  e('arm_close_grip_bench', 'arm', '窄距卧推', 'Close-Grip Bench Press', 'barbell', 'push', {
    aliases: ['窄握卧推'], pm: 'triceps', sm: 'chest', pmZh: '肱三头肌', smZh: '胸大肌、前束',
    diff: 'intermediate', src: 'Close-Grip_Barbell_Bench_Press',
    start: '仰卧平板，双手间距约与肩同宽或略窄，握住杠铃。',
    steps: ['下放至下胸，肘贴近躯干。', '推起至手臂伸直。', '不要握得过窄压迫腕。'],
    cues: ['这是复合推，但主打肱三头。', '肩胛稳定同普通卧推。'],
    count: '下放再推直，计 1 次。',
    pose: { family: 'bench_press', kit: 'barbell', incline: 0, cardPhase: 0.18 }
  }),

  e('glute_hip_thrust', 'glute', '臀推', 'Barbell Hip Thrust', 'barbell', 'hinge', {
    aliases: ['髋推', '杠铃臀推'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    diff: 'intermediate', src: 'Barbell_Hip_Thrust',
    start: '上背靠凳，杠铃垫于髋，双脚平放，小腿接近垂直。',
    steps: ['伸髋将杠铃推起至肩、髋、膝一条线。', '顶峰挤压臀部。', '控制下放。'],
    cues: ['不要过度挺腰。', '下巴微收。'],
    count: '髋推至顶再放下，计 1 次。',
    pose: { family: 'bridge', bar: true, cardPhase: 0.85 }
  }),
  e('glute_rdl', 'glute', '罗马尼亚硬拉', 'Romanian Deadlift', 'barbell', 'hinge', {
    aliases: ['RDL', '罗马尼亚拉'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    diff: 'intermediate', src: 'Romanian_Deadlift',
    start: '站直持杠于大腿前，膝微屈。',
    steps: ['髋向后推，杠贴腿下放至腘绳拉伸。', '背保持平坦。', '伸髋站直。'],
    cues: ['杠不离腿。', '不是蹲，膝角度变化很小。'],
    count: '放到拉伸位再站直，计 1 次。',
    pose: { family: 'hinge', kit: 'barbell', cardPhase: 0.2 }
  }),
  e('glute_bridge', 'glute', '臀桥', 'Glute Bridge', 'bodyweight', 'hinge', {
    aliases: ['桥式', '仰卧举髋'], pm: 'glute', sm: '', pmZh: '臀大肌', smZh: '腘绳肌',
    src: 'Barbell_Glute_Bridge', weightStep: 2.5, isBodyweight: 1,
    start: '仰卧，屈膝，脚平放，手臂置于体侧。',
    steps: ['伸髋将臀部抬起。', '顶峰挤压。', '控制放下。'],
    cues: ['用臀不是用腰。', '可把杠铃放髋上加重。'],
    count: '髋抬至顶再放下，计 1 次。',
    pose: { family: 'bridge', bar: false, cardPhase: 0.85 }
  }),
  e('glute_abduction', 'glute', '髋外展', 'Hip Abduction', 'machine', 'isolation', {
    aliases: ['外展机', '蝴蝶外展'], pm: 'glute_medius', sm: '', pmZh: '臀中肌', smZh: '臀大肌上部',
    src: '',
    start: '坐在外展机上，双膝抵住挡垫。',
    steps: ['将双腿向外打开。', '在外侧停留。', '控制合拢。'],
    cues: ['不要借甩。', '躯干保持直立。'],
    count: '打开再合拢，计 1 次。',
    pose: { family: 'abduction', kind: 'machine', cardPhase: 0.8 }
  }),
  e('glute_single_leg_thrust', 'glute', '单腿臀推', 'Single-Leg Hip Thrust', 'bodyweight', 'hinge', {
    aliases: ['单腿髋推'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    src: '', isUnilateral: 1, weightStep: 2.5, isBodyweight: 1,
    start: '上背靠凳，一脚踩地，另一腿抬起。',
    steps: ['用支撑腿伸髋推起。', '骨盆保持水平。', '控制下放后换边。'],
    cues: ['不要向支撑侧塌。', '可负重。'],
    count: '单侧推起再放下计 1 次；左右各做相同次数。',
    pose: { family: 'bridge', bar: false, single: true, cardPhase: 0.85 }
  }),
  e('glute_single_leg_bridge', 'glute', '单腿臀桥', 'Single-Leg Glute Bridge', 'bodyweight', 'hinge', {
    aliases: ['单腿桥'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    src: 'Single_Leg_Glute_Bridge', isUnilateral: 1, weightStep: 2.5, isBodyweight: 1,
    start: '仰卧屈膝，一脚踩地，另一腿伸直或屈髋举起。',
    steps: ['支撑腿把髋推起。', '顶峰停顿。', '放下后换边。'],
    cues: ['骨盆不要旋转。', '比双腿臀桥更难。'],
    count: '单侧抬髋再放下计 1 次；左右分别计。',
    pose: { family: 'bridge', single: true, cardPhase: 0.85 }
  }),
  e('glute_cable_kickback', 'glute', '绳索后踢', 'Cable Kickback', 'cable', 'isolation', {
    aliases: ['绳索踢腿', '髋伸绳索'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    src: '', isUnilateral: 1,
    start: '面对低位绳索，脚踝套住，略前倾扶稳。',
    steps: ['向后上方踢腿至髋伸展。', '挤压臀部。', '控制回到前方，不要靠甩腰。'],
    cues: ['膝可微屈。', '躯干尽量固定。'],
    count: '单侧后踢再收回计 1 次；换边做满。',
    pose: { family: 'kickback', cable: true, cardPhase: 0.8 }
  }),
  e('glute_donkey_kick', 'glute', '跪姿髋伸', 'Donkey Kick', 'bodyweight', 'isolation', {
    aliases: ['驴踢', '跪姿后踢'], pm: 'glute', sm: '', pmZh: '臀大肌', smZh: '腘绳肌',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '四肢着地，双手在肩下，膝在髋下。',
    steps: ['保持膝屈约 90 度，将一脚向后上方蹬。', '髋伸展到底。', '放回后再换边或做完一侧。'],
    cues: ['不要把腰过度塌下去。', '脚后跟向天花板。'],
    count: '单侧蹬出再收回计 1 次；左右各计。',
    pose: { family: 'kickback', cable: false, cardPhase: 0.8 }
  }),
  e('glute_side_lying_abduction', 'glute', '侧卧外展', 'Side-Lying Hip Abduction', 'bodyweight', 'isolation', {
    aliases: ['侧卧抬腿'], pm: 'glute_medius', sm: '', pmZh: '臀中肌', smZh: '无特别强调',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '侧卧，身体成直线，下方腿微屈，上方腿伸直。',
    steps: ['将上方腿向外上方抬起。', '脚尖略内扣。', '控制放下，不要前后摆。'],
    cues: ['动的是髋外展不是腰。', '可加沙袋或弹力带。'],
    count: '单侧抬起再放下计 1 次；完成一侧再换边。',
    pose: { family: 'abduction', kind: 'side', cardPhase: 0.8 }
  }),
  e('glute_band_lateral_walk', 'glute', '弹力带侧步', 'Banded Lateral Walk', 'band', 'isolation', {
    aliases: ['怪兽步', '横走'], pm: 'glute_medius', sm: '', pmZh: '臀中肌', smZh: '臀大肌',
    src: 'Monster_Walk',
    start: '弹力带套在膝上或踝上，半蹲，双脚与肩同宽。',
    steps: ['向一侧迈步，保持带宽张力。', '另一脚跟上，不要并拢失张。', '走若干步后反向。'],
    cues: ['始终半蹲。', '脚不要内八。'],
    count: '向一侧迈一步并跟上计 1 次；左右方向分别记次数或按总步数记。',
    pose: { family: 'abduction', kind: 'walk', cardPhase: 0.7 }
  }),
  e('glute_clamshell', 'glute', '蚌式开合', 'Clamshell', 'band', 'isolation', {
    aliases: ['蚌式', '侧卧开膝'], pm: 'glute_medius', sm: '', pmZh: '臀中肌', smZh: '无特别强调',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 0,
    start: '侧卧，髋膝屈曲，双脚并拢，可在膝上套弹力带。',
    steps: ['上方膝向外打开，双脚仍接触。', '在外侧停留。', '缓慢合拢。'],
    cues: ['骨盆不要后滚。', '幅度不必很大。'],
    count: '单侧打开再合拢计 1 次；左右分别计。',
    pose: { family: 'abduction', kind: 'clam', cardPhase: 0.8 }
  }),
  e('glute_pull_through', 'glute', '绳索拉穿', 'Pull Through', 'cable', 'hinge', {
    aliases: ['穿拉', '胯下拉'], pm: 'glute', sm: 'hamstring', pmZh: '臀大肌', smZh: '腘绳肌',
    src: 'Pull_Through',
    start: '背对低位绳索，双手从胯下握住绳索，向前走至有张力，髋铰链。',
    steps: ['伸髋站直，绳索贴身。', '顶峰挤压臀。', '髋后再回到铰链。'],
    cues: ['手臂只是挂钩。', '像 RDL 的绳索版。'],
    count: '站直再铰链回去，计 1 次。',
    pose: { family: 'pullthrough', kind: 'pullthrough', cardPhase: 0.8 }
  }),
  e('glute_frog_pump', 'glute', '蛙式臀桥', 'Frog Pump', 'bodyweight', 'hinge', {
    aliases: ['蛙泵', '蛙式桥'], pm: 'glute', sm: '', pmZh: '臀大肌', smZh: '臀中肌',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '仰卧，双脚掌相对，膝向外打开，髋外旋。',
    steps: ['伸髋把臀部泵起。', '顶峰挤压。', '小幅度快速或标准节奏均可。'],
    cues: ['膝保持打开。', '适合高次数。'],
    count: '髋上再下，计 1 次。',
    pose: { family: 'bridge', cardPhase: 0.85 }
  }),

  e('leg_squat', 'leg', '杠铃深蹲', 'Barbell Back Squat', 'barbell', 'squat', {
    aliases: ['背蹲', '深蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    diff: 'intermediate', src: 'Barbell_Full_Squat',
    start: '杠铃置于上背，双手握杠，站距约肩宽，脚略外展。',
    steps: ['吸气，屈髋屈膝下蹲。', '至大腿至少平行。', '蹬地站直。'],
    cues: ['膝与脚尖方向一致。', '腰背中立。'],
    count: '下蹲再站直，计 1 次。',
    pose: { family: 'squat', kit: 'barbell', cardPhase: 0.15 }
  }),
  e('leg_press', 'leg', '腿举', 'Leg Press', 'machine', 'squat', {
    aliases: ['倒蹬', '腿部推举'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Leg_Press',
    start: '坐在腿举机上，双脚置于踏板中部，放下安全销。',
    steps: ['屈膝下放至舒适深度。', '推起至膝接近伸直但不锁死。', '腰始终贴靠垫。'],
    cues: ['不要借手推膝。', '脚位高低改变刺激。'],
    count: '屈膝再推直，计 1 次。',
    pose: { family: 'leg_machine', press: true, cardPhase: 0.25 }
  }),
  e('leg_extension', 'leg', '腿屈伸', 'Leg Extension', 'machine', 'isolation', {
    aliases: ['踢腿器', '伸膝'], pm: 'quad', sm: '', pmZh: '股四头肌', smZh: '无特别强调',
    src: '',
    start: '坐在腿屈伸机上，踝垫在脚背上方，背部贴靠。',
    steps: ['伸膝将腿踢直。', '顶端挤压股四头。', '控制放下。'],
    cues: ['不要猛甩。', '座椅让膝与转轴对齐。'],
    count: '伸直再放下，计 1 次。',
    pose: { family: 'leg_machine', extension: true, cardPhase: 0.85 }
  }),
  e('leg_curl', 'leg', '腿弯举', 'Lying Leg Curl', 'machine', 'isolation', {
    aliases: ['俯卧腿弯举'], pm: 'hamstring', sm: '', pmZh: '腘绳肌', smZh: '小腿',
    src: 'Lying_Leg_Curls',
    start: '俯卧于腿弯举机，踝垫在跟腱上方。',
    steps: ['屈膝将垫子拉向臀部。', '挤压腘绳。', '控制放回。'],
    cues: ['髋不要离开垫面。', '底部不要完全甩开。'],
    count: '弯起再放直，计 1 次。',
    pose: { family: 'leg_machine', curl: true, cardPhase: 0.8 }
  }),
  e('leg_lunge', 'leg', '箭步蹲', 'Dumbbell Lunge', 'dumbbell', 'lunge', {
    aliases: ['弓步', '前箭步'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Dumbbell_Lunges', isUnilateral: 1,
    start: '双手持哑铃于体侧，向前迈一大步。',
    steps: ['双膝屈曲至前膝约 90 度。', '后膝接近地面。', '蹬前脚回站立，换腿或走步。'],
    cues: ['前膝不要过度内扣。', '躯干略直。'],
    count: '一侧下蹲再回站计 1 次；左右交替时按单侧计，或约定左右各一次记 2 次。',
    pose: { family: 'lunge', kit: 'dumbbell', cardPhase: 0.2 }
  }),
  e('leg_calf_raise', 'leg', '提踵', 'Calf Raise', 'machine', 'isolation', {
    aliases: ['器械提踵'], pm: 'calf', sm: '', pmZh: '小腿三头肌', smZh: '无特别强调',
    src: 'Standing_Calf_Raises',
    start: '在提踵器上，肩抵垫，前脚掌站在踏板上，脚跟悬空。',
    steps: ['脚跟尽量下沉拉伸。', '踮起至最高。', '控制下降。'],
    cues: ['膝保持伸直或固定微屈。', '不要弹震。'],
    count: '踮起再放下，计 1 次。',
    pose: { family: 'calf', sit: false, cardPhase: 0.85 }
  }),
  e('leg_front_squat', 'leg', '前蹲', 'Front Squat', 'barbell', 'squat', {
    aliases: ['前杠深蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌、核心',
    diff: 'advanced', src: 'Front_Squat_Clean_Grip',
    start: '杠铃置于前肩三角肌上，肘抬高，核心收紧。',
    steps: ['保持肘高下蹲。', '躯干比背蹲更直立。', '蹬地站直。'],
    cues: ['肘掉则杠会滚。', '可高翻握或交叉握。'],
    count: '下蹲再站直，计 1 次。',
    pose: { family: 'squat', kit: 'barbell', cardPhase: 0.15 }
  }),
  e('leg_goblet_squat', 'leg', '高脚杯深蹲', 'Goblet Squat', 'kettlebell', 'squat', {
    aliases: ['酒杯蹲', '壶铃深蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Goblet_Squat',
    start: '双手在胸前托住壶铃或哑铃，肘向下。',
    steps: ['下蹲至肘靠近膝内侧。', '挺胸。', '站直。'],
    cues: ['适合学习深蹲轨迹。', '重量贴胸。'],
    count: '下蹲再站直，计 1 次。',
    pose: { family: 'squat', kit: 'dumbbell', goblet: true, cardPhase: 0.18 }
  }),
  e('leg_split_squat', 'leg', '分腿蹲', 'Split Squat', 'dumbbell', 'lunge', {
    aliases: ['原地分腿蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Split_Squats', isUnilateral: 1,
    start: '前后分腿站立，双手可持哑铃，重心在两脚之间。',
    steps: ['原地屈膝下蹲。', '前膝与后膝同时屈曲。', '蹬起，不换脚直到该侧做完。'],
    cues: ['比箭步蹲更稳定。', '后脚只辅助平衡。'],
    count: '单侧一次下蹲站起计 1 次；做完一侧再换边。',
    pose: { family: 'lunge', kit: 'dumbbell', cardPhase: 0.2 }
  }),
  e('leg_bulgarian_split', 'leg', '保加利亚分腿蹲', 'Bulgarian Split Squat', 'dumbbell', 'lunge', {
    aliases: ['后脚抬高分腿蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    diff: 'intermediate', src: 'Elevated_Back_Lunge', isUnilateral: 1,
    start: '后脚放在凳上，前脚向前迈出足够距离，双手持哑铃。',
    steps: ['前腿屈膝下蹲。', '躯干略前倾可更打臀。', '蹬前脚站起。'],
    cues: ['前脚要够远，避免膝盖过脚尖过多。', '不要用后脚猛蹬。'],
    count: '单侧下蹲站起计 1 次；左右分别完成。',
    pose: { family: 'lunge', kit: 'dumbbell', cardPhase: 0.18 }
  }),
  e('leg_step_up', 'leg', '登阶', 'Step-Up', 'dumbbell', 'lunge', {
    aliases: ['上台阶', '踏步'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Dumbbell_Step_Ups', isUnilateral: 1,
    start: '面对稳固箱子或凳，双手可持哑铃。',
    steps: ['一脚踏上，用该腿把身体带上。', '在箱上站直。', '控制下来，减少另一腿借力。'],
    cues: ['箱高约到膝。', '上箱那条腿才是工作腿。'],
    count: '单侧上箱再下来计 1 次；左右交替或做完一侧再换。',
    pose: { family: 'lunge', kit: 'dumbbell', step: true, cardPhase: 0.7 }
  }),
  e('leg_hack_squat', 'leg', '哈克深蹲', 'Hack Squat', 'machine', 'squat', {
    aliases: ['Hack 蹲', '倒蹬深蹲器'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    diff: 'intermediate', src: 'Hack_Squat',
    start: '肩抵哈克机垫，双脚置于踏板，解开安全销。',
    steps: ['屈膝下蹲。', '至大腿平行或更深。', '推起至膝接近伸直。'],
    cues: ['腰贴垫。', '脚越前越偏臀，越后越偏股四。'],
    count: '下蹲再推起，计 1 次。',
    pose: { family: 'squat', kit: 'machine', cardPhase: 0.18 }
  }),
  e('leg_seated_curl', 'leg', '坐姿腿弯举', 'Seated Leg Curl', 'machine', 'isolation', {
    aliases: ['坐姿腘绳弯举'], pm: 'hamstring', sm: '', pmZh: '腘绳肌', smZh: '无特别强调',
    src: 'Seated_Leg_Curl',
    start: '坐在坐姿弯举机上，踝后抵垫，大腿被固定。',
    steps: ['屈膝将小腿向下向后弯。', '挤压腘绳。', '控制伸直。'],
    cues: ['髋被固定，更隔离腘绳。', '不要借手拉把手甩。'],
    count: '弯起再伸直，计 1 次。',
    pose: { family: 'leg_machine', curl: true, cardPhase: 0.8 }
  }),
  e('leg_standing_calf', 'leg', '站姿提踵', 'Standing Calf Raise', 'machine', 'isolation', {
    aliases: ['站立提踵'], pm: 'calf', sm: '', pmZh: '腓肠肌', smZh: '比目鱼肌',
    src: 'Standing_Calf_Raises',
    start: '站在台阶或器械上，膝伸直，前脚掌支撑。',
    steps: ['脚跟下沉。', '踮到最高。', '慢下。'],
    cues: ['膝伸直更打腓肠肌。', '两侧均匀。'],
    count: '踮起再放下，计 1 次。',
    pose: { family: 'calf', sit: false, cardPhase: 0.88 }
  }),
  e('leg_seated_calf', 'leg', '坐姿提踵', 'Seated Calf Raise', 'machine', 'isolation', {
    aliases: ['坐姿小腿'], pm: 'calf', sm: '', pmZh: '比目鱼肌', smZh: '腓肠肌',
    src: 'Seated_Calf_Raise',
    start: '坐在提踵器上，膝屈约 90 度，膝上压垫，前脚掌在踏板上。',
    steps: ['脚跟下沉拉伸。', '踮起。', '控制下降。'],
    cues: ['屈膝更打比目鱼。', '行程要完整。'],
    count: '踮起再放下，计 1 次。',
    pose: { family: 'calf', sit: true, cardPhase: 0.85 }
  }),
  e('leg_walking_lunge', 'leg', '行走箭步蹲', 'Walking Lunge', 'dumbbell', 'lunge', {
    aliases: ['走步弓箭步'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Barbell_Walking_Lunge', isUnilateral: 1,
    start: '双手持哑铃，向前行走空间充足。',
    steps: ['向前迈步下蹲。', '后腿蹬起，下一步换另一腿。', '连续行走。'],
    cues: ['步幅稳定。', '可持杠铃于背。'],
    count: '每迈出一步并完成下蹲计 1 次（单侧一步）；左右各一步记 2 次。',
    pose: { family: 'lunge', kit: 'dumbbell', cardPhase: 0.25 }
  }),
  e('leg_reverse_lunge', 'leg', '后箭步蹲', 'Reverse Lunge', 'dumbbell', 'lunge', {
    aliases: ['后退弓步'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌',
    src: 'Dumbbell_Rear_Lunge', isUnilateral: 1,
    start: '站立持哑铃，向后退一步。',
    steps: ['后膝下降。', '前腿承重。', '蹬前脚回到并立。'],
    cues: ['通常比前箭步更膝友好。', '躯干微前倾打臀。'],
    count: '一侧后退下蹲再回站计 1 次；左右分别或交替计。',
    pose: { family: 'lunge', kit: 'dumbbell', cardPhase: 0.2 }
  }),
  e('leg_sumo_squat', 'leg', '相扑深蹲', 'Sumo Squat', 'dumbbell', 'squat', {
    aliases: ['宽距深蹲', '犁式蹲'], pm: 'quad', sm: 'glute', pmZh: '股四头肌', smZh: '臀大肌、内收肌',
    src: '',
    start: '站距明显宽于肩，脚外展，双手于身前持哑铃或壶铃。',
    steps: ['屈膝下蹲，膝指向脚尖。', '躯干尽量直立。', '蹬地站直。'],
    cues: ['髋外展打开。', '不要变成体前屈。'],
    count: '下蹲再站直，计 1 次。',
    pose: { family: 'squat', kit: 'dumbbell', goblet: true, cardPhase: 0.18 }
  }),

  e('abs_crunch', 'abs', '卷腹', 'Crunch', 'bodyweight', 'isolation', {
    aliases: ['仰卧起坐（卷腹）'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '腹斜肌',
    src: 'Crunches', weightStep: 0, isBodyweight: 1,
    start: '仰卧，屈膝，脚平放，双手置于耳侧或胸前。',
    steps: ['将肩胛卷离地面。', '下背保持贴地。', '缓慢放回。'],
    cues: ['是卷不是甩头。', '不要用手拉脖子。'],
    count: '肩胛离地再放下，计 1 次。',
    pose: { family: 'crunch', cardPhase: 0.8 }
  }),
  e('abs_reverse_crunch', 'abs', '反向卷腹', 'Reverse Crunch', 'bodyweight', 'isolation', {
    aliases: ['反向卷'], pm: 'abs', sm: '', pmZh: '腹直肌下部', smZh: '髋屈肌',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '仰卧，髋膝屈曲，小腿可抬起。',
    steps: ['将髋卷离地面，膝向胸口。', '骨盆后倾。', '控制放回。'],
    cues: ['用腹而不是猛甩腿。', '下背不要借惯性拍打地面。'],
    count: '髋离地再放下，计 1 次。',
    pose: { family: 'crunch', reverse: true, cardPhase: 0.8 }
  }),
  e('abs_leg_raise', 'abs', '仰卧举腿', 'Lying Leg Raise', 'bodyweight', 'isolation', {
    aliases: ['躺姿举腿'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '髋屈肌',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '仰卧，双手可握身侧或垫在臀下，双腿伸直。',
    steps: ['将双腿向上举起至接近垂直。', '可在顶端将髋微微卷起。', '控制放下至离地数厘米。'],
    cues: ['下背尽量贴地。', '膝可微屈减难。'],
    count: '双腿举起再放下，计 1 次。',
    pose: { family: 'legraise', kind: 'legraise', cardPhase: 0.8 }
  }),
  e('abs_machine_crunch', 'abs', '器械卷腹', 'Ab Crunch Machine', 'machine', 'isolation', {
    aliases: ['卷腹机'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '无特别强调',
    src: 'Ab_Crunch_Machine',
    start: '坐在卷腹机上，胸垫或把手置于胸前，调整配重。',
    steps: ['将躯干卷向大腿。', '挤压腹肌。', '控制回到起始。'],
    cues: ['用腹不是用手臂猛拉。', '底部不要完全放松弹回。'],
    count: '卷到底再回，计 1 次。',
    pose: { family: 'crunch', kit: 'machine', cardPhase: 0.8 }
  }),
  e('abs_cable_crunch', 'abs', '绳索卷腹', 'Cable Crunch', 'cable', 'isolation', {
    aliases: ['跪姿绳索卷腹'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '无特别强调',
    src: 'Cable_Crunch',
    start: '跪在高位绳索前，双手握住绳索置于头侧。',
    steps: ['屈髋屈脊柱将肘向膝卷。', '挤压腹直肌。', '控制伸直但不站起。'],
    cues: ['是卷脊柱不是鞠躬甩髋。', '髋位置相对固定。'],
    count: '卷到底再回到伸展，计 1 次。',
    pose: { family: 'crunch', kit: 'cable', cardPhase: 0.75 }
  }),
  e('abs_hanging_knee', 'abs', '悬垂举膝', 'Hanging Knee Raise', 'bodyweight', 'isolation', {
    aliases: ['悬垂屈膝'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '髋屈肌',
    diff: 'intermediate', src: '', weightStep: 0, isBodyweight: 1,
    start: '双手悬垂于单杠，身体稳定，肩下沉。',
    steps: ['屈髋屈膝将膝抬向胸口。', '骨盆后倾。', '控制放下。'],
    cues: ['减少摆动。', '比直腿举腿容易。'],
    count: '双膝上举再放下，计 1 次。',
    pose: { family: 'hanging', kind: 'hanging', cardPhase: 0.8 }
  }),
  e('abs_hanging_leg', 'abs', '悬垂举腿', 'Hanging Leg Raise', 'bodyweight', 'isolation', {
    aliases: ['悬垂直腿'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '髋屈肌',
    diff: 'advanced', src: 'Hanging_Leg_Raise', weightStep: 0, isBodyweight: 1,
    start: '悬垂于单杠，双腿伸直。',
    steps: ['将双腿抬至至少平行地面。', '高级者可抬至杠。', '控制下降，抑制钟摆。'],
    cues: ['先学举膝。', '可在双杠支撑架上进行。'],
    count: '双腿举起再放下，计 1 次。',
    pose: { family: 'hanging', kind: 'hanging', cardPhase: 0.85 }
  }),
  e('abs_alt_crunch', 'abs', '交替卷腹', 'Cross-Body Crunch', 'bodyweight', 'isolation', {
    aliases: ['交叉卷腹', '异侧卷腹'], pm: 'abs', sm: 'obliques', pmZh: '腹直肌', smZh: '腹斜肌',
    src: 'Cross-Body_Crunch', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '仰卧屈膝，双手置于耳侧。',
    steps: ['右肘向左膝方向卷。', '放回后换左侧。', '肩胛离地。'],
    cues: ['是旋转卷腹不是自行车的完整蹬腿。', '不要拉头。'],
    count: '一侧卷起计 1 次；左右各一次记 2 次。',
    pose: { family: 'crunch', cardPhase: 0.8 }
  }),
  e('abs_heel_touch', 'abs', '触踵', 'Heel Touch', 'bodyweight', 'isolation', {
    aliases: ['交替触踵', '左右摸脚'], pm: 'abs', sm: 'obliques', pmZh: '腹斜肌', smZh: '腹直肌',
    src: 'Alternate_Heel_Touchers', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '仰卧屈膝，肩微离地，双臂置于体侧。',
    steps: ['向右侧屈，手指触右脚跟。', '回到中间再触左侧。', '肩保持微微离地。'],
    cues: ['小幅度侧屈。', '颈部放松。'],
    count: '触一侧脚跟计 1 次；左右各触一次记 2 次。',
    pose: { family: 'crunch', cardPhase: 0.6 }
  }),
  e('abs_flutter_kick', 'abs', '交替踢腿', 'Flutter Kick', 'bodyweight', 'isolation', {
    aliases: ['扑打踢', '剪刀踢'], pm: 'abs', sm: '', pmZh: '腹直肌下部', smZh: '髋屈肌',
    src: 'Flutter_Kicks', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '仰卧，双手垫臀或握身侧，双腿伸直离地。',
    steps: ['左右腿交替小幅度上下踢。', '下背贴地。', '腿尽量伸直。'],
    cues: ['幅度小而快或按节奏。', '腰痛则屈膝或缩短时间。'],
    count: '一只脚完成一次上下为 1 次；也可按左右各一次记 2 次，需全程同一口径。',
    pose: { family: 'legraise', kind: 'legraise', cardPhase: 0.5 }
  }),
  e('abs_decline_crunch', 'abs', '下斜卷腹', 'Decline Crunch', 'bodyweight', 'isolation', {
    aliases: ['下斜板卷腹'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '髋屈肌',
    src: 'Decline_Crunch', weightStep: 0, isBodyweight: 1,
    start: '坐在下斜凳上，小腿固定，上身后仰，双手置于耳侧。',
    steps: ['将躯干卷向大腿。', '不要完全躺平若过难。', '控制后仰。'],
    cues: ['比平板卷腹更难。', '可抱杠铃片。'],
    count: '卷起再后仰，计 1 次。',
    pose: { family: 'crunch', cardPhase: 0.75 }
  }),
  e('abs_v_up', 'abs', 'V 字起', 'V-Up', 'bodyweight', 'isolation', {
    aliases: ['V 起', '折叠起'], pm: 'abs', sm: '', pmZh: '腹直肌', smZh: '髋屈肌',
    diff: 'intermediate', src: 'Cocoons', weightStep: 0, isBodyweight: 1,
    start: '仰卧，手脚伸直。',
    steps: ['同时抬起躯干和双腿，手脚在空中靠近。', '身体成 V 形。', '控制放回。'],
    cues: ['可先做屈膝版本。', '不要靠甩。'],
    count: '手脚靠近再放回，计 1 次。',
    pose: { family: 'crunch', reverse: true, cardPhase: 0.8 }
  }),

  e('core_dead_bug', 'core', '死虫式', 'Dead Bug', 'bodyweight', 'isolation', {
    aliases: ['死亡虫'], pm: 'core', sm: '', pmZh: '核心、腹直肌', smZh: '腹斜肌',
    src: 'Dead_Bug', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '仰卧，髋膝 90 度，双臂指向天花板，下背贴地。',
    steps: ['对侧手臂与腿缓慢伸展。', '下背始终贴地。', '收回后换边。'],
    cues: ['宁慢勿拱腰。', '呼气帮助收腹。'],
    count: '一侧伸展再收回计 1 次；左右各一次记 2 次。',
    pose: { family: 'dead_bug', cardPhase: 0.7 }
  }),
  e('core_bird_dog', 'core', '鸟狗式', 'Bird Dog', 'bodyweight', 'isolation', {
    aliases: ['四足对侧伸'], pm: 'core', sm: '', pmZh: '核心、竖脊肌', smZh: '臀、肩稳定',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '四肢着地，脊柱中立。',
    steps: ['伸出对侧手臂与腿，与躯干成直线。', '骨盆不要旋转。', '收回后换边。'],
    cues: ['想象杯子放在腰上。', '不要过度抬头。'],
    count: '一侧伸展再收回计 1 次；左右交替各一次记 2 次。',
    pose: { family: 'bird_dog', cardPhase: 0.85 }
  }),
  e('core_shoulder_tap', 'core', '支撑交替触肩', 'Shoulder Tap', 'bodyweight', 'isolation', {
    aliases: ['平板支撑拍肩'], pm: 'core', sm: '', pmZh: '核心', smZh: '肩稳定、腹斜肌',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '高位平板支撑，双手在肩下，身体成直线。',
    steps: ['一手轻触对侧肩。', '髋尽量不晃。', '放回后换手。'],
    cues: ['双脚可略宽增稳。', '这是计次抗旋转，不是计时平板。'],
    count: '触一次肩计 1 次；左右各触一次记 2 次。',
    pose: { family: 'tap', kind: 'tap', cardPhase: 0.7 }
  }),
  e('core_pallof', 'core', '抗旋转推', 'Pallof Press', 'cable', 'isolation', {
    aliases: ['帕洛夫推', '动态抗旋转'], pm: 'core', sm: 'obliques', pmZh: '腹斜肌、核心', smZh: '肩带',
    src: 'Pallof_Press_With_Rotation',
    start: '侧向绳索站立，双手握手柄于胸口，双脚与肩同宽。',
    steps: ['将手柄向前推直。', '抵抗被拉转，可在伸直位短暂停留或小幅旋转再回。', '收回到胸口。'],
    cues: ['髋肩正对前方。', '不要被配重转走。'],
    count: '推直再收回计 1 次；完成一侧后转身做另一侧。',
    pose: { family: 'core', kind: 'pallof', cardPhase: 0.8 }
  }),
  e('core_side_plank_hip', 'core', '侧支撑提髋', 'Side Plank Hip Lift', 'bodyweight', 'isolation', {
    aliases: ['侧桥抬髋'], pm: 'core', sm: 'obliques', pmZh: '腹斜肌、核心', smZh: '臀中肌',
    src: '', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '侧卧，肘在肩下支撑，脚叠放或前后分开，髋先着地。',
    steps: ['将髋向上推起成侧直线。', '停留片刻。', '控制放下但不完全放松，再推起。'],
    cues: ['肩堆在肘上。', '这是计次抬髋，不是计时长支撑。'],
    count: '单侧髋上再下计 1 次；做完一侧换边。',
    pose: { family: 'core', kind: 'side', cardPhase: 0.85 }
  }),
  e('core_up_down', 'core', '支撑起落', 'Plank Up-Down', 'bodyweight', 'isolation', {
    aliases: ['平板起落', '从肘到掌'], pm: 'core', sm: '', pmZh: '核心', smZh: '肩、肱三头',
    src: 'Body-Up', isUnilateral: 0, weightStep: 0, isBodyweight: 1,
    start: '肘支撑平板开始，身体成直线。',
    steps: ['一手撑起至掌，再另一手撑起成高位支撑。', '再依次回到肘撑。', '交替先动手以平衡两侧。'],
    cues: ['髋尽量不左右扭。', '完整一来一回为一轮。'],
    count: '从肘撑到掌撑再回到肘撑，计 1 次。可约定先左或先右，组内保持一致。',
    pose: { family: 'core', kind: 'updown', cardPhase: 0.6 }
  }),
  e('core_russian_twist', 'core', '俄罗斯转体', 'Russian Twist', 'bodyweight', 'isolation', {
    aliases: ['俄式扭转', '坐姿转体'], pm: 'core', sm: 'obliques', pmZh: '腹斜肌', smZh: '腹直肌',
    src: 'Russian_Twist', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '坐地，躯干后倾，双脚离地或着地，双手合于身前。',
    steps: ['将双手转到一侧。', '再转到另一侧。', '可持杠铃片加重。'],
    cues: ['转的是胸椎不是只甩手。', '脚着地较易。'],
    count: '转到一侧计 1 次；左右各一次记 2 次。',
    pose: { family: 'core', kind: 'twist', cardPhase: 0.7 }
  }),
  e('core_woodchop', 'core', '伐木', 'Cable Woodchop', 'cable', 'isolation', {
    aliases: ['绳索劈砍', '木斩'], pm: 'core', sm: 'obliques', pmZh: '腹斜肌、核心', smZh: '肩带',
    src: '',
    start: '侧向高位或中位绳索，双手握住手柄于外侧上方。',
    steps: ['将手柄斜向对侧髋下劈。', '髋可小幅转动但膝稳定。', '控制回到高位。'],
    cues: ['对角线发力。', '低位往高拉则是反向伐木。'],
    count: '劈一次再回到高位计 1 次；换边做另一侧。',
    pose: { family: 'core', kind: 'chop', cardPhase: 0.4 }
  }),
  e('core_hollow_rock', 'core', '空心体摇摆', 'Hollow Body Rock', 'bodyweight', 'isolation', {
    aliases: ['空心石头', '船式摇摆'], pm: 'core', sm: '', pmZh: '腹直肌、核心', smZh: '髋屈肌',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '仰卧成空心体：下背贴地，肩和腿离地，手脚伸展。',
    steps: ['保持空心体形状前后小幅摇摆。', '腰不离开地面。', '幅度以能维持形状为准。'],
    cues: ['先能稳住空心体再摇摆。', '这是计次摇摆，不是计时平板。'],
    count: '向前再向后完成一个来回，计 1 次。',
    pose: { family: 'core', kind: 'hollow', cardPhase: 0.8 }
  }),
  e('core_body_saw', 'core', '身体锯', 'Body Saw', 'bodyweight', 'isolation', {
    aliases: ['平板前后滑'], pm: 'core', sm: '', pmZh: '核心', smZh: '肩',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '肘撑平板，双脚踩滑盘或穿袜子在滑面上。',
    steps: ['将身体向后推，肩角变大。', '再拉回至标准平板。', '全程保持一条直线。'],
    cues: ['不要塌腰。', '无滑面时可改用小幅度前后移动肩。'],
    count: '向后推再拉回，计 1 次。',
    pose: { family: 'core', kind: 'saw', cardPhase: 0.6 }
  }),

  e('cardio_jump_rope', 'cardio', '跳绳（按次数）', 'Jump Rope', 'bodyweight', 'isolation', {
    aliases: ['跳绳'], pm: 'cardio', sm: '', pmZh: '心肺、小腿', smZh: '全身',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '双手握绳于髋侧，绳在身后，微屈膝。',
    steps: ['甩绳用腕，前脚掌轻跳。', '每次跳跃让绳通过脚下。', '保持节奏，落地缓冲。'],
    cues: ['本应用按次记录，不记时长。', '双摇可按每次通过脚下计。'],
    count: '绳子每通过脚下 1 次计 1 次；双摇一次通过计 1 次。',
    pose: { family: 'cardio', kind: 'rope', cardPhase: 0.5 }
  }),
  e('cardio_jumping_jack', 'cardio', '开合跳（按次数）', 'Jumping Jack', 'bodyweight', 'isolation', {
    aliases: ['开合跳', '跳跃开合'], pm: 'cardio', sm: '', pmZh: '心肺', smZh: '肩、髋外展',
    src: '', weightStep: 0, isBodyweight: 1,
    start: '站立，双脚并拢，双手置于体侧。',
    steps: ['跳起同时双脚打开、双手上举。', '再跳回并拢。', '落地屈膝缓冲。'],
    cues: ['按完整开合计次。', '不记时长。'],
    count: '打开再合拢为 1 次。',
    pose: { family: 'cardio', kind: 'jack', cardPhase: 0.85 }
  }),
  e('cardio_mountain_climber', 'cardio', '登山跑（按次数）', 'Mountain Climber', 'bodyweight', 'isolation', {
    aliases: ['登山者', '快速交替登阶'], pm: 'cardio', sm: 'core', pmZh: '心肺、核心', smZh: '髋屈肌',
    src: 'Mountain_Climbers', isUnilateral: 1, weightStep: 0, isBodyweight: 1,
    start: '高位支撑，身体成直线。',
    steps: ['一膝快速向胸口收。', '换另一腿，像跑步。', '髋不要过度抬高。'],
    cues: ['本应用按次记录。', '保持肩在手腕上方。'],
    count: '一侧膝盖向前收再换边，每收一次计 1 次；左右各一次记 2 次。',
    pose: { family: 'cardio', kind: 'mountain', cardPhase: 0.6 }
  }),
  e('cardio_burpee', 'cardio', '波比跳（按次数）', 'Burpee', 'bodyweight', 'isolation', {
    aliases: ['立卧撑跳', 'Burpee'], pm: 'cardio', sm: '', pmZh: '心肺、全身', smZh: '胸、腿、核心',
    diff: 'intermediate', src: '', weightStep: 0, isBodyweight: 1,
    start: '站立。',
    steps: ['下蹲双手撑地，双脚后蹬成俯撑。', '可选择做一次俯卧撑。', '双脚收回，跳起举手过顶。'],
    cues: ['约定本组是否含俯卧撑，保持一致。', '只按完整动作计次，不记时长。'],
    count: '从站立到跳起落地为 1 次；是否含俯卧撑在备注中统一。',
    pose: { family: 'cardio', kind: 'burpee', cardPhase: 0.3 }
  })
];
