import { strict as assert } from 'assert';
import {
  addDays,
  isoWeekStart,
  rangeStart,
  isWorkSet,
  isCompoundLift,
  epleyE1rm,
  isE1rmEligible,
  chartFromDate,
  digestQueryStart,
  formatTrendNumber,
  pickKeyLifts,
  buildLiftSeries,
  weekSummary,
  partVolumeRows,
  buildTrendDigest,
  weightDeltaText
} from './trend_logic.mjs';

function row(partial) {
  return Object.assign({
    date: '2026-09-07',
    exerciseId: 'chest_bb_bench',
    exerciseName: '杠铃卧推',
    partKey: 'chest',
    movementPattern: 'push',
    isBodyweight: 0,
    weight: 60,
    reps: 5,
    rir: 1,
    isWarmup: 0,
    status: 'done'
  }, partial);
}

assert.equal(isoWeekStart('2026-09-07'), '2026-09-07');
assert.equal(isoWeekStart('2026-09-09'), '2026-09-07');
assert.equal(isoWeekStart('2026-09-13'), '2026-09-07');
assert.equal(addDays('2026-09-07', -1), '2026-09-06');
assert.equal(rangeStart('2026-09-07', 4), '2026-08-11');
assert.equal(chartFromDate('2026-09-07', 'all'), '');
assert.equal(chartFromDate('2026-09-07', '12'), rangeStart('2026-09-07', 12));
assert.equal(digestQueryStart('2026-09-07', 'all'), '');
assert.equal(digestQueryStart('2026-09-07', '4'), addDays('2026-09-07', -28));

assert.equal(isCompoundLift('push', 'chest'), true);
assert.equal(isCompoundLift('hinge', 'back'), true);
assert.equal(isCompoundLift('isolation', 'chest'), false);
assert.equal(isCompoundLift('push', 'abs'), false);
assert.equal(isCompoundLift('push', 'cardio'), false);
assert.equal(isCompoundLift('lunge', 'leg'), false);

assert.equal(epleyE1rm(60, 5), 70);
assert.equal(epleyE1rm(100, 1), 100 * (1 + 1 / 30));
assert.equal(epleyE1rm(null, 5), null);
assert.equal(epleyE1rm(60, 0), null);

assert.equal(isWorkSet(row({ status: 'planned' })), false);
assert.equal(isWorkSet(row({ isWarmup: 1 })), false);
assert.equal(isE1rmEligible(row({ rir: null })), false);
assert.equal(isE1rmEligible(row({ rir: 3 })), false);
assert.equal(isE1rmEligible(row({ reps: 10 })), false);
assert.equal(isE1rmEligible(row({ rir: 0, reps: 8 })), true);
assert.equal(isE1rmEligible(row({ status: 'planned', rir: 0 })), false);

const noisy = [
  row({ date: '2026-08-10', weight: 60, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 62.5, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 40, reps: 12, rir: null, isWarmup: 0 }),
  row({ date: '2026-08-24', weight: 50, reps: 8, status: 'planned' }),
  row({ date: '2026-08-24', weight: 40, reps: 10, isWarmup: 1, rir: 0 })
];
const benchPick = {
  exerciseId: 'chest_bb_bench',
  name: '杠铃卧推',
  partKey: 'chest',
  movementPattern: 'push',
  isBodyweight: 0,
  isCompound: true,
  sessions: 2,
  workSets: 2
};
const e1rmSeries = buildLiftSeries(noisy, benchPick);
assert.equal(e1rmSeries.metric, 'e1rm');
assert.equal(e1rmSeries.points.length, 2);
assert.equal(e1rmSeries.points[0].value, 70);
assert.equal(e1rmSeries.points[1].value, 62.5 * (1 + 5 / 30));

const sparse = [
  row({ date: '2026-08-10', weight: 80, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 85, reps: 5, rir: null }),
  row({ date: '2026-08-24', weight: 90, reps: 3, rir: 3 })
];
const topSeries = buildLiftSeries(sparse, benchPick);
assert.equal(topSeries.metric, 'top_weight');
assert.deepEqual(topSeries.points.map((p) => p.value), [80, 85, 90]);

const pullRows = [
  row({
    date: '2026-08-10',
    exerciseId: 'back_pullup',
    exerciseName: '引体向上',
    partKey: 'back',
    movementPattern: 'pull',
    isBodyweight: 1,
    weight: 0,
    reps: 8,
    rir: 0
  }),
  row({
    date: '2026-08-10',
    exerciseId: 'back_pullup',
    exerciseName: '引体向上',
    partKey: 'back',
    movementPattern: 'pull',
    isBodyweight: 1,
    weight: 0,
    reps: 6,
    rir: 0
  }),
  row({
    date: '2026-08-24',
    exerciseId: 'back_pullup',
    exerciseName: '引体向上',
    partKey: 'back',
    movementPattern: 'pull',
    isBodyweight: 1,
    weight: 0,
    reps: 10,
    rir: 1
  })
];
const pullSeries = buildLiftSeries(pullRows, {
  exerciseId: 'back_pullup',
  name: '引体向上',
  partKey: 'back',
  movementPattern: 'pull',
  isBodyweight: 1,
  isCompound: true,
  sessions: 2,
  workSets: 3
});
assert.equal(pullSeries.metric, 'reps');
assert.deepEqual(pullSeries.points.map((p) => p.value), [14, 10]);

