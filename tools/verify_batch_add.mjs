import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

function load(path, names, dependencies = {}) {
  const source = readFileSync(new URL(`../entry/src/main/ets/${path}`, import.meta.url), 'utf8')
    .replace(/^import[\s\S]*?from\s+['"][^'"]+['"];\r?\n/gm, '')
    .replace(/@Observed\s*/g, '').replace(/\bexport /g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(source) + `\nglobalThis.result = { ${names.join(',')} };`, context);
  return context.result;
}

const types = load('model/types.ets', ['toPartKey', 'partName', 'toEquipment', 'toSetStatus', 'equipmentName'], { $r: x => x });
const muscles = load('model/muscleTypes.ets', ['toMuscleKey', 'MUSCLE_REGIONS']);
const catalog = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG', 'findExercise']);
const details = load('model/exerciseDetails.ets', ['findExerciseDetail', 'extraSearchText']);
const logic = load('common/WorkoutLogic.ets', ['formatWeight', 'formatLastHint', 'groupExercisesByPart', 'GroupEx', 'HintSet', 'LastHint', 'parseWeight', 'parseReps']);
const muscleLogic = load('common/MuscleLogic.ets', [
  'planBatchAdd', 'BatchPlan', 'recommendForMuscle', 'filterExercises', 'toggleSelected', 'isSelected', 'RecommendItem'
], { ...muscles, ...catalog, ...details });
const models = load('model/DayModels.ets', ['DayModel', 'PartItem', 'ExerciseItem', 'SetItem']);
const schema = load('db/schemaSql.ets', ['SQL_CREATE_EXERCISES', 'SQL_CREATE_WORKOUT_DAYS', 'SQL_CREATE_DAY_EXERCISES', 'SQL_CREATE_WORKOUT_SETS']);
const { seedBuiltinExercises } = load('db/ExerciseSeed.ets', ['seedBuiltinExercises'], catalog);

const db = new DatabaseSync(':memory:');
for (const sql of Object.values(schema)) db.exec(sql);
let atBegin = null;
let insertCount = 0;
let failInsertAt = -1;
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
  },
  insert: async (table, values) => {
    if (table === 'day_exercises' && ++insertCount === failInsertAt) {
      throw new Error('injected write failure');
    }
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
const count = (table) => db.prepare(`SELECT count(*) AS n FROM ${table}`).get().n;
const dayCount = (date) => db.prepare('SELECT count(*) AS n FROM workout_days WHERE date = ?').get(date).n;
const exerciseIds = (date) => db.prepare(
  'SELECT e.exercise_id AS id FROM workout_days d INNER JOIN day_exercises e ON e.day_id = d.id WHERE d.date = ? ORDER BY e.sort_order, e.id'
).all(date).map((row) => row.id);

const planDup = muscleLogic.planBatchAdd(
  ['chest_fly', 'chest_fly', 'chest_bb_bench', 'leg_squat'],
  ['chest_bb_bench'],
  ['chest_fly', 'chest_bb_bench', 'leg_squat']
);
assert.equal(planDup.ok, true);
assert.deepEqual(Array.from(planDup.toInsert), ['chest_fly', 'leg_squat']);
const planBad = muscleLogic.planBatchAdd(['missing'], [], ['chest_fly']);
assert.equal(planBad.ok, false);
assert.equal(planBad.toInsert.length, 0);

assert.equal(await repository.addExercisesBatch('2026-09-01', []), 0);
assert.equal(dayCount('2026-09-01'), 0);

const mutated = ['leg_squat', 'chest_bb_bench', 'back_deadlift'];
const pending = repository.addExercisesBatch('2026-09-01', mutated);
mutated.length = 0;
assert.equal(await pending, 3);
assert.deepEqual(exerciseIds('2026-09-01'), ['leg_squat', 'chest_bb_bench', 'back_deadlift']);

assert.equal(await repository.addExercisesBatch('2026-09-01', ['chest_bb_bench', 'leg_squat', 'leg_squat']), 0);
assert.equal(count('workout_sets'), 0);
assert.equal(await repository.addExercisesBatch('2026-09-01', ['leg_squat', 'leg_press']), 1);
assert.deepEqual(exerciseIds('2026-09-01'), ['leg_squat', 'chest_bb_bench', 'back_deadlift', 'leg_press']);

const rowsBefore = count('day_exercises');
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'missing']));
assert.equal(dayCount('2026-09-02'), 0);
assert.equal(count('day_exercises'), rowsBefore);

failInsertAt = insertCount + 2;
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'leg_curl']));
failInsertAt = -1;
assert.equal(dayCount('2026-09-02'), 0);
assert.equal(count('day_exercises'), rowsBefore);

atBegin = () => db.prepare('UPDATE exercises SET is_archived = 1 WHERE id = ?').run('leg_curl');
await assert.rejects(repository.addExercisesBatch('2026-09-02', ['leg_squat', 'leg_curl']));
assert.equal(dayCount('2026-09-02'), 0);
db.prepare('UPDATE exercises SET is_archived = 0 WHERE id = ?').run('leg_curl');

