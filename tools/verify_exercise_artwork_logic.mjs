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

const appSettings = readFileSync(new URL('../entry/src/main/ets/common/AppSettings.ets', import.meta.url), 'utf8');
const minePage = readFileSync(new URL('../entry/src/main/ets/pages/MinePage.ets', import.meta.url), 'utf8');
assert(appSettings.includes("const KEY_EXERCISE_MODEL_GENDER: string = 'exercise_model_gender'"));
assert(appSettings.includes('loadExerciseModelPreference'));
assert(appSettings.includes('saveExerciseModelPreference'));
assert(minePage.includes("Text('动作模特')"));
assert(minePage.includes("'自动混合'"));
assert(minePage.includes("'女性模特'"));
assert(minePage.includes("'男性模特'"));

const mineHandlers = minePage.slice(minePage.indexOf('struct MinePage'), minePage.indexOf('  build()'))
  .replace('struct MinePage', 'class MinePage')
  .replace(/@(?:Consume|Watch)\([^)]*\)\s*/g, '')
  .replace(/@State\s*/g, '') + '\n}\nglobalThis.MinePage = MinePage;';
const pendingPreferenceSaves = [];
const mineContext = {
  AppSettings: {
    saveExerciseModelPreference: preference => new Promise((resolve, reject) => {
      pendingPreferenceSaves.push({ preference, resolve, reject });
    })
  },
  promptAction: { showToast: () => {} }
};
runInNewContext(stripTypeScriptTypes(mineHandlers), mineContext);
const mine = new mineContext.MinePage();
mine.exerciseModelPreference = 'auto';
const firstChoice = mine.setExerciseModelPreference('female');
const secondChoice = mine.setExerciseModelPreference('male');
assert.deepEqual(pendingPreferenceSaves.map(save => save.preference), ['female', 'male']);
pendingPreferenceSaves[0].reject(new Error('first save failed'));
pendingPreferenceSaves[1].resolve();
await Promise.all([firstChoice, secondChoice]);
assert.equal(mine.exerciseModelPreference, 'male', 'a stale failed save must not roll back a newer choice');

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
