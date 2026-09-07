import { strict as assert } from 'assert';
import {
  mapLegacyTag,
  flattenDayExerciseOrder,
  parseWeight,
  parseReps,
  inheritFromPreviousSet,
  statusAfterEdit,
  toggleSetStatus,
  isWeightPr,
  isRepsPr,
  retainBackupNames,
  groupExercisesByPart,
  datesWithDoneSets,
  setCsvHeader,
  setToCsvRow,
  formatLastHint,
  formatBackupName,
  customExerciseId,
  dayDotKind,
  calendarCellKey
} from './workout_logic.mjs';

// --- legacy tag split ---
assert.deepEqual(mapLegacyTag('warmup'), { isWarmup: 1, technique: null });
assert.deepEqual(mapLegacyTag('drop'), { isWarmup: 0, technique: 'drop' });
assert.deepEqual(mapLegacyTag('ramp'), { isWarmup: 0, technique: 'ramp' });
assert.deepEqual(mapLegacyTag('working'), { isWarmup: 0, technique: null });
assert.deepEqual(mapLegacyTag('unknown'), { isWarmup: 0, technique: null });

// --- flatten day_parts into day_exercises sort_order ---
const flattened = flattenDayExerciseOrder([
  { id: 10, partId: 1, partSort: 0, exSort: 0, exerciseId: 'chest_a' },
  { id: 11, partId: 2, partSort: 1, exSort: 0, exerciseId: 'back_a' },
  { id: 12, partId: 3, partSort: 2, exSort: 0, exerciseId: 'chest_b' },
  { id: 13, partId: 1, partSort: 0, exSort: 1, exerciseId: 'chest_c' }
]);
assert.deepEqual(flattened.map((r) => r.id), [10, 13, 11, 12]);
assert.deepEqual(flattened.map((r) => r.sortOrder), [0, 1, 2, 3]);

// --- parse weight / reps ---
assert.deepEqual(parseWeight(''), { ok: true, value: null, error: '' });
assert.deepEqual(parseWeight('  '), { ok: true, value: null, error: '' });
assert.deepEqual(parseWeight('60'), { ok: true, value: 60, error: '' });
assert.deepEqual(parseWeight('12.5'), { ok: true, value: 12.5, error: '' });
assert.equal(parseWeight('.').ok, false);
assert.equal(parseWeight('-1').ok, false);
assert.deepEqual(parseReps(''), { ok: true, value: null, error: '' });
assert.deepEqual(parseReps('8'), { ok: true, value: 8, error: '' });
assert.equal(parseReps('8.5').ok, false);
assert.equal(parseReps('-2').ok, false);

// --- inherit ---
assert.deepEqual(
  inheritFromPreviousSet({ weight: 60, reps: 5 }, null),
  { weight: 60, reps: 5 }
);
assert.deepEqual(
  inheritFromPreviousSet(null, { weight: 80, reps: 3 }),
  { weight: 80, reps: 3 }
);
assert.deepEqual(inheritFromPreviousSet(null, null), { weight: null, reps: null });

// --- status machine ---
const edited = statusAfterEdit('planned', 1700000000000);
assert.equal(edited.status, 'done');
assert.equal(edited.completedAt, 1700000000000);
const alreadyDone = statusAfterEdit('done', 1700000000000);
assert.equal(alreadyDone.status, 'done');
assert.equal(alreadyDone.completedAt, null); // keep existing completed_at

const toggledDone = toggleSetStatus('planned', 1700000000000);
assert.equal(toggledDone.status, 'done');
assert.equal(toggledDone.completedAt, 1700000000000);
const toggledPlan = toggleSetStatus('done', 1700000000000);
assert.equal(toggledPlan.status, 'planned');
assert.equal(toggledPlan.completedAt, null);

// --- PR ---
assert.equal(isWeightPr(100, [80, 90], 'done'), true);
assert.equal(isWeightPr(90, [80, 90], 'done'), false);
assert.equal(isWeightPr(100, [80], 'planned'), false);
assert.equal(isRepsPr(60, 8, [{ weight: 60, reps: 5 }, { weight: 80, reps: 3 }], 'done'), true);
assert.equal(isRepsPr(60, 5, [{ weight: 60, reps: 5 }], 'done'), false);
assert.equal(isRepsPr(60, 10, [{ weight: 60, reps: 5 }], 'planned'), false);

