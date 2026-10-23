import { strict as assert } from 'node:assert';
import { load, sqliteStore } from './cardio_test_utils.mjs';

const schemaNames = ['CURRENT_VERSION', 'SQL_CREATE_EXERCISES', 'SQL_CREATE_WORKOUT_DAYS', 'SQL_CREATE_DAY_EXERCISES',
  'SQL_CREATE_WORKOUT_SETS', 'SQL_CREATE_BODY_METRICS', 'SQL_CREATE_WATCHED_EXERCISES', 'SQL_CREATE_TREND_SETTINGS',
  'SQL_CREATE_TREND_PART_GOALS', 'SQL_IDX_EXERCISES_PART', 'SQL_IDX_DAY_EXERCISES_DAY', 'SQL_IDX_DAY_EXERCISES_EX', 'SQL_IDX_WORKOUT_SETS_DE'];
const schema = load('db/schemaSql.ets', schemaNames);
assert.equal(schema.CURRENT_VERSION, 4, 'cardio storage schema is v4');
const cardioModel = load('model/CardioModels.ets', ['CardioMetrics']);
const cardioStorage = load('db/CardioStorage.ets', ['CARDIO_COLUMNS', 'CARDIO_SELECT', 'cardioValues', 'putCardioValues', 'readCardioMetrics'], cardioModel);
const cardio = load('common/CardioLogic.ets', ['validateCardioMetrics', 'copyCardioMetrics', 'inheritCardioSettings', 'cardioPlanMetrics', 'formatCardioSummary'], cardioModel);
const types = load('model/types.ets', ['toPartKey', 'partName', 'toEquipment', 'toSetStatus', 'toRecordType'], { $r: x => x });
assert.equal(types.toRecordType('unknown'), 'reps');
const models = load('model/DayModels.ets', ['DayModel', 'ExerciseItem', 'PartItem', 'SetItem', 'PrResult'], cardioModel);
const logic = load('common/WorkoutLogic.ets', ['formatWeight', 'formatLastHint', 'groupExercisesByPart', 'GroupEx', 'HintSet', 'LastHint', 'parseWeight', 'parseReps',
  'WeightReps', 'inheritFromPreviousSet', 'trimNote', 'CsvSetRow', 'setCsvHeader', 'setToCsvRow', 'rirLegacyForImport',
  'LegacyExRow', 'flattenDayExerciseOrder', 'mapLegacyTag']);
