import { readFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function assert(cond, message) {
  if (!cond) {
    throw new Error(message);
  }
}

const requiredFiles = [
  'AppScope/app.json5',
  'AppScope/resources/base/element/string.json',
  'AppScope/resources/base/media/app_icon.png',
  'build-profile.json5',
  'oh-package.json5',
  'hvigorfile.ts',
  'hvigor/hvigor-config.json5',
  'entry/src/main/module.json5',
  'entry/src/main/ets/entryability/EntryAbility.ets',
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/pages/DayDetailPage.ets',
  'entry/src/main/ets/pages/BodyMetricsPage.ets',
  'entry/src/main/ets/components/MonthCalendar.ets',
  'entry/src/main/ets/components/PartSection.ets',
  'entry/src/main/ets/components/ExerciseCard.ets',
  'entry/src/main/ets/components/SetRow.ets',
  'entry/src/main/ets/components/BodyPartSheet.ets',
  'entry/src/main/ets/components/ExerciseSheet.ets',
  'entry/src/main/ets/components/CreateExerciseSheet.ets',
  'entry/src/main/ets/model/types.ets',
  'entry/src/main/ets/model/exerciseCatalog.ets',
  'entry/src/main/ets/model/DayModels.ets',
  'entry/src/main/ets/common/DateUtil.ets',
  'entry/src/main/ets/common/InputUtil.ets',
  'entry/src/main/ets/common/WorkoutLogic.ets',
  'entry/src/main/ets/db/WorkoutDatabase.ets',
  'entry/src/main/ets/db/WorkoutRepository.ets',
  'entry/src/main/ets/db/schemaSql.ets',
  'entry/src/main/ets/db/ExerciseSeed.ets',
  'entry/src/main/ets/db/BackupService.ets',
  'entry/src/main/ets/db/ExportService.ets',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/src/main/resources/base/element/color.json',
  'entry/src/main/resources/base/media/startIcon.png'
];

for (const rel of requiredFiles) {
  assert(existsSync(join(root, rel)), `missing ${rel}`);
}

const catalog = readFileSync(join(root, 'entry/src/main/ets/model/exerciseCatalog.ets'), 'utf8');
const ids = [...catalog.matchAll(/id: '([^']+)'/g)].map((m) => m[1]);
assert(ids.length > 0, 'catalog should contain exercises');
assert(new Set(ids).size === ids.length, 'exercise ids must be unique');

const parts = ['chest', 'shoulder', 'back', 'arm', 'glute', 'leg'];
for (const part of parts) {
  const count = [...catalog.matchAll(new RegExp(`partKey: '${part}'`, 'g'))].length;
  assert(count > 0, `catalog missing part ${part}`);
}

const repo = readFileSync(join(root, 'entry/src/main/ets/db/WorkoutRepository.ets'), 'utf8');
for (const method of [
  'listDatesInMonth',
  'loadDay',
  'addExercise',
  'addSet',
  'writeSet',
  'deleteSet',
  'deleteExercise',
  'deleteExercisesOfPart',
  'deleteDay',
  'cleanupEmptyDay',
  'copyDay',
  'createCustomExercise',
  'exportAllJson',
  'clearPlannedSets',
  'checkPr',
  'upsertBodyMetric'
]) {
  assert(repo.includes(method), `repository missing ${method}`);
}
assert(!repo.includes('addPart'), 'repository should not keep addPart');
assert(!repo.includes('deletePart('), 'repository should not keep deletePart');
assert(repo.includes("status = 'done'") || repo.includes('status = \\\'done\\\''), 'listDatesInMonth must filter status = done');

const db = readFileSync(join(root, 'entry/src/main/ets/db/WorkoutDatabase.ets'), 'utf8');
assert(db.includes('store.version'), 'database must use store.version');
assert(db.includes('backupBeforeMigrate') || db.includes('.backup('), 'database must backup before migrate');

const schema = readFileSync(join(root, 'entry/src/main/ets/db/schemaSql.ets'), 'utf8');
for (const table of ['exercises', 'workout_days', 'day_exercises', 'workout_sets', 'body_metrics']) {
  assert(schema.includes(table), `schema missing table ${table}`);
}
assert(schema.includes('is_warmup'), 'workout_sets must include is_warmup');
assert(schema.includes("status TEXT NOT NULL DEFAULT 'done'") || schema.includes('status TEXT NOT NULL DEFAULT \\\'done\\\''), 'status default done');

const pages = readFileSync(join(root, 'entry/src/main/resources/base/profile/main_pages.json'), 'utf8');
assert(pages.includes('pages/CalendarPage'), 'main_pages should register CalendarPage');
assert(pages.includes('pages/DayDetailPage'), 'main_pages should register DayDetailPage');
assert(pages.includes('pages/BodyMetricsPage'), 'main_pages should register BodyMetricsPage');

const app = readFileSync(join(root, 'AppScope/app.json5'), 'utf8');
assert(app.includes('com.fitloger.app'), 'bundleName should be com.fitloger.app');
assert(app.includes('训练日志') === false, 'app.json5 uses string resource for label');

const strings = readFileSync(join(root, 'AppScope/resources/base/element/string.json'), 'utf8');
assert(strings.includes('训练日志'), 'app display name should be 训练日志');

const dayPage = readFileSync(join(root, 'entry/src/main/ets/pages/DayDetailPage.ets'), 'utf8');
assert(!dayPage.includes('showPartSheet'), 'DayDetailPage should not reference removed showPartSheet');
assert(dayPage.includes('$$this.showSheet'), 'DayDetailPage should two-way bind the sheet');
assert(!dayPage.includes('@State viewEpoch'), 'DayDetailPage must not remount via viewEpoch');
assert(!dayPage.includes('this.viewEpoch++'), 'reload must not bump viewEpoch');
assert(!dayPage.includes('`${part.id}#${this.viewEpoch}`'), 'parts ForEach must not use viewEpoch keys');
assert(dayPage.includes('part.exercises.push') || dayPage.includes('ex.sets.push'), 'additions must update the in-memory model');
assert(dayPage.includes('记录今天') === false, 'today shortcut lives on calendar');
assert(dayPage.includes('复制上次训练'), 'empty day should offer copy last workout');
assert(dayPage.includes('清理未完成组'), 'planned sets need a cleanup action');

const calendar = readFileSync(join(root, 'entry/src/main/ets/pages/CalendarPage.ets'), 'utf8');
assert(calendar.includes('记录今天'), 'calendar must have today shortcut');
assert(calendar.includes('todayString'), 'today shortcut must open today');

const setRow = readFileSync(join(root, 'entry/src/main/ets/components/SetRow.ets'), 'utf8');
assert(!setRow.includes('Select(['), 'tag Select should be replaced by compact chip');
assert(setRow.includes('练到力竭') || setRow.includes('rirLabel'), 'last set should expose rir chips');

const logic = readFileSync(join(root, 'entry/src/main/ets/common/WorkoutLogic.ets'), 'utf8');
for (const name of ['mapLegacyTag', 'parseWeight', 'statusAfterEdit', 'isWeightPr', 'retainBackupNames', 'formatLastHint']) {
  assert(logic.includes(name), `WorkoutLogic missing ${name}`);
}

console.log(`project files + catalog: ${ids.length} exercises, all checks passed`);
