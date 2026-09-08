import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

const base = new URL('../entry/src/main/ets/', import.meta.url);
const context = { $r: (s) => s };
for (const file of ['model/types.ets', 'model/exerciseCatalog.ets', 'model/muscleTypes.ets', 'common/MuscleLogic.ets']) {
  const source = readFileSync(new URL(file, base), 'utf8').replace(/^import[\s\S]*?;\s*$/gm, '').replace(/export /g, '');
  runInNewContext(stripTypeScriptTypes(source), context);
}
runInNewContext('globalThis.api = { MUSCLE_REGIONS, EXERCISE_CATALOG, recommendForMuscle, filterExercises, toggleSelected, isSelected };', context);
const { MUSCLE_REGIONS: regions, EXERCISE_CATALOG: defs, recommendForMuscle: recommend, filterExercises: search, toggleSelected: toggle } = context.api;
assert.equal(regions.length, 18);
for (const region of regions) {
  const recommendations = recommend(region.key, defs, []);
  assert(recommendations.length > 0, region.key);
  assert.equal(new Set(recommendations.map((d) => d.id)).size, recommendations.length);
}
assert(recommend('triceps', defs, []).some((d) => d.id === 'chest_bb_bench' && d.role === '协同'));
assert(recommend('glute_max', defs, []).some((d) => d.id === 'leg_squat'));
assert(recommend('obliques', defs, []).some((d) => d.id === 'core_shoulder_tap'));
const custom = { ...defs[0], id: 'custom_test', name: '我的动作', aliases: 'TEST alias', primaryMuscles: 'chest' };
assert(!recommend('chest', [...defs, custom], []).some((d) => d.id === custom.id));
assert.equal(search([...defs, custom], '  test  ', [custom.id])[0].addedToday, true);
assert.equal(search(defs, '杠铃卧推', [defs[0].id])[0].addedToday, true);
assert.equal(toggle([], defs[0].id, true).length, 0);
assert.equal(toggle(toggle([], 'a', false), 'a', false).length, 0);
console.log('Actual muscle recommendation, cross-part mapping and selection checks passed.');
