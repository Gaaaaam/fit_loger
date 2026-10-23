import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

function load(relative, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
    .replace(/^import .*;\r?\n/gm, '')
    .replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}

const OLD_IDS = [
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

const types = load('model/types.ets', ['toEquipment', 'EQUIPMENT_OPTIONS', 'BODY_PARTS'], { $r: (name) => name });
assert.equal(types.toEquipment('band'), 'band');
assert.equal(types.toEquipment('kettlebell'), 'kettlebell');
assert.equal(types.toEquipment('ezbar'), 'ezbar');
assert.equal(types.toEquipment('mystery'), 'other');
assert(types.EQUIPMENT_OPTIONS.some((item) => item.key === 'band'));
assert(types.EQUIPMENT_OPTIONS.some((item) => item.key === 'other'));

const catalog = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG', 'findExercise']);
const details = load('model/exerciseDetails.ets', [
  'EXERCISE_DETAILS', 'findExerciseDetail', 'extraSearchText', 'difficultyLabel'
]);
const { EXERCISE_CATALOG, findExercise } = catalog;
const { EXERCISE_DETAILS, findExerciseDetail, extraSearchText } = details;
const cardioIds = ['cardio_treadmill', 'cardio_stair_climber', 'cardio_elliptical', 'cardio_stationary_bike', 'cardio_rower'];
const { GENERATED_GUIDANCE_ARTWORK } = load('model/exerciseGuidanceArtwork.generated.ets', ['GENERATED_GUIDANCE_ARTWORK'], { $r: x => x });

assert(EXERCISE_CATALOG.length >= 100 && EXERCISE_CATALOG.length <= 150, `size ${EXERCISE_CATALOG.length}`);
assert.equal(new Set(EXERCISE_CATALOG.map((item) => item.id)).size, EXERCISE_CATALOG.length);
assert.equal(EXERCISE_DETAILS.length, EXERCISE_CATALOG.length);
assert.equal(findExercise('chest_bb_bench').name, '杠铃卧推');
assert.equal(EXERCISE_CATALOG.filter(item => item.recordType === 'reps').length, 120);
assert.equal(EXERCISE_CATALOG.filter(item => item.recordType === 'cardio').length, 5);
for (const id of cardioIds) {
  const item = findExercise(id);
  assert.equal(item.recordType, 'cardio'); assert.equal(item.partKey, 'cardio');
  assert.equal(item.equipment, 'machine'); assert.equal(item.weightStep, 0); assert.equal(item.isBodyweight, 0);
}

for (const id of OLD_IDS) {
  assert(findExercise(id), `missing old id ${id}`);
}

const names = new Set();
for (const item of EXERCISE_CATALOG) {
  const key = `${item.partKey}:${item.name}`;
  assert(!names.has(key), `duplicate ${key}`);
  names.add(key);
  const detail = findExerciseDetail(item.id);
  assert(detail, `missing detail ${item.id}`);
  assert(detail.englishName.length > 0, `english ${item.id}`);
  assert(detail.steps.length >= 2, `steps ${item.id}`);
  assert(detail.counting.length > 0, `counting ${item.id}`);
  if (cardioIds.includes(item.id)) {
    if (!process.argv.includes('--skip-cardio-assets')) {
      const art = GENERATED_GUIDANCE_ARTWORK.find(art => art.id === item.id);
      assert(art, `missing guidance mapping ${item.id}`);
      assert(art.femaleFrames.length >= 2 && art.maleFrames.length === art.femaleFrames.length, `incomplete gender frames ${item.id}`);
      assert.equal(art.frameCaptions.length, art.femaleFrames.length);
      for (const frame of [...art.femaleFrames, ...art.maleFrames]) {
        assert(existsSync(new URL(`../entry/src/main/resources/base/media/${frame.replace('app.media.', '')}.webp`, import.meta.url)), `missing guidance WebP ${frame}`);
      }
    }
  } else {
    assert.equal(item.recordType, 'reps');
    for (const phase of ['card', 'start', 'end']) {
      const svg = new URL(`../entry/src/main/resources/base/media/ex_${item.id}_${phase}.svg`, import.meta.url);
      assert(existsSync(svg), `missing svg ${item.id} ${phase}`);
    }
  }
}
for (const part of types.BODY_PARTS) {
  assert(EXERCISE_CATALOG.some((item) => item.partKey === part.key), `empty part ${part.key}`);
}

const muscle = load('common/MuscleLogic.ets', ['matchesSearch', 'filterExercises'], {
  ...catalog,
  ...details
});
const picker = load('common/ExerciseLogic.ets', ['filterPickerList', 'isCustomExercise', 'joinZh'], {
  ...muscle,
  ...catalog,
  ...details
});

const generated = load('model/exerciseGuidanceArtwork.generated.ets', ['GENERATED_GUIDANCE_ARTWORK'], {
  $r: (name) => name
});
const artworkLogic = load('common/ExerciseArtworkLogic.ets', [
  'resolveExerciseModelGender', 'safeArtworkFrameIndex'
]);
const artwork = load('model/exerciseArtwork.ets', [
  'guidanceArtworkOf', 'guidanceFramesOf', 'guidanceCaptionsOf', 'cardImageOf'
], {
  $r: (name) => name,
  ...generated,
  ...artworkLogic
});
assert.equal(artwork.guidanceArtworkOf('leg_squat').id, 'leg_squat');
assert.equal(artwork.guidanceArtworkOf('usr_1'), null);
assert.equal(artwork.guidanceFramesOf('leg_squat', 'leg', 'female').length, 3);
assert.equal(artwork.guidanceFramesOf('leg_squat', 'leg', 'male').length, 3);
assert.deepEqual([...artwork.guidanceCaptionsOf('core_bird_dog')], ['四点支撑', '对侧伸展']);
assert.equal(artwork.guidanceFramesOf('chest_db_bench', 'chest', 'female').length, 3);
assert.deepEqual([...artwork.guidanceCaptionsOf('chest_db_bench')], ['胸上举铃', '屈肘下放', '弧线推起']);
assert(artwork.cardImageOf('leg_squat', 'leg', 'female').includes('female_03'));
assert(artwork.cardImageOf('usr_1', 'leg', 'female').includes('part_leg'));

const invalidGenerated = [{
  id: 'chest_db_bench',
  femaleFrames: [],
  maleFrames: [],
  frameCaptions: ['不应使用'],
  cardFrameIndex: 99
}];
const invalidArtwork = load('model/exerciseArtwork.ets', [
  'guidanceFramesOf', 'guidanceCaptionsOf', 'cardImageOf'
], {
  $r: (name) => name,
  GENERATED_GUIDANCE_ARTWORK: invalidGenerated,
  ...artworkLogic
});
assert.deepEqual([...invalidArtwork.guidanceFramesOf('chest_db_bench', 'chest', 'female')], [
  'app.media.ex_chest_db_bench_start', 'app.media.ex_chest_db_bench_end'
]);
assert.deepEqual([...invalidArtwork.guidanceCaptionsOf('chest_db_bench')], ['起始', '结束']);
assert.equal(invalidArtwork.cardImageOf('chest_db_bench', 'chest', 'female'), 'app.media.ex_chest_db_bench_card');

const chest = EXERCISE_CATALOG.filter((item) => item.partKey === 'chest');
assert(picker.filterPickerList(chest, 'bench press', '').some((item) => item.id === 'chest_bb_bench'));
assert(picker.filterPickerList(chest, '平板卧推', '').some((item) => item.id === 'chest_bb_bench'));
assert(picker.filterPickerList(chest, '飞鸟', '').some((item) => item.id === 'chest_fly'));
assert(picker.filterPickerList(chest, '', 'cable').every((item) => item.equipment === 'cable'));
assert.equal(picker.filterPickerList(chest, '不存在的动作xyz', '').length, 0);
assert.equal(picker.isCustomExercise('usr_1'), true);
assert.equal(picker.isCustomExercise('chest_bb_bench'), false);
assert.ok(muscle.matchesSearch('杠铃卧推', '', 'Barbell', extraSearchText(findExerciseDetail('chest_bb_bench'))));

const { SQL_CREATE_EXERCISES } = load('db/schemaSql.ets', ['SQL_CREATE_EXERCISES']);
const { seedBuiltinExercises } = load('db/ExerciseSeed.ets', ['seedBuiltinExercises'], catalog);
const db = new DatabaseSync(':memory:');
db.exec(SQL_CREATE_EXERCISES);
const store = { executeSql: async (sql, args) => db.prepare(sql).run(...args) };
await seedBuiltinExercises(store);
db.prepare('UPDATE exercises SET name = ? WHERE id = ?').run('用户保留名称', 'chest_bb_bench');
db.prepare('INSERT INTO exercises (id, name, part_key, equipment, is_builtin, is_archived) VALUES (?,?,?,?,?,?)')
  .run('usr_old', '旧自定义', 'chest', 'band', 0, 0);
await seedBuiltinExercises(store);
assert.equal(db.prepare('SELECT name FROM exercises WHERE id = ?').get('chest_bb_bench').name, '用户保留名称');
assert.equal(db.prepare('SELECT equipment FROM exercises WHERE id = ?').get('usr_old').equipment, 'band');
assert.equal(db.prepare('SELECT count(*) AS n FROM exercises WHERE is_builtin = 1').get().n, EXERCISE_CATALOG.length);
db.close();

assert(existsSync(new URL('../entry/src/main/resources/rawfile/exercises/ATTRIBUTION.md', import.meta.url)));
assert(existsSync(new URL('../entry/src/main/resources/rawfile/exercises/LICENSE.txt', import.meta.url)));
assert(existsSync(new URL('../tools/exercises/curated.json', import.meta.url)));

const sheet = readFileSync(new URL('../entry/src/main/ets/components/ExerciseSheet.ets', import.meta.url), 'utf8');
assert(sheet.includes('详情'));
assert(sheet.includes('ExerciseInfoView'));
assert(sheet.includes('没有匹配的动作'));
assert(sheet.includes('重试'));
assert(sheet.includes('openDetail'));
assert(sheet.includes('savedY'));
assert(sheet.includes('CardItem'));
assert(sheet.includes('filterPickerList'));

const info = readFileSync(new URL('../entry/src/main/ets/components/ExerciseInfoView.ets', import.meta.url), 'utf8');
assert(info.includes('添加动作'));
assert(info.includes('动作步骤'));

const card = readFileSync(new URL('../entry/src/main/ets/components/ExerciseCard.ets', import.meta.url), 'utf8');
assert(card.includes('详情'));
assert(card.includes('onOpenDetail'));

console.log(`Catalog ${EXERCISE_CATALOG.length} exercises, details, SVGs, search, equipment, and seed compatibility passed.`);
