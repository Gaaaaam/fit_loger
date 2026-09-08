import { strict as assert } from 'assert';
import {
  addDays,
  isoWeekStart,
  rangeStart,
  daysSinceEpoch,
  isWorkSet,
  isLiftPerformancePoint,
  isCompoundLift,
  epleyE1rm,
  isE1rmEligible,
  chartFromDate,
  formatTrendNumber,
  liftMetricLabel,
  liftChangeText,
  weightDeltaText,
  resolveWatchedLifts,
  buildLiftSeries,
  weekSummary,
  buildWeekGoalProgress,
  buildWeightTrend,
  datedChartPositions,
  buildTrendInsight,
  buildTrendDigest,
  buildExerciseTrendDetail
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
    technique: '',
    status: 'done'
  }, partial);
}

function prefs(partial) {
  return Object.assign({
    watchedExerciseIds: [],
    sessionsTarget: null,
    partGoals: []
  }, partial);
}

// ---- date helpers ----
assert.equal(isoWeekStart('2026-09-07'), '2026-09-07');
assert.equal(isoWeekStart('2026-09-09'), '2026-09-07');
assert.equal(isoWeekStart('2026-09-13'), '2026-09-07');
assert.equal(addDays('2026-09-07', -1), '2026-09-06');
assert.equal(rangeStart('2026-09-07', 4), '2026-08-11');
assert.equal(chartFromDate('2026-09-07', 'all'), '');
assert.equal(chartFromDate('2026-09-07', '12'), rangeStart('2026-09-07', 12));
assert.equal(daysSinceEpoch('2026-09-08') - daysSinceEpoch('2026-09-01'), 7);
assert.equal(daysSinceEpoch('2026-09-01') - daysSinceEpoch('2026-09-08'), -7);

// ---- basic predicates ----
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
assert.equal(isWorkSet(row({ technique: 'drop' })), true, 'drop sets still count toward volume');

// ---- technique exclusion from performance points ----
assert.equal(isLiftPerformancePoint(row({ technique: 'drop' })), false);
assert.equal(isLiftPerformancePoint(row({ technique: 'ramp' })), false);
assert.equal(isLiftPerformancePoint(row({ technique: 'rest_pause' })), false);
assert.equal(isLiftPerformancePoint(row({ technique: 'amrap' })), true, 'amrap remains eligible');
assert.equal(isLiftPerformancePoint(row({ status: 'planned' })), false);

assert.equal(isE1rmEligible(row({ rir: null })), false);
assert.equal(isE1rmEligible(row({ rir: 3 })), false);
assert.equal(isE1rmEligible(row({ reps: 10 })), false);
assert.equal(isE1rmEligible(row({ rir: 0, reps: 8 })), true);
assert.equal(isE1rmEligible(row({ status: 'planned', rir: 0 })), false);
assert.equal(isE1rmEligible(row({ technique: 'drop', rir: 0 })), false, 'drop set cannot set e1RM');
assert.equal(isE1rmEligible(row({ technique: 'amrap', rir: 0, reps: 6 })), true);

// ---- stable metric assignment (no runtime switching) ----
const sparseCompound = [
  row({ date: '2026-08-10', weight: 60, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 62.5, reps: 5, rir: 3 })
];
const compoundPick = {
  exerciseId: 'chest_bb_bench', name: '杠铃卧推', partKey: 'chest', movementPattern: 'push',
  isBodyweight: 0, isCompound: true, sessions: 2, workSets: 2
};
const sparseSeries = buildLiftSeries(sparseCompound, compoundPick);
assert.equal(sparseSeries.metric, 'e1rm', 'compound lifts always use e1RM, even with few data points');
assert.equal(sparseSeries.points.length, 1, 'only the RIR<=1 set qualifies');

const noisy = [
  row({ date: '2026-08-10', weight: 60, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 62.5, reps: 5, rir: 1 }),
  row({ date: '2026-08-17', weight: 40, reps: 12, rir: null, isWarmup: 0 }),
  row({ date: '2026-08-24', weight: 50, reps: 8, status: 'planned' }),
  row({ date: '2026-08-24', weight: 40, reps: 10, isWarmup: 1, rir: 0 })
];
const e1rmSeries = buildLiftSeries(noisy, compoundPick);
assert.equal(e1rmSeries.metric, 'e1rm');
assert.equal(e1rmSeries.points.length, 2);
assert.equal(e1rmSeries.points[0].value, 70);
assert.equal(e1rmSeries.points[1].value, 62.5 * (1 + 5 / 30));

