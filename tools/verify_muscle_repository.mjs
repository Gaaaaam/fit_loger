import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import { DatabaseSync } from 'node:sqlite';

const base = new URL('../entry/src/main/ets/', import.meta.url);
const db = new DatabaseSync(':memory:');
class ResultSet {
  constructor(rows) { this.rows = rows; this.index = 0; this.columns = Object.keys(rows[0] || {}); }
  goToFirstRow() { this.index = 0; return this.rows.length > 0; }
  goToNextRow() { return ++this.index < this.rows.length; }
  getColumnIndex(name) { return this.columns.indexOf(name); }
  isColumnNull(index) { return this.rows[this.index][this.columns[index]] == null; }
  getString(index) { return this.rows[this.index][this.columns[index]]; }
  getLong(index) { return Number(this.rows[this.index][this.columns[index]]); }
  getDouble(index) { return this.getLong(index); }
  close() {}
}
class Predicates { constructor(table) { this.table = table; } equalTo(key, value) { this.key = key; this.value = value; } }
let failInsert = '';
let updates = 0;
const store = {
  querySql: async (sql, args = []) => new ResultSet(db.prepare(sql).all(...args)),
  executeSql: async (sql, args = []) => db.prepare(sql).run(...args),
  insert: async (table, values) => {
    if (values.exercise_id === failInsert) throw new Error('injected insert failure');
    const keys = Object.keys(values);
    return Number(db.prepare(`INSERT INTO ${table} (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`).run(...Object.values(values)).lastInsertRowid);
  },
  update: async (values, p) => { updates++; return db.prepare(`UPDATE ${p.table} SET ${Object.keys(values).map((k) => `${k} = ?`).join(',')} WHERE ${p.key} = ?`).run(...Object.values(values), p.value).changes; },
  beginTransaction: () => db.exec('BEGIN'), commit: () => db.exec('COMMIT'), rollBack: () => db.exec('ROLLBACK')
};
const context = { $r: (s) => s, WorkoutDatabase: { getStore: () => store, logError() {} }, relationalStore: { RdbPredicates: Predicates } };
for (const file of ['model/types.ets', 'model/DayModels.ets', 'common/WorkoutLogic.ets', 'common/DateUtil.ets', 'model/exerciseCatalog.ets', 'db/schemaSql.ets', 'db/WorkoutRepository.ets']) {
  const source = readFileSync(new URL(file, base), 'utf8').replace(/^import[\s\S]*?;\s*$/gm, '').replace(/export /g, '').replace(/@Observed\s*/g, '');
  runInNewContext(stripTypeScriptTypes(source), context);
}
runInNewContext('globalThis.api = { WorkoutRepository, SetItem, EXERCISE_CATALOG, schema: [SQL_CREATE_EXERCISES, SQL_CREATE_WORKOUT_DAYS, SQL_CREATE_DAY_EXERCISES, SQL_CREATE_WORKOUT_SETS] };', context);
const { WorkoutRepository: repo, SetItem, EXERCISE_CATALOG: defs, schema } = context.api;
schema.forEach((sql) => db.exec(sql));
for (const d of defs) await store.insert('exercises', { id: d.id, name: d.name, part_key: d.partKey, equipment: d.equipment, movement_pattern: d.movementPattern, weight_step: d.weightStep, is_builtin: 1, is_archived: 0, created_at: 0 });
assert.equal((await repo.listAllExercises()).length, defs.length);
assert.equal((await repo.addExercisesBatch('2026-09-08', [])).length, 0);
assert.equal(db.prepare('SELECT count(*) AS n FROM workout_days').get().n, 0);
const ids = [defs[0].id, defs[7].id, defs[1].id];
assert.equal((await repo.addExercisesBatch('2026-09-08', [...ids, ids[0]])).length, 3);
assert.deepEqual(Array.from(await repo.listDayExerciseIds('2026-09-08')), ids);
assert.equal((await repo.addExercisesBatch('2026-09-08', ids)).length, 0);
const overlapping = await Promise.all([
  repo.addExercisesBatch('2026-09-12', ids), repo.addExercisesBatch('2026-09-12', ids)
]);
assert.equal(overlapping[0].length + overlapping[1].length, 3, 'overlapping requests cannot duplicate rows');
await assert.rejects(repo.addExercisesBatch('2026-09-09', [ids[0], 'missing']));
assert.equal(db.prepare("SELECT count(*) AS n FROM workout_days WHERE date = '2026-09-09'").get().n, 0);
failInsert = ids[1];
await assert.rejects(repo.addExercisesBatch('2026-09-10', ids));
failInsert = '';
assert.equal(db.prepare("SELECT count(*) AS n FROM workout_days WHERE date = '2026-09-10'").get().n, 0);
failInsert = defs[3].id;
await assert.rejects(repo.addExercisesBatch('2026-09-08', [defs[2].id, defs[3].id]));
failInsert = '';
assert.deepEqual(Array.from(await repo.listDayExerciseIds('2026-09-08')), ids, 'rollback preserves an existing day');
db.prepare('UPDATE exercises SET is_archived = 1 WHERE id = ?').run(ids[1]);
await assert.rejects(repo.addExercisesBatch('2026-09-11', [ids[1]]));
assert.equal((await repo.listAllExercises()).length, defs.length - 1);
const day = await repo.loadDay('2026-09-08');
assert.deepEqual(Array.from(day.exercises, (e) => e.exerciseId), ids);
assert.equal(day.parts[0].exercises[0], day.exercises[0], 'both modes share object identity');
assert.equal((await repo.loadExerciseRow(day.exercises[2].id, day.date)).sortOrder, 2);
const set = await repo.addSet(day.exercises[0].id);
set.weightText = ''; set.repsText = '8';
const oldWrite = repo.writeSet(set);
set.weightText = '55'; set.repsText = '10'; set.status = 'done'; set.completedAt = 123;
const newWrite = repo.writeSet(set);
await Promise.all([oldWrite, newWrite]);
let saved = db.prepare('SELECT * FROM workout_sets WHERE id = ?').get(set.id);
assert.equal(saved.weight, 55); assert.equal(saved.reps, 10); assert.equal(saved.completed_at, 123);
assert.equal(updates, 2, 'each edit persists in one atomic snapshot');
set.weightText = ''; set.repsText = ''; set.completedAt = 0; set.status = 'planned';
await repo.writeSet(set);
saved = db.prepare('SELECT * FROM workout_sets WHERE id = ?').get(set.id);
assert.equal(saved.weight, null); assert.equal(saved.reps, null); assert.equal(saved.completed_at, null);
console.log('Actual repository + SQLite batch atomicity, deduplication, shared order and nullable write tests passed.');