const crowded = [
  row({ date: '2026-08-03', exerciseId: 'chest_bb_bench', exerciseName: '杠铃卧推', partKey: 'chest' }),
  row({ date: '2026-08-10', exerciseId: 'chest_bb_bench', exerciseName: '杠铃卧推', partKey: 'chest' }),
  row({ date: '2026-08-17', exerciseId: 'chest_db_bench', exerciseName: '哑铃卧推', partKey: 'chest' }),
  row({ date: '2026-08-03', exerciseId: 'leg_squat', exerciseName: '杠铃深蹲', partKey: 'leg', movementPattern: 'squat' }),
  row({ date: '2026-08-10', exerciseId: 'leg_squat', exerciseName: '杠铃深蹲', partKey: 'leg', movementPattern: 'squat' }),
  row({ date: '2026-08-17', exerciseId: 'leg_squat', exerciseName: '杠铃深蹲', partKey: 'leg', movementPattern: 'squat' }),
  row({ date: '2026-08-24', exerciseId: 'back_deadlift', exerciseName: '硬拉', partKey: 'back', movementPattern: 'hinge' }),
  row({ date: '2026-08-31', exerciseId: 'arm_bb_curl', exerciseName: '杠铃弯举', partKey: 'arm', movementPattern: 'isolation' })
];
const picks = pickKeyLifts(crowded, 4);
assert.deepEqual(picks.map((p) => p.exerciseId), ['leg_squat', 'chest_bb_bench', 'back_deadlift', 'arm_bb_curl']);
assert.equal(picks[0].isCompound, true);
assert.equal(picks[3].isCompound, false);

const onlyIsolation = [
  row({
    date: '2026-08-10',
    exerciseId: 'arm_bb_curl',
    exerciseName: '杠铃弯举',
    partKey: 'arm',
    movementPattern: 'isolation'
  }),
  row({
    date: '2026-08-10',
    exerciseId: 'cardio_jump_rope',
    exerciseName: '跳绳',
    partKey: 'cardio',
    movementPattern: 'isolation'
  })
];
const isoPicks = pickKeyLifts(onlyIsolation, 4);
assert.deepEqual(isoPicks.map((p) => p.exerciseId), ['arm_bb_curl']);

const today = '2026-09-07';
const volumeRows = [
  row({ date: '2026-09-07', partKey: 'chest' }),
  row({ date: '2026-09-07', partKey: 'chest' }),
  row({ date: '2026-09-07', partKey: 'chest', status: 'planned' }),
  row({ date: '2026-09-07', partKey: 'chest', isWarmup: 1 }),
  row({ date: '2026-09-07', partKey: 'back', movementPattern: 'pull', exerciseId: 'back_bb_row' }),
  row({ date: '2026-08-31', partKey: 'chest' }),
  row({ date: '2026-08-31', partKey: 'chest' }),
  row({ date: '2026-08-24', partKey: 'chest' }),
  row({ date: '2026-08-24', partKey: 'chest' }),
  row({ date: '2026-08-03', partKey: 'chest' })
];
assert.deepEqual(weekSummary(volumeRows, today), [1, 3]);
const parts = partVolumeRows(volumeRows, today);
const chest = parts.find((p) => p.partKey === 'chest');
const back = parts.find((p) => p.partKey === 'back');
const arm = parts.find((p) => p.partKey === 'arm');
assert.equal(chest.thisWeek, 2);
assert.equal(chest.avg4, 1);
assert.equal(back.thisWeek, 1);
assert.equal(back.avg4, 0);
assert.equal(arm, undefined);

const digest = buildTrendDigest(
  [
    row({ date: '2026-08-10', weight: 60, reps: 5, rir: 1 }),
    row({ date: '2026-08-24', weight: 65, reps: 5, rir: 0 }),
    row({ date: '2026-09-07', weight: 70, reps: 4, rir: 1 })
  ],
  [
    { date: '2026-08-01', weightKg: 73 },
    { date: '2026-09-01', weightKg: 72.4 }
  ],
  today,
  '12'
);
assert.equal(digest.sessions, 1);
assert.equal(digest.workSets, 1);
assert.equal(digest.hasWeight, true);
assert.equal(digest.weightKg, 72.4);
assert.equal(digest.hasDelta, true);
assert.ok(Math.abs(digest.weightDelta - (-0.6)) < 1e-9);
assert.equal(weightDeltaText(digest), '72.4 kg · -0.6');
assert.equal(digest.lifts.length, 1);
assert.equal(digest.lifts[0].metric, 'e1rm');
assert.equal(digest.lifts[0].points.length, 3);
assert.equal(digest.weights.length, 2);
assert.equal(formatTrendNumber(70), '70');
assert.equal(formatTrendNumber(62.5 * (1 + 5 / 30)), '72.9');

const emptyDigest = buildTrendDigest([], [], today, '12');
assert.equal(emptyDigest.sessions, 0);
assert.equal(emptyDigest.hasWeight, false);
assert.equal(weightDeltaText(emptyDigest), '未记录');
assert.equal(emptyDigest.lifts.length, 0);
assert.equal(emptyDigest.parts.length, 0);

console.log('trend logic checks passed');