// --- backup retention: keep newest 5 ---
const kept = retainBackupNames([
  'workout_backup_20260101_010000.db',
  'workout_backup_20260102_010000.db',
  'workout_backup_20260103_010000.db',
  'workout_backup_20260104_010000.db',
  'workout_backup_20260105_010000.db',
  'workout_backup_20260106_010000.db'
]);
assert.deepEqual(kept.keep, [
  'workout_backup_20260102_010000.db',
  'workout_backup_20260103_010000.db',
  'workout_backup_20260104_010000.db',
  'workout_backup_20260105_010000.db',
  'workout_backup_20260106_010000.db'
]);
assert.deepEqual(kept.remove, ['workout_backup_20260101_010000.db']);
assert.equal(formatBackupName(new Date('2026-09-04T15:04:00+08:00')).startsWith('workout_backup_'), true);

// --- group by part_key, order by first appearance ---
const grouped = groupExercisesByPart([
  { id: 1, exerciseId: 'chest_a', partKey: 'chest', sortOrder: 0, name: '卧推' },
  { id: 2, exerciseId: 'back_a', partKey: 'back', sortOrder: 1, name: '划船' },
  { id: 3, exerciseId: 'chest_b', partKey: 'chest', sortOrder: 2, name: '飞鸟' }
]);
assert.deepEqual(grouped.map((g) => g.partKey), ['chest', 'back']);
assert.deepEqual(grouped[0].exercises.map((e) => e.exerciseId), ['chest_a', 'chest_b']);

// --- calendar marks only done ---
assert.deepEqual(
  datesWithDoneSets([
    { date: '2026-09-01', status: 'planned' },
    { date: '2026-09-02', status: 'done' },
    { date: '2026-09-02', status: 'planned' },
    { date: '2026-09-03', status: 'done' }
  ]).sort(),
  ['2026-09-02', '2026-09-03']
);

// --- CSV ---
const header = setCsvHeader();
assert.ok(header.includes('status'));
assert.ok(header.includes('rir'));
assert.ok(header.includes('completed_at'));
const row = setToCsvRow({
  date: '2026-09-04',
  exerciseName: '杠铃卧推',
  exerciseId: 'chest_bb_bench',
  partKey: 'chest',
  weight: 60,
  reps: 5,
  isWarmup: 0,
  technique: null,
  rir: null,
  status: 'done',
  completedAt: 1700000000000,
  note: 'ok, "quoted"',
  sortOrder: 0
});
assert.ok(row.includes('done'));
assert.ok(row.includes('')); // null rir stays empty, not 0
assert.ok(!row.includes('undefined'));

// --- last hint ---
assert.equal(
  formatLastHint('2026-08-28', [
    { weight: 60, reps: 5 },
    { weight: 60, reps: 5 },
    { weight: 60, reps: 4 }
  ]),
  '上次 8月28日：60×5 / 60×5 / 60×4'
);
assert.equal(formatLastHint('', []), '');

assert.equal(customExerciseId(1700000000000), 'usr_1700000000000');

const today = '2026-09-04';
assert.equal(dayDotKind('2026-09-01', today, false, false), 'rest');
assert.equal(dayDotKind('2026-09-01', today, false, true), 'planned');
assert.equal(dayDotKind('2026-09-01', today, true, true), 'trained');
assert.equal(dayDotKind('2026-09-04', today, false, false), 'empty');
assert.equal(dayDotKind('2026-09-04', today, false, true), 'planned');
assert.equal(dayDotKind('2026-09-04', today, true, false), 'trained');
assert.equal(dayDotKind('2026-09-10', today, false, false), 'empty');
assert.equal(dayDotKind('2026-09-10', today, false, true), 'planned');
assert.equal(calendarCellKey('2026-09-01', 'rest'), '2026-09-01#rest');
assert.notEqual(
  calendarCellKey('2026-09-01', 'rest'),
  calendarCellKey('2026-09-01', 'trained'),
  'ForEach key must change when a rest day becomes trained'
);

console.log('v1 logic: all checks passed');