const overlapIds = ['chest_fly', 'chest_incline_bench', 'chest_db_bench'];
const overlapping = await Promise.all([
  repository.addExercisesBatch('2026-09-12', overlapIds),
  repository.addExercisesBatch('2026-09-12', overlapIds)
]);
const overlapRows = db.prepare(
  "SELECT exercise_id, count(*) AS n FROM day_exercises e JOIN workout_days d ON d.id = e.day_id WHERE d.date = '2026-09-12' GROUP BY exercise_id"
).all();
assert.equal(overlapping[0] + overlapping[1], 3);
assert.equal(overlapRows.length, 3);
for (const row of overlapRows) assert.equal(row.n, 1);

const cross = await Promise.all([
  repository.addExercisesBatch('2026-09-21', ['leg_curl']),
  repository.addExercisesBatch('2026-09-22', ['leg_curl'])
]);
assert.deepEqual(cross, [1, 1]);
assert.equal(dayCount('2026-09-21'), 1);
assert.equal(dayCount('2026-09-22'), 1);

const orders = db.prepare(
  "SELECT sort_order FROM day_exercises e JOIN workout_days d ON d.id = e.day_id WHERE d.date = '2026-09-01' ORDER BY sort_order"
).all().map((row) => row.sort_order);
assert.deepEqual(orders, [0, 1, 2, 3]);

const pageSource = readFileSync(new URL('../entry/src/main/ets/pages/MusclePickerPage.ets', import.meta.url), 'utf8');
const handlers = pageSource.slice(pageSource.indexOf('struct MusclePickerPage'), pageSource.indexOf('  @Builder'))
  .replace('struct MusclePickerPage', 'class MusclePickerPage')
  .replace(/@State\s+/g, '') + '\n}\nglobalThis.Page = MusclePickerPage;';

const batchCalls = [];
let batchImpl = async (date, ids) => repository.addExercisesBatch(date, ids);
const toasts = [];
const backs = [];
const pageContext = {
  ...types, ...muscles, ...muscleLogic, ...catalog,
  todayString: () => '2026-09-30',
  AppSettings: { loadTheme: async () => 'light' },
  WorkoutRepository: {
    listExercisesAll: async () => catalog.EXERCISE_CATALOG,
    listAddedExerciseIds: async (date) => repository.listAddedExerciseIds(date),
    addExercisesBatch: async (date, ids) => {
      batchCalls.push({ date, ids: ids.slice() });
      return batchImpl(date, ids);
    }
  },
  promptAction: { showToast: (opt) => { toasts.push(opt.message); } },
  hilog: { warn: () => {}, error: () => {} },
  router: {
    getParams: () => ({ date: '2026-09-01' }),
    back: () => { backs.push('back'); }
  }
};
runInNewContext(stripTypeScriptTypes(handlers), pageContext);
const screen = new pageContext.Page();
screen.alive = true;
screen.dateStr = '2026-09-01';
screen.catalogLoading = false;
screen.loadError = '';
screen.selectedIds = [];
await screen.confirmAdd();
assert.equal(batchCalls.length, 0, 'empty selection must not write');

screen.catalogLoading = true;
screen.selectedIds = ['leg_calf_raise'];
await screen.confirmAdd();
assert.equal(batchCalls.length, 0, 'loading catalog must block confirm');

screen.catalogLoading = false;
screen.loadError = '暂时无法加载动作';
await screen.confirmAdd();
assert.equal(batchCalls.length, 0, 'load error must block confirm');

screen.loadError = '';
screen.selectedIds = ['leg_calf_raise', 'leg_calf_raise'];
const kept = screen.selectedIds;
await screen.confirmAdd();
assert.equal(batchCalls.length, 1);
assert.deepEqual(batchCalls[0].ids, ['leg_calf_raise', 'leg_calf_raise']);
assert.equal(backs.length, 1);
assert.equal(screen.submitting, true, 'success leaves submitting true while leaving the page');
assert.equal(screen.selectedIds, kept, 'success keeps the same selected array object');
assert.ok(exerciseIds('2026-09-01').includes('leg_calf_raise'));

screen.submitting = false;
screen.selectedIds = ['missing'];
const beforeFail = screen.selectedIds.slice();
await screen.confirmAdd();
assert.equal(screen.submitting, false);
assert.deepEqual(Array.from(screen.selectedIds), beforeFail);
assert.equal(toasts[toasts.length - 1], '添加失败，选择已保留，请重试');

screen.submitting = false;
screen.selectedIds = ['arm_bb_curl'];
let release;
batchImpl = () => new Promise((resolve) => { release = resolve; });
const callsBeforeDouble = batchCalls.length;
const first = screen.confirmAdd();
const second = screen.confirmAdd();
assert.equal(screen.submitting, true);
assert.equal(batchCalls.length, callsBeforeDouble + 1, 'second confirm while submitting must not call repository');
release(1);
await Promise.all([first, second]);
assert.equal(batchCalls.filter((c) => c.ids[0] === 'arm_bb_curl').length, 1, 'double tap must not start a second batch');

screen.submitting = true;
const locked = screen.selectedIds.slice();
screen.handleToggle({ id: 'chest_fly', addedToday: false });
screen.removeSelected('arm_bb_curl');
assert.deepEqual(Array.from(screen.selectedIds), locked);
assert.equal(screen.onBackPress(), true);

console.log('Systematic batch-add tests passed: plan, repository atomicity/queue, picker confirm guards.');
