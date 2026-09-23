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
function createMinePage(loadedPreference = 'auto') {
  const pendingPreferenceSaves = [];
  const toasts = [];
  const mineContext = {
    AppSettings: {
      loadTheme: async () => 'light',
      loadExerciseModelPreference: async () => loadedPreference,
      loadHeightCm: async () => 0,
      saveExerciseModelPreference: preference => new Promise((resolve, reject) => {
        pendingPreferenceSaves.push({ preference, resolve, reject });
      })
    },
    WorkoutRepository: {
      loadLatestBodyMetric: async () => ({ hasWeight: false })
    },
    promptAction: { showToast: options => toasts.push(options.message) }
  };
  runInNewContext(stripTypeScriptTypes(mineHandlers), mineContext);
  return { mine: new mineContext.MinePage(), pendingPreferenceSaves, toasts };
}

async function waitForPendingSave(pendingPreferenceSaves, count) {
  for (let attempt = 0; attempt < 10 && pendingPreferenceSaves.length < count; attempt++) {
    await Promise.resolve();
  }
  assert.equal(pendingPreferenceSaves.length, count, `expected ${count} queued preference saves`);
}

{
  const { mine, pendingPreferenceSaves, toasts } = createMinePage();
  await mine.load();
  const firstChoice = mine.setExerciseModelPreference('female');
  const secondChoice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 1);
  assert.equal(pendingPreferenceSaves[0].preference, 'female');
  pendingPreferenceSaves[0].reject(new Error('first save failed'));
  await waitForPendingSave(pendingPreferenceSaves, 2);
  assert.equal(pendingPreferenceSaves[1].preference, 'male');
  pendingPreferenceSaves[1].reject(new Error('second save failed'));
  await Promise.all([firstChoice, secondChoice]);
  assert.equal(mine.exerciseModelPreference, 'auto', 'two failed saves must return to the persisted baseline');
  assert.deepEqual(toasts, ['保存失败，请重试'], 'only the current failed choice should show a toast');
}

{
  const { mine, pendingPreferenceSaves, toasts } = createMinePage();
  await mine.load();
  const firstChoice = mine.setExerciseModelPreference('female');
  const secondChoice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 1);
  pendingPreferenceSaves[0].resolve();
  await waitForPendingSave(pendingPreferenceSaves, 2);
  pendingPreferenceSaves[1].reject(new Error('second save failed'));
  await Promise.all([firstChoice, secondChoice]);
  assert.equal(mine.exerciseModelPreference, 'female', 'a failed second save must return to the first persisted choice');
  assert.deepEqual(toasts, ['保存失败，请重试']);
}

{
  const { mine, pendingPreferenceSaves, toasts } = createMinePage();
  await mine.load();
  const firstChoice = mine.setExerciseModelPreference('female');
  const secondChoice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 1);
  pendingPreferenceSaves[0].reject(new Error('first save failed'));
  await waitForPendingSave(pendingPreferenceSaves, 2);
  pendingPreferenceSaves[1].resolve();
  await Promise.all([firstChoice, secondChoice]);
  assert.equal(mine.exerciseModelPreference, 'male', 'a successful second save must keep the latest choice');
  assert.deepEqual(toasts, [], 'a stale failed choice should not show a toast');
}

{
  const { mine, pendingPreferenceSaves } = createMinePage('female');
  await mine.load();
  const choice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 1);
  pendingPreferenceSaves[0].reject(new Error('save failed'));
  await choice;
  assert.equal(mine.exerciseModelPreference, 'female', 'failed saves must use the loaded persisted preference as baseline');
}

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