// drop/ramp/rest_pause sets must not set a new top_weight / e1RM
const isolationPick = {
  exerciseId: 'arm_bb_curl', name: '杠铃弯举', partKey: 'arm', movementPattern: 'isolation',
  isBodyweight: 0, isCompound: false, sessions: 2, workSets: 3
};
const techniqueRows = [
  row({
    date: '2026-08-10', exerciseId: 'arm_bb_curl', exerciseName: '杠铃弯举', partKey: 'arm',
    movementPattern: 'isolation', weight: 30, reps: 8, rir: 1
  }),
  row({
    date: '2026-08-17', exerciseId: 'arm_bb_curl', exerciseName: '杠铃弯举', partKey: 'arm',
    movementPattern: 'isolation', weight: 40, reps: 6, rir: 0, technique: 'drop'
  })
];
const isolationSeries = buildLiftSeries(techniqueRows, isolationPick);
assert.equal(isolationSeries.metric, 'top_weight');
assert.deepEqual(isolationSeries.points.map((p) => p.value), [30], 'drop set weight must not override top weight');

// bodyweight metric uses the best single set, not the day total
const pullRows = [
  row({
    date: '2026-08-10', exerciseId: 'back_pullup', exerciseName: '引体向上', partKey: 'back',
    movementPattern: 'pull', isBodyweight: 1, weight: 0, reps: 8, rir: 0
  }),
  row({
    date: '2026-08-10', exerciseId: 'back_pullup', exerciseName: '引体向上', partKey: 'back',
    movementPattern: 'pull', isBodyweight: 1, weight: 0, reps: 6, rir: 0
  }),
  row({
    date: '2026-08-24', exerciseId: 'back_pullup', exerciseName: '引体向上', partKey: 'back',
    movementPattern: 'pull', isBodyweight: 1, weight: 0, reps: 10, rir: 1
  })
];
const pullSeries = buildLiftSeries(pullRows, {
  exerciseId: 'back_pullup', name: '引体向上', partKey: 'back', movementPattern: 'pull',
  isBodyweight: 1, isCompound: true, sessions: 2, workSets: 3
});
assert.equal(pullSeries.metric, 'reps');
assert.deepEqual(pullSeries.points.map((p) => p.value), [8, 10], 'best single set, not day total (8, not 14)');

// ---- resolveWatchedLifts: pinned order, no forced part dedup, empty -> auto ----
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
const autoPicks = resolveWatchedLifts(crowded, [], 3);
assert.equal(autoPicks.length, 3, 'auto-recommend is capped at the requested limit');
assert.deepEqual(autoPicks.map((p) => p.exerciseId), ['leg_squat', 'chest_bb_bench', 'back_deadlift']);

const pinnedSameParts = resolveWatchedLifts(crowded, ['chest_bb_bench', 'chest_db_bench', 'leg_squat'], 3);
assert.deepEqual(pinnedSameParts.map((p) => p.exerciseId), ['chest_bb_bench', 'chest_db_bench', 'leg_squat'],
  'two exercises from the same part can both be pinned');

const pinnedWithMissing = resolveWatchedLifts(crowded, ['unknown_ex', 'back_deadlift', 'unknown_ex'], 3);
assert.deepEqual(pinnedWithMissing.map((p) => p.exerciseId), ['back_deadlift'],
  'unknown or duplicate ids are skipped, no auto-fill happens once configured');

const onlyIsolation = [
  row({
    date: '2026-08-10', exerciseId: 'arm_bb_curl', exerciseName: '杠铃弯举', partKey: 'arm', movementPattern: 'isolation'
  }),
  row({
    date: '2026-08-10', exerciseId: 'cardio_jump_rope', exerciseName: '跳绳', partKey: 'cardio', movementPattern: 'isolation'
  })
];
const isoPicks = resolveWatchedLifts(onlyIsolation, [], 4);
assert.deepEqual(isoPicks.map((p) => p.exerciseId), ['arm_bb_curl']);

