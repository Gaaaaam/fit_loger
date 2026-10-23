import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { load, sqliteStore } from './cardio_test_utils.mjs';
import * as mirror from './trend_logic.mjs';
const model = load('model/CardioModels.ets', ['CardioMetrics']);
const date = load('common/DateUtil.ets', ['addDays', 'daysSinceEpoch', 'isoWeekStart', 'rangeStart']);
const names = ['TrendSetRow', 'ExerciseMeta', 'WatchableExercise', 'KeyLiftPick', 'KeyLiftSeries', 'TrendPreferences', 'TrendWeightRow', 'buildLiftSeries', 'buildExerciseTrendDetail', 'buildTrendDigest', 'resolveWatchedLifts', 'weekSummary', 'buildWeekGoalProgress', 'isWorkSet', 'isLiftPerformancePoint', 'setVolume', 'buildPrBoard', 'buildVolumeSeries', 'recentSessionCause', 'liftMetricLabel', 'buildTrendInsight'];
const actual = load('common/TrendLogic.ets', names, { ...model, ...date });
const clean = value => JSON.parse(JSON.stringify(value));
function row(extra = {}) {
  return { date: '2026-10-19', exerciseId: 'cardio_treadmill', exerciseName: '跑步机', recordType: 'cardio', partKey: 'cardio', movementPattern: 'cardio', isBodyweight: 0, isUnilateral: 0, weight: 100, reps: 5, rir: 0, rirLegacy: 0, bodyWeightKg: 70, isWarmup: 0, technique: '', status: 'done', cardio: { durationSec: 600, distanceM: null, steps: null }, ...extra };
}
const prefs = { watchedExerciseIds: ['cardio_treadmill'], sessionsTarget: null, partGoals: [] };
const rows = [row(), row({ cardio: { durationSec: 300, distanceM: 1200 } }), row({ date: '2026-10-20', cardio: { durationSec: 60, distanceM: 0 } }), row({ date: '2026-10-21', cardio: { durationSec: 120, distanceM: null } }), row({ isWarmup: 1 }), row({ status: 'planned' }), row({ cardio: { durationSec: 0, distanceM: 999 } }), row({ cardio: { durationSec: Infinity, distanceM: 999 } })];
function check(api) {
  const meta = { exerciseId: 'cardio_treadmill', name: '跑步机', partKey: 'cardio', movementPattern: 'cardio', isBodyweight: 0, recordType: 'cardio' };
  const detail = api.buildExerciseTrendDetail(rows, meta);
  assert.equal(detail.metric, 'duration', 'cardio must use daily duration instead of stray strength values');
  assert.equal(detail.recordType, 'cardio');
  assert.equal(detail.metricLabel, '时长 分钟');
  assert.deepEqual(clean(detail.points.map(p => p.value)), [15, 1, 2]);
  assert.equal(detail.sessions, 3); assert.equal(detail.workSets, 4);
  assert.equal(detail.secondaryUnit, 'km');
  assert.deepEqual(clean(detail.secondaryPoints.map(p => [p.date, p.value])), [['2026-10-19', 1.2], ['2026-10-20', 0]], 'missing optional values omitted; known zero retained');
  assert.equal(detail.recentSessions[2].value, 15); assert.equal(detail.recentSessions[2].workSets, 2);
  assert.equal(detail.recentSessions[2].minRir, null); assert.equal(detail.relativeText, '');
  const optionalInvalid = api.buildExerciseTrendDetail([row({ cardio: { durationSec: 600, distanceM: Infinity } }), row({ cardio: { durationSec: 600, distanceM: -1 } })], meta);
  assert.equal(optionalInvalid.points[0].value, 20); assert.equal(optionalInvalid.secondaryPoints.length, 0);
  const single = api.buildExerciseTrendDetail([row()], meta);
  assert.equal(single.points.length, 1); assert.equal(single.insufficientData, false); assert.equal(single.secondaryPoints.length, 0);
  const stairMeta = { ...meta, exerciseId: 'cardio_stair_climber' };
  const stairs = api.buildExerciseTrendDetail([row({ exerciseId: stairMeta.exerciseId, cardio: { durationSec: 300, distanceM: 800, floors: 20, steps: null } })], stairMeta);
  assert.equal(stairs.secondaryUnit, '步'); assert.equal(stairs.secondaryPoints.length, 0, 'floors never become steps');
  const stepZero = api.buildExerciseTrendDetail([row({ exerciseId: stairMeta.exerciseId, cardio: { durationSec: 60, steps: 0 } })], stairMeta);
  assert.equal(stepZero.secondaryPoints[0].value, 0);
  for (const [id, unit, value] of [['cardio_rower', 'm', 1200], ['cardio_elliptical', 'km', 1.2], ['cardio_stationary_bike', 'km', 1.2]]) {
    const d = api.buildExerciseTrendDetail([row({ exerciseId: id, cardio: { durationSec: 600, distanceM: 1200 } })], { ...meta, exerciseId: id });
    assert.equal(d.secondaryUnit, unit); assert.equal(d.secondaryPoints[0].value, value);
  }
  const strength = row({ exerciseId: 'chest_bb_bench', exerciseName: '卧推', recordType: 'reps', partKey: 'chest', movementPattern: 'push', weight: 60 });
  assert.deepEqual(clean(api.weekSummary([...rows, strength], '2026-10-23')), [3, 1]);
  assert.equal(api.isWorkSet(row()), false); assert.equal(api.isLiftPerformancePoint(row()), false); assert.equal(api.setVolume(row()), null);
  assert.equal(api.buildPrBoard(rows).length, 0); assert.equal(api.buildVolumeSeries(rows).length, 0);
  assert.equal(api.recentSessionCause(rows, meta.exerciseId), 'none');
  const goal = api.buildWeekGoalProgress([...rows, strength], '2026-10-23', prefs);
  assert.equal(goal.sessionsDone, 3); assert.equal(goal.parts.find(x => x.partKey === 'chest').done, 1);
  const digest = api.buildTrendDigest(rows, [], '2026-10-23', '4', prefs);
  assert.equal(digest.lifts[0].metric, 'duration'); assert.equal(digest.insight.kind, 'none', 'cardio does not create strength progress or stall tips');
  assert.equal(api.buildTrendDigest([row()], [], '2026-10-23', 'all', { ...prefs, watchedExerciseIds: [] }).lifts.length, 1, 'cardio-only history is recommended');
  assert.equal(api.resolveWatchedLifts([row()], prefs.watchedExerciseIds, 3).length, 1);
  assert.equal(api.buildTrendDigest([row()], [], '2026-10-23', '4', prefs).lifts[0].points.length, 1);
  const old = api.buildExerciseTrendDetail([row({ exerciseId: 'cardio_jump_rope', recordType: 'reps', isBodyweight: 1, reps: 20 })], { ...meta, exerciseId: 'cardio_jump_rope', recordType: 'reps', isBodyweight: 1 });
  assert.equal(old.metric, 'reps'); assert.equal(old.points[0].value, 20);
  return clean(digest);
}
const expected = check(actual);
assert.deepEqual(check(mirror), expected, 'portable mirror and real ArkTS yield the same cardio digest');
// Exercise actual repository SQL and readers against SQLite, including nullable/zero metrics.
const schema = load('db/schemaSql.ets', ['SQL_CREATE_EXERCISES', 'SQL_CREATE_WORKOUT_DAYS', 'SQL_CREATE_DAY_EXERCISES', 'SQL_CREATE_WORKOUT_SETS', 'SQL_CREATE_BODY_METRICS']);
const storage = load('db/CardioStorage.ets', ['CARDIO_SELECT', 'readCardioMetrics'], model);
const types = load('model/types.ets', ['toRecordType'], { $r: x => x });
const { db, store } = sqliteStore();
for (const sql of Object.values(schema)) db.exec(sql);
const { WorkoutRepository: repo } = load('db/WorkoutRepository.ets', ['WorkoutRepository'], { ...actual, ...model, ...storage, ...types, WorkoutDatabase: { getStore: () => store } });
db.exec(`INSERT INTO exercises (id,name,part_key,movement_pattern,record_type) VALUES ('cardio_treadmill','跑步机','cardio','cardio','cardio'),('chest_bb_bench','卧推','chest','push','reps');
INSERT INTO workout_days (id,date) VALUES (1,'2026-10-19'),(2,'2026-10-20');
INSERT INTO day_exercises (id,day_id,exercise_id,sort_order) VALUES (1,1,'cardio_treadmill',0),(2,2,'cardio_treadmill',0),(3,1,'chest_bb_bench',1);
INSERT INTO workout_sets (id,day_exercise_id,sort_order,status,is_warmup,duration_sec,distance_m,weight,reps) VALUES
(1,1,0,'done',0,600,0,90,6),(2,1,1,'done',0,300,NULL,NULL,NULL),(3,2,0,'done',0,60,200,NULL,NULL),(4,2,1,'planned',0,600,999,NULL,NULL),(5,2,2,'done',1,600,999,NULL,NULL),(6,3,0,'done',0,NULL,NULL,60,5),(7,2,3,'done',0,0,999,NULL,NULL);`);
const loaded = await repo.loadTrendSets('', '2026-10-23');
assert.equal(loaded.find(x => x.exerciseId === 'cardio_treadmill').recordType, 'cardio');
assert.equal(loaded[0].cardio.durationSec, 600); assert.equal(loaded[0].cardio.distanceM, 0);
const ex = await repo.loadTrendSetsForExercise('cardio_treadmill', '2026-10-20', '2026-10-23');
assert(ex.every(x => x.recordType === 'cardio' && x.date === '2026-10-20'));
assert.equal(ex[0].cardio.distanceM, 200);
const meta = await repo.loadExerciseMeta('cardio_treadmill'); assert.equal(meta.recordType, 'cardio');
const watch = (await repo.listExercisesWithHistory()).find(x => x.exerciseId === 'cardio_treadmill');
assert.equal(watch.recordType, 'cardio'); assert.equal(watch.sessions, 2); assert.equal(watch.workSets, 3, 'invalid duration excluded from history segment count');
assert.deepEqual(clean(actual.weekSummary(loaded, '2026-10-23')), [2, 1]);
assert.equal(actual.buildExerciseTrendDetail(loaded, meta).points[0].value, 15);
db.close();
// Run the complete existing strength regression suite against the actual ArkTS,
// with portable dependencies in the same Node realm (deep equality stays strict).
const sourceOf = relative => readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8')
  .replace(/^import[\s\S]*?from\s+['"][^'"]+['"];\r?\n/gm, '');
const realModule = ['common/DateUtil.ets', 'model/CardioModels.ets', 'common/TrendLogic.ets'].map(sourceOf).join('\n');
const realUrl = 'data:text/javascript;base64,' + Buffer.from(stripTypeScriptTypes(realModule)).toString('base64');
const oldSuite = readFileSync(new URL('./verify_trend_logic.mjs', import.meta.url), 'utf8').replace('./trend_logic.mjs', realUrl);
await import('data:text/javascript;base64,' + Buffer.from(oldSuite).toString('base64'));
console.log('cardio trends: actual ArkTS, mirror parity, strength exclusions and SQLite mappings passed');