const catalog = load('model/exerciseCatalog.ets', ['EXERCISE_CATALOG', 'findExercise']);
assert.equal(catalog.EXERCISE_CATALOG.filter(x => x.recordType === 'cardio').length, 5);
const seed = load('db/ExerciseSeed.ets', ['seedBuiltinExercises'], catalog);
const { db, store, relationalStore } = sqliteStore();
for (const [name, sql] of Object.entries(schema)) if (name.startsWith('SQL_')) db.exec(sql);
await seed.seedBuiltinExercises(store);
const database = { getStore: () => store, logError: () => {} };
const { ExportService } = load('db/ExportService.ets', ['ExportService'], { ...logic, ...cardioModel, ...cardioStorage, ...cardio, ...types, ...seed, ...catalog, WorkoutDatabase: database });
const { WorkoutRepository: repo } = load('db/WorkoutRepository.ets', ['WorkoutRepository'], {
  ...types, ...models, ...logic, ...cardioModel, ...cardioStorage, ...cardio, relationalStore, WorkoutDatabase: database, ExportService
});
const id = await repo.addExercise('2026-10-20', 'cardio_treadmill');
const item = await repo.addSet(id);
assert.equal(item.recordType, 'cardio'); assert.equal(item.exerciseId, 'cardio_treadmill');
assert.equal(await repo.writeSet(item), '');
item.status = 'done';
assert(await repo.writeSet(item), 'done requires positive duration');
item.cardio.durationSec = 600; item.cardio.distanceM = 0; item.cardio.speedKmh = 0; item.cardio.inclinePct = -2;
item.cardio.level = 0; item.cardio.avgHeartRateBpm = 141; item.cardio.energyKcal = 0; item.completedAt = 123;
assert.equal(await repo.writeSet(item), '');
const stored = db.prepare('SELECT * FROM workout_sets WHERE id = ?').get(item.id);
assert.equal(stored.weight, null); assert.equal(stored.reps, null); assert.equal(stored.distance_m, 0);
assert.equal(stored.incline_pct, -2); assert.equal(stored.avg_heart_rate_bpm, 141);
const originalUpdate = store.update;
let release;
store.update = async (bucket, predicate) => { await new Promise(resolve => { release = resolve; }); return originalUpdate(bucket, predicate); };
const saving = repo.writeSet(item);
item.cardio.inclinePct = 7; item.cardio.energyKcal = 99; item.status = 'planned'; item.note = 'later';
release(); await saving; store.update = originalUpdate;
assert.equal(db.prepare('SELECT incline_pct FROM workout_sets WHERE id = ?').get(item.id).incline_pct, -2, 'autosave snapshots every numeric metric before await');
item.cardio.inclinePct = -2; item.cardio.energyKcal = 0; item.status = 'done'; item.note = '';
let loaded = await repo.loadDay('2026-10-20');
assert.equal(loaded.exercises[0].recordType, 'cardio');
assert.equal(loaded.exercises[0].sets[0].cardio.energyKcal, 0);
const next = await repo.addSet(id);
assert.equal(next.cardio.durationSec, null); assert.equal(next.cardio.distanceM, null);
assert.equal(next.cardio.speedKmh, 0); assert.equal(next.cardio.inclinePct, -2); assert.equal(next.cardio.level, 0);
assert.equal(next.cardio.avgHeartRateBpm, null);
await repo.deleteSet(next.id);
const restore = await repo.insertSetCopy(id, item);
assert.equal(db.prepare('SELECT energy_kcal FROM workout_sets WHERE id = ?').get(restore).energy_kcal, 0);
await repo.deleteSet(restore);
assert.equal(await repo.copyDay('2026-10-20', '2026-10-21'), true);
loaded = await repo.loadDay('2026-10-21');
const copy = loaded.exercises[0].sets[0];
assert.equal(copy.status, 'planned'); assert.equal(copy.completedAt, 0);
assert.equal(copy.cardio.durationSec, 600); assert.equal(copy.cardio.distanceM, 0); assert.equal(copy.cardio.energyKcal, null);
assert.equal(copy.cardio.avgHeartRateBpm, null);
assert.match(loaded.exercises[0].lastHint, /10:00/);
const later = await repo.addSet(await repo.addExercise('2026-10-22', 'cardio_treadmill'));
assert.equal(later.cardio.speedKmh, 0); assert.equal(later.cardio.durationSec, null);
const query = store.querySql;
store.querySql = async (sql, args) => {
  assert(!sql.includes('SELECT s.weight AS weight'), 'cardio PR must short-circuit before strength history');
  return query(sql, args);
};
assert.equal((await repo.checkPr('cardio_treadmill', 50, 10, 0)).weightPr, false);
store.querySql = query;
item.cardio.distanceM = Infinity;
assert(await repo.writeSet(item), 'non-finite metrics must be rejected before persistence');
assert.equal(db.prepare('SELECT distance_m FROM workout_sets WHERE id = ?').get(item.id).distance_m, 0);
item.cardio.distanceM = 0;
const beforeFuture = store.transactionCount;
await assert.rejects(ExportService.importJsonText(JSON.stringify({ version: 99 })));
assert.equal(store.transactionCount, beforeFuture, 'reject future format before transaction');
const dump = JSON.parse(await ExportService.exportAllJson());
assert.equal(dump.version, 4); assert.equal(dump.exercises.find(x => x.id === 'cardio_treadmill').record_type, 'cardio');
assert.equal(dump.workout_sets.find(x => x.id === item.id).energy_kcal, 0);
assert.equal(dump.workout_sets.find(x => x.id === item.id).avg_power_w, null);
await ExportService.importJsonText(JSON.stringify(dump));
assert.equal(db.prepare('SELECT incline_pct FROM workout_sets WHERE id = ?').get(item.id).incline_pct, -2);
// Import must enforce the same completion invariant as writeSet, following the
// imported set -> day exercise -> exercise relationship rather than set fields.
for (const profile of ['builtin', 'builtin-missing-type', 'builtin-wrong-type', 'custom']) {
  for (const duration of [undefined, null, 0]) {
    for (const status of ['done', 'planned']) {
      const imported = structuredClone(dump);
      const row = imported.workout_sets.find(row => row.id === item.id);
      row.status = status;
      if (duration === undefined) delete row.duration_sec;
      else row.duration_sec = duration;
      const exercise = imported.exercises.find(row => row.id === 'cardio_treadmill');
      if (profile === 'builtin-missing-type') delete exercise.record_type;
      if (profile === 'builtin-wrong-type') exercise.record_type = 'reps';
      if (profile === 'custom') {
        imported.exercises.push({ ...exercise, id: 'usr_cardio_import', is_builtin: 0 });
        imported.day_exercises.find(row => row.id === id).exercise_id = 'usr_cardio_import';
      }
      if (status === 'done') {
        const transactions = store.transactionCount;
        await assert.rejects(ExportService.importJsonText(JSON.stringify(imported)), `${profile}: completed cardio cannot import duration ${duration}`);
        assert.equal(store.transactionCount, transactions, 'invalid completed cardio must reject before any writes');
      } else {
        await ExportService.importJsonText(JSON.stringify(imported));
        const planned = db.prepare('SELECT status, duration_sec FROM workout_sets WHERE id = ?').get(item.id);
        assert.equal(planned.status, 'planned');
        assert.equal(planned.duration_sec, duration ?? null);
      }
    }
  }
}
await ExportService.importJsonText(JSON.stringify(dump));
assert.equal(db.prepare('SELECT status, duration_sec FROM workout_sets WHERE id = ?').get(item.id).duration_sec, 600,
  'valid completed cardio from the application export still roundtrips');