// ---- weekSummary ----
const today = '2026-09-07';
const volumeRows = [
  row({ date: '2026-09-07', partKey: 'chest' }),
  row({ date: '2026-09-07', partKey: 'chest' }),
  row({ date: '2026-09-07', partKey: 'chest', status: 'planned' }),
  row({ date: '2026-09-07', partKey: 'chest', isWarmup: 1 }),
  row({ date: '2026-09-07', partKey: 'back', movementPattern: 'pull', exerciseId: 'back_bb_row' }),
  row({ date: '2026-08-31', partKey: 'chest' }),
  row({ date: '2026-08-24', partKey: 'chest' })
];
assert.deepEqual(weekSummary(volumeRows, today), [1, 3]);

// ---- buildWeekGoalProgress: goal-based, mid-week shows progress not a verdict ----
const goalProgress = buildWeekGoalProgress(volumeRows, today, prefs({
  sessionsTarget: 4,
  partGoals: [{ partKey: 'chest', workSetsTarget: 6 }, { partKey: 'leg', workSetsTarget: 8 }]
}));
assert.equal(goalProgress.sessionsDone, 1);
assert.equal(goalProgress.sessionsTarget, 4);
assert.deepEqual(goalProgress.parts.map((p) => [p.partKey, p.done, p.target]), [
  ['chest', 2, 6],
  ['leg', 0, 8]
], 'parts with no data still show up with done=0 when a target exists');

const noGoals = buildWeekGoalProgress(volumeRows, today, prefs({}));
assert.equal(noGoals.parts.length, 0, 'no target configured means no part rows, not an avg-4-week comparison');

// ---- buildWeightTrend: 7-day rolling average vs sparse fallback ----
const denseWeights = [];
for (let i = 13; i >= 0; i--) {
  // i counts days before today; larger i = further in the past.
  // weight decreases as i decreases (i.e. trends down approaching today).
  denseWeights.push({ date: addDays(today, -i), weightKg: 79 + i * 0.1 });
}
const denseTrend = buildWeightTrend(denseWeights, today);
assert.equal(denseTrend.sparse, false);
assert.equal(denseTrend.hasDelta, true);
assert.ok(denseTrend.deltaKg < 0, 'weight trending down over two weeks');

const sparseWeights = [
  { date: '2026-08-01', weightKg: 73 },
  { date: '2026-09-01', weightKg: 72.4 }
];
const sparseTrend = buildWeightTrend(sparseWeights, today);
assert.equal(sparseTrend.sparse, true);
assert.equal(sparseTrend.hasWeight, true);
assert.equal(sparseTrend.latestKg, 72.4);
assert.equal(sparseTrend.hasDelta, true);
assert.ok(Math.abs(sparseTrend.deltaKg - (-0.6)) < 1e-9);
assert.equal(sparseTrend.referenceDate, '2026-08-01');
assert.equal(weightDeltaText(sparseTrend), '72.4 kg · 较 2026-08-01 -0.6');

const singleWeight = buildWeightTrend([{ date: '2026-09-01', weightKg: 72 }], today);
assert.equal(singleWeight.hasWeight, true);
assert.equal(singleWeight.hasDelta, false);
assert.equal(weightDeltaText(singleWeight), '72 kg');

const noWeight = buildWeightTrend([], today);
assert.equal(weightDeltaText(noWeight), '未记录');

// ---- datedChartPositions: real date spacing, not index spacing ----
const unevenPoints = [
  { date: '2026-08-01', value: 10 },
  { date: '2026-08-02', value: 20 },
  { date: '2026-09-01', value: 30 }
];
const positioned = datedChartPositions(unevenPoints);
assert.equal(positioned[0].xRatio, 0);
assert.equal(positioned[2].xRatio, 1);
assert.ok(positioned[1].xRatio < 0.1, 'one day out of a 31-day span should sit near the start');

const singlePoint = datedChartPositions([{ date: '2026-08-01', value: 5 }]);
assert.equal(singlePoint[0].xRatio, 0.5);
assert.deepEqual(datedChartPositions([]), []);

// ---- buildTrendInsight: priority order, and the <3-point guard ----
const setupInsight = buildTrendInsight(prefs({}), { sessionsDone: 0, sessionsTarget: null, parts: [] }, []);
assert.equal(setupInsight.kind, 'setup');

const sessionGoalInsight = buildTrendInsight(
  prefs({ sessionsTarget: 4 }),
  { sessionsDone: 1, sessionsTarget: 4, parts: [] },
  []
);
assert.equal(sessionGoalInsight.kind, 'session_goal');
assert.equal(sessionGoalInsight.remaining, 3);

