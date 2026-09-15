import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
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

const logic = load('common/ExerciseArtworkLogic.ets', [
  'toExerciseModelPreference',
  'autoGenderForExercise',
  'resolveExerciseModelGender',
  'safeArtworkFrameIndex'
]);
const { toExerciseModelPreference, autoGenderForExercise, resolveExerciseModelGender, safeArtworkFrameIndex } = logic;

assert.equal(toExerciseModelPreference('female'), 'female');
assert.equal(toExerciseModelPreference('male'), 'male');
assert.equal(toExerciseModelPreference('auto'), 'auto');
assert.equal(toExerciseModelPreference('AUTO'), 'auto');
assert.equal(toExerciseModelPreference(''), 'auto');
assert.equal(resolveExerciseModelGender('female', 'leg_squat'), 'female');
assert.equal(resolveExerciseModelGender('male', 'leg_squat'), 'male');
assert.equal(
  resolveExerciseModelGender('auto', 'leg_squat'),
  resolveExerciseModelGender('auto', 'leg_squat')
);
assert(['female', 'male'].includes(autoGenderForExercise('chest_bb_bench')));
assert.equal(safeArtworkFrameIndex(-1, 3), 0);
assert.equal(safeArtworkFrameIndex(8, 3), 0);
assert.equal(safeArtworkFrameIndex(2, 3), 2);
assert.equal(safeArtworkFrameIndex(0, 0), 0);

const { EXERCISE_CATALOG } = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG']);
const counts = { female: 0, male: 0 };
for (const item of EXERCISE_CATALOG) {
  counts[resolveExerciseModelGender('auto', item.id)]++;
}
assert(counts.female >= 40, `female auto distribution ${counts.female}`);
assert(counts.male >= 40, `male auto distribution ${counts.male}`);

console.log(`Auto distribution female=${counts.female}, male=${counts.male}. Exercise artwork logic passed.`);
