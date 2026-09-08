import { strict as assert } from 'node:assert';
import { readFileSync, existsSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

function load(relative, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
    .replace(/^import .*;\r?\n/gm, '')
    .replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}

const types = load('model/muscleTypes.ets', [
  'MUSCLE_REGIONS',
  'toMuscleKey',
  'muscleName',
  'toWorkoutViewMode'
]);
assert.equal(types.MUSCLE_REGIONS.length, 18);
assert.equal(types.toWorkoutViewMode('exercise'), 'exercise');
assert.equal(types.toWorkoutViewMode('part'), 'part');
assert.equal(types.toWorkoutViewMode('other'), 'part');
for (const region of types.MUSCLE_REGIONS) {
  assert.equal(types.toMuscleKey(region.key), region.key);
  assert.ok(region.name.length > 0);
}

const catalog = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG', 'findExercise']);
const details = load('model/exerciseDetails.ets', ['findExerciseDetail', 'extraSearchText', 'EXERCISE_DETAILS']);
const logic = load('common/MuscleLogic.ets', [
  'muscleFromNodeName',
  'pickVisibleMuscle',
  'isDragGesture',
  'recommendForMuscle',
  'filterExercises',
  'matchesSearch',
  'toggleSelected',
  'planBatchAdd',
  'keysFromLegacyField',
  'mapLegacyMuscleToken',
  'DRAG_THRESHOLD',
  'HitNode'
], { ...types, ...catalog, ...details });

assert.equal(logic.muscleFromNodeName('pick_chest_L'), 'chest');
assert.equal(logic.muscleFromNodeName('pick_chest_R'), 'chest');
assert.equal(logic.muscleFromNodeName('pick_rectus_abdominis'), 'rectus_abdominis');
assert.equal(logic.muscleFromNodeName('base_head'), null);
assert.equal(logic.muscleFromNodeName('rootNode_/BodyRoot/pick_lats_L'), 'lats');

const frontChest = { name: 'pick_chest_L', parentNames: ['BodyRoot'], distance: 1.2 };
const backLats = { name: 'pick_lats_L', parentNames: ['BodyRoot'], distance: 2.4 };
assert.equal(logic.pickVisibleMuscle([backLats, frontChest]), 'chest');
assert.equal(logic.pickVisibleMuscle([{ name: 'base_head', parentNames: [], distance: 0.8 }, backLats]), null);
assert.equal(logic.pickVisibleMuscle([]), null);

assert.equal(logic.isDragGesture(3, 4, 8), false);
assert.equal(logic.isDragGesture(9, 0, 8), true);

assert.equal(logic.mapLegacyMuscleToken('upper_chest'), 'chest');
assert.equal(logic.mapLegacyMuscleToken('posterior_chain'), 'erector_spinae');
assert.equal(logic.mapLegacyMuscleToken('cardio'), null);
assert.equal(JSON.stringify(logic.keysFromLegacyField('triceps,front_delt')), JSON.stringify(['triceps', 'front_delt']));

const { EXERCISE_CATALOG } = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG']);
const oldBench = { ...EXERCISE_CATALOG[0], primaryMuscles: '', secondaryMuscles: '', name: '我的卧推名称' };
const oldBenchRec = logic.recommendForMuscle('chest', [oldBench], []);
assert.equal(oldBenchRec.length, 1, 'legacy builtin rows without muscle metadata use the current preset mapping');
assert.equal(oldBenchRec[0].name, '我的卧推名称', 'recommendations preserve user-visible database names');
const custom = { ...oldBench, id: 'usr_custom', name: '自编胸部动作', partKey: 'chest', primaryMuscles: 'chest' };
assert.equal(logic.recommendForMuscle('chest', [custom], []).length, 0,
  'unmapped custom actions must not be assigned recommendations from legacy metadata');
const duplicatePrimary = logic.recommendForMuscle('chest', [oldBench, oldBench], []);
assert.equal(duplicatePrimary.length, 1, 'duplicate definitions must produce one recommendation');
for (const region of types.MUSCLE_REGIONS) {
  const recs = logic.recommendForMuscle(region.key, EXERCISE_CATALOG, []);
  assert(recs.length > 0, `${region.key} should offer useful preset actions`);
  let secondarySeen = false;
  for (const item of recs) {
    if (item.role === 'secondary') secondarySeen = true;
    else assert.equal(secondarySeen, false, 'primary recommendations precede secondary recommendations');
  }
}
const chestRec = logic.recommendForMuscle('chest', EXERCISE_CATALOG, ['chest_bb_bench']);
assert.ok(chestRec.length > 0);
assert.equal(chestRec[0].role, 'primary');
const ids = chestRec.map((item) => item.id);
assert.equal(new Set(ids).size, ids.length);
const bench = chestRec.find((item) => item.id === 'chest_bb_bench');
assert.ok(bench);
assert.equal(bench.addedToday, true);

const trapsRec = logic.recommendForMuscle('traps', EXERCISE_CATALOG, []);
assert.ok(trapsRec.some((item) => item.id === 'shoulder_face_pull' && item.role === 'secondary'));

const searched = logic.filterExercises(EXERCISE_CATALOG.concat([
  { id: 'usr_1', name: '自编绳索面拉', aliases: 'face pull', primaryMuscles: '', secondaryMuscles: '' }
]), 'face', []);
assert.ok(searched.some((item) => item.id === 'usr_1'));
assert.ok(logic.matchesSearch('杠铃卧推', '', '卧推'));
assert.ok(logic.filterExercises(EXERCISE_CATALOG, 'Barbell Bench', []).some((item) => item.id === 'chest_bb_bench'));
assert.ok(logic.filterExercises(EXERCISE_CATALOG, '平板卧推', []).some((item) => item.id === 'chest_bb_bench'));

let selected = [];
selected = logic.toggleSelected(selected, 'chest_fly', false);
selected = logic.toggleSelected(selected, 'leg_squat', false);
selected = logic.toggleSelected(selected, 'chest_fly', true);
assert.equal(JSON.stringify(selected), JSON.stringify(['chest_fly', 'leg_squat']));
selected = logic.toggleSelected(selected, 'chest_fly', false);
assert.equal(JSON.stringify(selected), JSON.stringify(['leg_squat']));

const plan = logic.planBatchAdd(
  ['chest_fly', 'chest_fly', 'chest_bb_bench', 'leg_squat'],
  ['chest_bb_bench'],
  ['chest_fly', 'chest_bb_bench', 'leg_squat']
);
assert.equal(plan.ok, true);
assert.equal(JSON.stringify(plan.toInsert), JSON.stringify(['chest_fly', 'leg_squat']));

const bad = logic.planBatchAdd(['missing'], [], ['chest_fly']);
assert.equal(bad.ok, false);
assert.equal(bad.toInsert.length, 0);

const glbPath = new URL('../entry/src/main/resources/rawfile/models/body_muscles.glb', import.meta.url);
assert.ok(existsSync(glbPath), 'muscle glb must ship with the app');
const glb = readFileSync(glbPath);
assert.equal(glb.slice(0, 4).toString(), 'glTF');
const jsonLen = glb.readUInt32LE(12);
const json = JSON.parse(glb.slice(20, 20 + jsonLen).toString().trim());
const pickNodes = json.nodes.filter((node) => typeof node.name === 'string' && node.name.startsWith('pick_'));
const keys = new Set();
for (const node of pickNodes) {
  let key = node.name.slice(5);
  if (key.endsWith('_L') || key.endsWith('_R')) {
    key = key.slice(0, -2);
  }
  keys.add(key);
}
for (const region of types.MUSCLE_REGIONS) {
  assert.ok(keys.has(region.key), `glb missing ${region.key}`);
}
assert.ok(existsSync(new URL('../entry/src/main/resources/rawfile/models/LICENSE.txt', import.meta.url)));
assert.ok(existsSync(new URL('../tools/anatomy/ATTRIBUTION.md', import.meta.url)));

console.log(`muscle picker logic + ${pickNodes.length} glb pick nodes passed`);