const csv = await ExportService.exportAllCsv();
assert(csv.split('\n')[0].startsWith('date,exercise_name,exercise_id,part_key,weight,reps,is_warmup,technique,rir,rir_legacy,status,completed_at,note,sort_order,'));
assert(csv.includes('record_type,duration_sec,distance_m,speed_kmh,incline_pct,level,steps,floors,cadence_per_min,avg_power_w,avg_heart_rate_bpm,energy_kcal'));
const invalid = structuredClone(dump); invalid.workout_sets[0].steps = 1.5;
await assert.rejects(ExportService.importJsonText(JSON.stringify(invalid)));
assert.equal(db.prepare('SELECT distance_m FROM workout_sets WHERE id = ?').get(item.id).distance_m, 0, 'invalid import preserves existing data');
const strengthId = await repo.addExercise('2026-10-23', 'chest_bb_bench');
const strength = await repo.addSet(strengthId); strength.weightText = '42.5'; strength.repsText = '10'; strength.rir = 2; strength.rirLegacy = 0;
strength.status = 'done';
assert.equal(await repo.writeSet(strength), '');
const old = JSON.parse(await ExportService.exportAllJson()); old.version = 3;
// Legacy exports predate cardio machine records. Keep their actual strength
// rows, with no record type or cardio metric fields, as the compatibility fixture.
old.workout_sets = old.workout_sets.filter(row => row.id === strength.id);
old.day_exercises = old.day_exercises.filter(row => row.id === strengthId);
old.workout_days = old.workout_days.filter(row => row.date === '2026-10-23');
for (const x of old.exercises) delete x.record_type;
for (const x of old.workout_sets) for (const key of Object.keys(x)) if (key in stored && !['id','day_exercise_id','weight','reps','is_warmup','technique','rir','rir_legacy','status','completed_at','note','sort_order'].includes(key)) delete x[key];
await ExportService.importJsonText(JSON.stringify(old));
assert.equal(db.prepare('SELECT rir_legacy FROM workout_sets WHERE id = ?').get(strength.id).rir_legacy, 0);
assert.equal(db.prepare('SELECT duration_sec, status FROM workout_sets WHERE id = ?').get(strength.id).duration_sec, null);
for (const version of [1, 2]) {
  const oldRir = structuredClone(old); oldRir.version = version;
  const row = oldRir.workout_sets.find(x => x.id === strength.id); row.rir = 1; delete row.rir_legacy;
  await ExportService.importJsonText(JSON.stringify(oldRir));
  assert.equal(db.prepare('SELECT rir_legacy FROM workout_sets WHERE id = ?').get(strength.id).rir_legacy, 1);
}

