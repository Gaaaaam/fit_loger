import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

// Run production ArkTS methods against SQLite. Only the platform RdbStore adapter is replaced.
function load(path, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${path}`, import.meta.url), 'utf8')
    .replace(/^import[\s\S]*?from\s+['"][^'"]+['"];\r?\n/gm, '')
    .replace(/@Observed\s*/g, '').replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}
const types = load('model/types.ets', ['toPartKey', 'partName', 'toEquipment', 'toSetStatus'], { $r: x => x });
const muscles = load('model/muscleTypes.ets', ['toMuscleKey', 'MUSCLE_REGIONS']);
const catalog = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG', 'findExercise']);
const logic = load('common/WorkoutLogic.ets', ['formatWeight', 'formatLastHint', 'groupExercisesByPart', 'GroupEx', 'HintSet', 'parseWeight', 'parseReps']);
const muscleLogic = load('common/MuscleLogic.ets', ['planBatchAdd', 'BatchPlan', 'recommendForMuscle'], { ...muscles, ...catalog });
const models = load('model/DayModels.ets', ['DayModel', 'PartItem', 'ExerciseItem', 'SetItem']);
const schema = load('db/schemaSql.ets', ['SQL_CREATE_EXERCISES', 'SQL_CREATE_WORKOUT_DAYS', 'SQL_CREATE_DAY_EXERCISES', 'SQL_CREATE_WORKOUT_SETS']);
const { seedBuiltinExercises } = load('db/ExerciseSeed.ets', ['seedBuiltinExercises'], catalog);
const db = new DatabaseSync(':memory:');
for (const sql of Object.values(schema)) db.exec(sql);
let atBegin = null;
let insertCount = 0;
let failInsertAt = -1;
let afterUpdate = null;
class Predicates {
  constructor(table) { this.table = table; this.conditions = []; }
  equalTo(key, value) { this.conditions.push([key, value]); return this; }
}
class ResultSet {
  constructor(rows) { this.rows = rows; this.index = -1; this.columns = Object.keys(rows[0] ?? {}); }
  goToFirstRow() { this.index = 0; return this.rows.length > 0; }
  goToNextRow() { return ++this.index < this.rows.length; }
  getColumnIndex(key) { return this.columns.indexOf(key); }
  isColumnNull(index) { return this.rows[this.index][this.columns[index]] == null; }
  getString(index) { return String(this.rows[this.index][this.columns[index]]); }
  getLong(index) { return Number(this.rows[this.index][this.columns[index]]); }
  getDouble(index) { return this.getLong(index); }
  close() {}
}
const store = {
  querySql: async (sql, args = []) => new ResultSet(db.prepare(sql).all(...args)),
  executeSql: async (sql, args = []) => db.prepare(sql).run(...args),
  beginTransaction: () => { if (atBegin) { const f = atBegin; atBegin = null; f(); } db.exec('BEGIN'); },
  commit: () => db.exec('COMMIT'),
  rollBack: () => db.exec('ROLLBACK'),
  update: async (values, predicate) => {
    const keys = Object.keys(values);
    db.prepare(`UPDATE ${predicate.table} SET ${keys.map(key => `${key} = ?`).join(',')} WHERE ${predicate.conditions.map(([key]) => `${key} = ?`).join(' AND ')}`)
      .run(...keys.map(key => values[key]), ...predicate.conditions.map(([, value]) => value));
    if (afterUpdate) { const f = afterUpdate; afterUpdate = null; await f(); }
  },
  insert: async (table, values) => {
    if (table === 'day_exercises' && ++insertCount === failInsertAt) throw new Error('injected write failure');
    const keys = Object.keys(values);
    return Number(db.prepare(`INSERT INTO ${table} (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`)
      .run(...keys.map(key => values[key])).lastInsertRowid);
  }
};
const { WorkoutRepository: repository } = load('db/WorkoutRepository.ets', ['WorkoutRepository'], {
  ...types, ...logic, ...models, ...muscleLogic,
  relationalStore: { RdbPredicates: Predicates },
  WorkoutDatabase: { getStore: () => store, logError: () => {} }
});
await seedBuiltinExercises(store);
const count = table => db.prepare(`SELECT count(*) AS n FROM ${table}`).get().n;
assert.equal(await repository.addExercisesBatch('2026-09-01', ['leg_squat', 'chest_bb_bench', 'leg_squat', 'back_deadlift']), 3);
assert.equal(await repository.addExercisesBatch('2026-09-01', ['chest_bb_bench']), 0);
assert.deepEqual(Array.from(await repository.listAddedExerciseIds('2026-09-01')), ['leg_squat', 'chest_bb_bench', 'back_deadlift']);
assert.equal(count('workout_sets'), 0, 'adding actions must not invent sets');
let day = await repository.loadDay('2026-09-01');
for (const exercise of day.exercises) {
  assert.equal(day.parts.flatMap(part => part.exercises).find(ex => ex.id === exercise.id), exercise,
    'mode views must share each ExerciseItem, including unsaved input');
  const loaded = await repository.loadExerciseRow(exercise.id, '2026-09-01');
  assert.equal(loaded.sortOrder, exercise.sortOrder);
}
const rowsBeforeFailure = count('day_exercises');
failInsertAt = insertCount + 2;
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'leg_curl']));
assert.equal(count('day_exercises'), rowsBeforeFailure, 'partial insert must roll back');
assert.equal(count('workout_days'), 1, 'failed batch must not leave an empty day');
failInsertAt = -1;
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'missing']));
assert.equal(count('workout_days'), 1);

// A pending change can land between initial reads and BEGIN; validation must see the transaction snapshot.
atBegin = () => db.prepare('UPDATE exercises SET is_archived = 1 WHERE id = ?').run('leg_curl');
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'leg_curl']),
  'archived exercise must be rejected even when archive completes just before the transaction');
assert.equal(count('workout_days'), 1);
atBegin = () => db.prepare('INSERT INTO day_exercises(day_id, exercise_id, sort_order) VALUES(1, ?, 3)').run('leg_press');
assert.equal(await repository.addExercisesBatch('2026-09-01', ['leg_press', 'leg_calf_raise']), 1);
assert.equal(db.prepare('SELECT count(*) AS n FROM day_exercises WHERE exercise_id = ?').get('leg_press').n, 1);

// Pre-existing duplicate records survive the new duplicate prevention policy.
db.prepare('INSERT INTO day_exercises(day_id, exercise_id, sort_order) VALUES(1, ?, 7)').run('leg_squat');
assert.equal(await repository.addExercisesBatch('2026-09-01', ['leg_squat']), 0);
day = await repository.loadDay('2026-09-01');
assert.equal(day.exercises.filter(ex => ex.exerciseId === 'leg_squat').length, 2);
assert.deepEqual(Array.from(day.exercises, ex => ex.sortOrder), [0, 1, 2, 3, 4, 7]);
assert.equal((await repository.listExercisesAll()).some(ex => ex.id === 'leg_curl'), false);

// A debounced empty-input save must not clear values from a newer explicit save.
const setId = Number(db.prepare('INSERT INTO workout_sets(day_exercise_id, weight, reps, status, sort_order) VALUES(1, 10, 5, ?, 0)')
  .run('planned').lastInsertRowid);
const edited = new models.SetItem();
edited.id = setId;
edited.weightText = '';
edited.repsText = '8';
afterUpdate = async () => {
  edited.weightText = '42.5';
  await repository.writeSet(edited);
};
await repository.writeSet(edited);
assert.equal(db.prepare('SELECT weight FROM workout_sets WHERE id = ?').get(setId).weight, 42.5,
  'older save must not clear a newer weight during a mode transition');
db.close();
console.log('Actual repository SQLite checks passed: ordering, shared models, duplicate handling, archived validation, atomic rollback.');

// Execute page handlers without ArkUI rendering; focus/navigation/persistence are platform boundaries.
const pageSource = readFileSync(new URL('../entry/src/main/ets/pages/DayDetailPage.ets', import.meta.url), 'utf8');
const handlers = pageSource.slice(pageSource.indexOf('struct DayDetailPage'), pageSource.indexOf('  @Builder'))
  .replace('struct DayDetailPage', 'class DayDetailPage').replace(/@State\s+/g, '') + '\n}\nglobalThis.Page = DayDetailPage;';
let writeError = '';
let writeGate = null;
let preferenceFails = false;
let navigationFails = false;
const savedModes = [];
const navigations = [];
const pageContext = {
  ...logic, ...models, ...types,
  Scroller: class {},
  WorkoutRepository: {
    writeSet: async () => { if (writeGate) await writeGate; return writeError; },
    loadDay: async () => { throw new Error('load failed'); }
  },
  AppSettings: { saveWorkoutViewMode: async mode => { if (preferenceFails) throw new Error('preference failed'); savedModes.push(mode); } },
  promptAction: { showToast: () => {} },
  hilog: { error: () => {} },
  router: { pushUrl: async options => { navigations.push(options); if (navigationFails) throw new Error('router failed'); } }
};
runInNewContext(stripTypeScriptTypes(handlers), pageContext);
const page = new pageContext.Page();
page.getUIContext = () => ({ getFocusController: () => ({ clearFocus: () => {} }) });
page.dateStr = '2026-08-18';
page.day = new models.DayModel();
const pageExercise = new models.ExerciseItem();
const pageSet = new models.SetItem();
pageExercise.sets = [pageSet];
page.day.exercises = [pageExercise];
pageSet.weightText = '.';
await page.setViewMode('exercise');
assert.equal(page.viewMode, 'part');
assert(pageSet.inputError.length > 0);
pageSet.weightText = '42.5';
pageSet.repsText = '8';
writeError = '保存失败';
await page.openMusclePicker();
assert.equal(navigations.length, 0, 'failed set save must prevent navigation');
assert.equal(pageSet.weightText, '42.5', 'failed save preserves the user input');
writeError = '';
await page.setViewMode('exercise');
assert.equal(page.viewMode, 'exercise');
assert.equal(page.day.exercises[0].sets[0], pageSet, 'switching mode preserves observed input objects');
assert.deepEqual(savedModes, ['exercise']);
preferenceFails = true;
await page.setViewMode('part');
assert.equal(page.viewMode, 'exercise', 'preference failure should keep the previous mode for retry');
preferenceFails = false;
let releaseWrite;
writeGate = new Promise(resolve => { releaseWrite = resolve; });
const firstOpen = page.openMusclePicker();
const secondOpen = page.openMusclePicker();
releaseWrite();
await Promise.all([firstOpen, secondOpen]);
assert.equal(navigations.length, 1, 'repeated add taps while flushing should open one picker');
assert.equal(navigations[0].params.date, '2026-08-18');
writeGate = null;
const retainedDay = page.day;
await page.reload();
assert.equal(page.day, retainedDay, 'a reload failure must not erase the visible record and user input');
console.log('Actual day-page checks passed: save-before-transition, failure retention, mode preference, navigation deduplication.');