const partGoalInsight = buildTrendInsight(
  prefs({ sessionsTarget: 4 }),
  { sessionsDone: 4, sessionsTarget: 4, parts: [{ partKey: 'chest', done: 2, target: 6 }] },
  []
);
assert.equal(partGoalInsight.kind, 'part_goal');
assert.equal(partGoalInsight.partKey, 'chest');
assert.equal(partGoalInsight.remaining, 4);

const risingLift = { exerciseId: 'x', name: '卧推', metric: 'e1rm', points: [1, 2, 3], firstValue: 60, lastValue: 70 };
const fallingLift = { exerciseId: 'y', name: '深蹲', metric: 'e1rm', points: [1, 2, 3], firstValue: 100, lastValue: 90 };
const tooFewPoints = { exerciseId: 'z', name: '划船', metric: 'top_weight', points: [1, 2], firstValue: 40, lastValue: 30 };

const goalsMetInsight = buildTrendInsight(
  prefs({ sessionsTarget: 4 }),
  { sessionsDone: 4, sessionsTarget: 4, parts: [{ partKey: 'chest', done: 6, target: 6 }] },
  [tooFewPoints, fallingLift]
);
assert.equal(goalsMetInsight.kind, 'stall', 'falling lift with >=3 points wins over the 2-point lift');
assert.equal(goalsMetInsight.exerciseId, 'y');

const progressInsight = buildTrendInsight(
  prefs({ sessionsTarget: 4 }),
  { sessionsDone: 4, sessionsTarget: 4, parts: [] },
  [risingLift]
);
assert.equal(progressInsight.kind, 'progress');

const noInsight = buildTrendInsight(
  prefs({ sessionsTarget: 4 }),
  { sessionsDone: 4, sessionsTarget: 4, parts: [] },
  [tooFewPoints]
);
assert.equal(noInsight.kind, 'none', 'fewer than 3 comparable points must not produce a verdict');

// ---- buildTrendDigest integration ----
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
  '12',
  prefs({ watchedExerciseIds: ['chest_bb_bench'] })
);
assert.equal(digest.sessions, 1);
assert.equal(digest.workSets, 1);
assert.equal(digest.weightTrend.hasWeight, true);
assert.equal(digest.lifts.length, 1);
assert.equal(digest.lifts[0].metric, 'e1rm');
assert.equal(digest.lifts[0].points.length, 3);
assert.equal(digest.weightPoints.length, 2);
assert.equal(formatTrendNumber(70), '70');
assert.equal(formatTrendNumber(62.5 * (1 + 5 / 30)), '72.9');

const emptyDigest = buildTrendDigest([], [], today, '12', prefs({}));
assert.equal(emptyDigest.sessions, 0);
assert.equal(emptyDigest.weightTrend.hasWeight, false);
assert.equal(emptyDigest.lifts.length, 0);
assert.equal(emptyDigest.insight.kind, 'setup');

// ---- buildExerciseTrendDetail ----
const compoundMeta = {
  exerciseId: 'chest_bb_bench', name: '杠铃卧推', partKey: 'chest', movementPattern: 'push', isBodyweight: 0
};
const compoundDetail = buildExerciseTrendDetail(noisy, compoundMeta);
assert.equal(compoundDetail.metric, 'e1rm');
assert.equal(compoundDetail.points.length, 2);
assert.equal(compoundDetail.insufficientData, false);
assert.equal(compoundDetail.sessions, 2);
assert.equal(compoundDetail.workSets, 3);
assert.equal(compoundDetail.recentSessions.length, 2);
assert.equal(compoundDetail.recentSessions[0].date, '2026-08-17', 'most recent session first');

const sparseCompoundDetail = buildExerciseTrendDetail(sparseCompound, compoundMeta);
assert.equal(sparseCompoundDetail.insufficientData, true, 'fewer than 2 e1RM points must be flagged, not hidden');

const isolationMeta = {
  exerciseId: 'arm_bb_curl', name: '杠铃弯举', partKey: 'arm', movementPattern: 'isolation', isBodyweight: 0
};
const isolationDetail = buildExerciseTrendDetail(techniqueRows, isolationMeta);
assert.equal(isolationDetail.metric, 'top_weight');
assert.equal(isolationDetail.secondaryLabel, '同重量下的次数');
assert.deepEqual(isolationDetail.secondaryPoints.map((p) => p.value), [8], 'only the top-weight (30kg) session counts');

console.log('trend logic checks passed');