// Exercise the real migration against a v3 SQLite database, including reinitialization/recovery.
const legacy = sqliteStore();
for (const [name, sql] of Object.entries(schema)) if (name.startsWith('SQL_')) {
  let v3 = sql;
  if (name === 'SQL_CREATE_EXERCISES') v3 = v3.replace(/record_type TEXT NOT NULL DEFAULT 'reps',?/, '');
  if (name === 'SQL_CREATE_WORKOUT_SETS') for (const key of ['duration_sec','distance_m','speed_kmh','incline_pct','level','steps','floors','cadence_per_min','avg_power_w','avg_heart_rate_bpm','energy_kcal']) v3 = v3.replace(new RegExp(`${key} (?:REAL|INTEGER),?`), '');
  legacy.db.exec(v3);
}
legacy.store.version = 3;
let backups = 0;
const { WorkoutDatabase: migration } = load('db/WorkoutDatabase.ets', ['WorkoutDatabase'], {
  ...schema, ...logic, ...seed, relationalStore: { SecurityLevel: { S1: 1 } },
  BackupService: { backupBeforeMigrate: async () => { backups++; } }, hilog: { error() {} }
});
await migration.migrate(legacy.store, {});
assert.equal(backups, 1); assert.equal(legacy.store.version, 4);
await migration.migrate(legacy.store, {});
assert.equal(backups, 1);
assert.equal(legacy.db.prepare('SELECT record_type FROM exercises WHERE id = ?').get('cardio_rower').record_type, 'cardio');
assert(legacy.db.prepare('PRAGMA table_info(workout_sets)').all().some(x => x.name === 'energy_kcal'));
legacy.db.exec('ALTER TABLE workout_sets DROP COLUMN energy_kcal');
legacy.db.exec('ALTER TABLE exercises DROP COLUMN record_type');
await migration.migrate(legacy.store, {});
assert(legacy.db.prepare('PRAGMA table_info(workout_sets)').all().some(x => x.name === 'energy_kcal'), 'v4 recovery repairs missing columns');
assert.equal(legacy.db.prepare('SELECT record_type FROM exercises WHERE id = ?').get('cardio_rower').record_type, 'cardio');
const fresh = sqliteStore();
await migration.migrate(fresh.store, {});
assert.equal(fresh.store.version, 4); assert.equal(backups, 1);
// Pre-v1 day-part layout still copies strength history before adding v4 fields.
const prehistoric = sqliteStore();
prehistoric.db.exec("CREATE TABLE workout_days (id INTEGER PRIMARY KEY, date TEXT); CREATE TABLE day_parts (id INTEGER PRIMARY KEY, day_id INTEGER, sort_order INTEGER); CREATE TABLE day_exercises (id INTEGER PRIMARY KEY, day_part_id INTEGER, exercise_id TEXT, sort_order INTEGER); CREATE TABLE workout_sets (id INTEGER PRIMARY KEY, exercise_row_id INTEGER, weight REAL, reps INTEGER, tag TEXT, sort_order INTEGER)");
prehistoric.db.exec("INSERT INTO workout_days VALUES(1,'2020-01-01'); INSERT INTO day_parts VALUES(1,1,0); INSERT INTO day_exercises VALUES(1,1,'chest_bb_bench',0); INSERT INTO workout_sets VALUES(1,1,42.5,8,'warmup',0)");
await migration.migrate(prehistoric.store, {});
assert.equal(prehistoric.store.version, 4); assert.equal(backups, 2);
assert.equal(prehistoric.db.prepare('SELECT weight FROM workout_sets WHERE id=1').get().weight, 42.5);
assert.equal(prehistoric.db.prepare('SELECT duration_sec FROM workout_sets WHERE id=1').get().duration_sec, null);
assert.equal(prehistoric.db.prepare("SELECT record_type FROM exercises WHERE id='chest_bb_bench'").get().record_type, 'reps');
for (const connection of [db, legacy.db, fresh.db, prehistoric.db]) connection.close();
console.log('Actual ArkTS + SQLite cardio migration, save/load, settings inheritance, undo/copy, CSV and v4 JSON passed.');
