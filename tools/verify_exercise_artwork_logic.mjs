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
function createDeferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function createMinePage(loadedPreference = 'auto', loaders = {}) {
  const pendingPreferenceSaves = [];
  const toasts = [];
  const mineContext = {
    AppSettings: {
      loadTheme: loaders.theme ?? (async () => 'light'),
      loadExerciseModelPreference: loaders.preference ?? (async () => loadedPreference),
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

async function waitForPreferenceReads(readCount, count) {
  for (let attempt = 0; attempt < 10 && readCount() < count; attempt++) {
    await Promise.resolve();
  }
  assert.equal(readCount(), count, `expected ${count} preference reads`);
}

{
  const themeLoad = createDeferred();
  const preferenceLoad = createDeferred();
  let preferenceReadCount = 0;
  const { mine, pendingPreferenceSaves, toasts } = createMinePage('auto', {
    theme: () => themeLoad.promise,
    preference: () => {
      preferenceReadCount++;
      return preferenceLoad.promise;
    }
  });
  const loading = mine.load();
  const firstChoice = mine.setExerciseModelPreference('female');
  const visibleAtClick = mine.exerciseModelPreference;
  for (let attempt = 0; attempt < 10; attempt++) await Promise.resolve();
  const readsBeforeTheme = preferenceReadCount;
  themeLoad.resolve('light');
  for (let attempt = 0; attempt < 10 && preferenceReadCount === 0; attempt++) await Promise.resolve();
  assert.equal(preferenceReadCount, 1, 'initial preference read must start independently of theme load');
  const savesBeforePreferenceLoaded = pendingPreferenceSaves.length;
  preferenceLoad.resolve('auto');
  await loading;
  const visibleAfterLoad = mine.exerciseModelPreference;
  await waitForPendingSave(pendingPreferenceSaves, 1);
  assert.equal(pendingPreferenceSaves[0].preference, 'female');
  pendingPreferenceSaves[0].resolve();
  await firstChoice;
  const secondChoice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 2);
  pendingPreferenceSaves[1].reject(new Error('second save failed'));
  await secondChoice;
  assert.equal(readsBeforeTheme, 1, 'preference read must start while theme remains pending');
  assert.equal(visibleAtClick, 'female', 'the early choice must appear immediately');
  assert.equal(savesBeforePreferenceLoaded, 0, 'the first save must wait for the initial preference');
  assert.equal(visibleAfterLoad, 'female', 'the late initial preference must not replace the early choice');
  assert.equal(mine.exerciseModelPreference, 'female', 'a failed later choice must roll back to the saved choice');
  assert.equal(mine.persistedExerciseModelPreference, 'female', 'the persisted baseline must remain the successful choice');
  assert.deepEqual(toasts, ['保存失败，请重试']);
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

if (process.argv[2] !== 'repeated-load') {
  let preferenceReads = 0;
  const { mine, pendingPreferenceSaves, toasts } = createMinePage('auto', {
    theme: async () => { throw new Error('theme load failed'); },
    preference: async () => { preferenceReads++; return 'auto'; }
  });
  const loading = mine.load().catch(error => error);
  const choice = mine.setExerciseModelPreference('female');
  const themeError = await loading;
  assert.equal(themeError.message, 'theme load failed');
  assert.equal(preferenceReads, 1, 'theme rejection must not skip the preference read');
  await waitForPendingSave(pendingPreferenceSaves, 1);
  pendingPreferenceSaves[0].resolve();
  await choice;
  assert.equal(mine.exerciseModelPreference, 'female', 'theme failure must not block preference saving');
  assert.equal(mine.persistedExerciseModelPreference, 'female', 'successful save must update the rollback baseline');
  assert.deepEqual(toasts, [], 'theme failure must not be reported as a preference save failure');
}

if (process.argv[2] !== 'theme-reject') {
  let storedPreference = 'auto';
  let preferenceReads = 0;
  const secondRead = createDeferred();
  const { mine, pendingPreferenceSaves, toasts } = createMinePage('auto', {
    preference: () => {
      preferenceReads++;
      if (preferenceReads === 1) return Promise.resolve(storedPreference);
      const snapshot = storedPreference;
      return secondRead.promise.then(() => snapshot);
    }
  });
  await mine.load();
  const firstChoice = mine.setExerciseModelPreference('female');
  const reloading = mine.load();
  await waitForPendingSave(pendingPreferenceSaves, 1);
  assert.equal(preferenceReads, 1, 'reload must wait for the previously queued save before reading');
  storedPreference = 'female';
  pendingPreferenceSaves[0].resolve();
  await firstChoice;
  await waitForPreferenceReads(() => preferenceReads, 2);
  secondRead.resolve();
  await reloading;
  const failedChoice = mine.setExerciseModelPreference('male');
  await waitForPendingSave(pendingPreferenceSaves, 2);
  pendingPreferenceSaves[1].reject(new Error('later save failed'));
  await failedChoice;
  assert.equal(mine.exerciseModelPreference, 'female', 'later failed save must roll back to the saved choice');
  assert.equal(mine.persistedExerciseModelPreference, 'female', 'stale reload must not replace the saved baseline');
  assert.deepEqual(toasts, ['保存失败，请重试']);
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