// Run the page's real non-rendering handlers against the same repository and SQLite database.
context.AppSettings = { loadWorkoutMode: async () => 'part', saveWorkoutMode: async (mode) => { context.savedMode = mode; } };
context.Scroller = class {};
context.router = { back() {}, pushUrl: async () => {}, getParams: () => ({ date: '2026-09-08' }) };
context.promptAction = { showToast() {} };
context.hilog = { error() {} };
const page = readFileSync(new URL('pages/DayDetailPage.ets', base), 'utf8');
const handlers = page.slice(page.indexOf('struct DayDetailPage'), page.indexOf('  @Builder'))
  .replace('struct DayDetailPage', 'class DayDetailPage')
  .replace(/@State\s+/g, '') + '\n}\nglobalThis.Page = DayDetailPage;';
runInNewContext(stripTypeScriptTypes(handlers), context);
const screen = new context.Page();
screen.dateStr = '2026-09-08';
screen.getUIContext = () => ({ getFocusController: () => ({ clearFocus() {} }) });
await screen.initialize();
assert.equal(screen.showSheet, false, 'opening a date must not open a picker');
const sharedExercise = screen.day.exercises[0];
const sharedSet = sharedExercise.sets[0];
sharedSet.weightText = '72.5'; sharedSet.repsText = '6';
sharedSet.isWarmup = 1; sharedSet.technique = 'drop'; sharedSet.rir = 3;
sharedSet.status = 'done'; sharedSet.completedAt = 456; sharedSet.note = '保留备注';
await screen.switchMode('exercise');
assert.equal(screen.workoutMode, 'exercise');
assert.equal(context.savedMode, 'exercise');
assert.equal(screen.day.exercises[0], sharedExercise);
assert.equal(screen.day.parts[0].exercises[0].sets[0], sharedSet);
assert.equal(db.prepare('SELECT weight FROM workout_sets WHERE id = ?').get(sharedSet.id).weight, 72.5);
const switchedSet = db.prepare('SELECT * FROM workout_sets WHERE id = ?').get(sharedSet.id);
assert.equal(switchedSet.is_warmup, 1); assert.equal(switchedSet.technique, 'drop'); assert.equal(switchedSet.rir, 3);
assert.equal(switchedSet.status, 'done'); assert.equal(switchedSet.completed_at, 456); assert.equal(switchedSet.note, '保留备注');
sharedSet.weightText = '.';
await screen.switchMode('part');
assert.equal(screen.workoutMode, 'exercise', 'invalid pending edits prevent teardown');
sharedSet.weightText = '75';
await screen.switchMode('part');
assert.equal(screen.workoutMode, 'part');
await screen.switchMode('exercise');
await screen.openAddPicker();
assert.equal(screen.returningFromPicker, true);
let reloads = 0;
screen.reload = async () => { reloads++; };
screen.onPageShow(); screen.onPageShow();
assert.equal(reloads, 1, 'return from muscle picker reloads once');
console.log('Actual day mode switching, validation, shared state and picker return handlers passed.');
