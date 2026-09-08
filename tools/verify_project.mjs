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
  'entry/src/main/ets/pages/MainPage.ets',
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/pages/TrendsPage.ets',
  'entry/src/main/ets/pages/MinePage.ets',
  'entry/src/main/ets/pages/DayDetailPage.ets',
  'entry/src/main/ets/pages/BodyMetricsPage.ets',
  'entry/src/main/ets/pages/MusclePickerPage.ets',
  'entry/src/main/ets/components/MonthCalendar.ets',
  'entry/src/main/ets/components/PartSection.ets',
  'entry/src/main/ets/components/ExerciseCard.ets',
  'entry/src/main/ets/components/SetRow.ets',
  'entry/src/main/ets/components/BodyPartSheet.ets',
  'entry/src/main/ets/components/ExerciseSheet.ets',
  'entry/src/main/ets/components/ExerciseInfoView.ets',
  'entry/src/main/ets/components/CreateExerciseSheet.ets',
  'entry/src/main/ets/components/MuscleSceneView.ets',
  'entry/src/main/ets/model/types.ets',
  'entry/src/main/ets/model/muscleTypes.ets',
  'entry/src/main/ets/model/exerciseCatalog.ets',
  'entry/src/main/ets/model/exerciseDetails.ets',
  'entry/src/main/ets/model/exerciseArtwork.ets',
  'entry/src/main/ets/common/ExerciseLogic.ets',
  'entry/src/main/ets/model/DayModels.ets',
  'entry/src/main/ets/common/DateUtil.ets',
  'entry/src/main/ets/common/InputUtil.ets',
  'entry/src/main/ets/common/WorkoutLogic.ets',
  'entry/src/main/ets/common/MuscleLogic.ets',
  'entry/src/main/ets/common/OrbitCamera.ets',
  'entry/src/main/ets/common/SceneInteraction.ets',
  'entry/src/main/ets/common/AppSettings.ets',
  'entry/src/main/ets/db/WorkoutDatabase.ets',
  'entry/src/main/ets/db/WorkoutRepository.ets',
  'entry/src/main/ets/db/schemaSql.ets',
  'entry/src/main/ets/db/ExerciseSeed.ets',
  'entry/src/main/ets/db/BackupService.ets',
  'entry/src/main/ets/db/ExportService.ets',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/src/main/resources/base/element/color.json',
  'entry/src/main/resources/dark/element/color.json',
  'entry/src/main/resources/base/media/startIcon.png',
  'entry/src/main/resources/rawfile/models/body_muscles.glb',
  'entry/src/main/resources/rawfile/models/LICENSE.txt',
  'entry/src/main/resources/rawfile/exercises/ATTRIBUTION.md',
  'entry/src/main/resources/rawfile/exercises/LICENSE.txt'
];

for (const rel of requiredFiles) {
  assert(existsSync(join(root, rel)), `missing ${rel}`);
}

const catalog = readFileSync(join(root, 'entry/src/main/ets/model/exerciseCatalog.ets'), 'utf8');
const ids = [...catalog.matchAll(/id: '([^']+)'/g)].map((m) => m[1]);
assert(ids.length >= 100 && ids.length <= 150, `catalog should have 100-150 exercises, got ${ids.length}`);
assert(new Set(ids).size === ids.length, 'exercise ids must be unique');

const parts = ['chest', 'shoulder', 'back', 'arm', 'glute', 'leg', 'abs', 'core', 'cardio'];
for (const part of parts) {
  const count = [...catalog.matchAll(new RegExp(`partKey: '${part}'`, 'g'))].length;
  assert(count > 0, `catalog missing part ${part}`);
}

const repo = readFileSync(join(root, 'entry/src/main/ets/db/WorkoutRepository.ets'), 'utf8');
for (const method of [
  'listMonthDayMarks',
  'loadLatestBodyMetric',
  'loadDay',
  'addExercise',
  'addExercisesBatch',
  'listExercisesAll',
  'listAddedExerciseIds',
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
assert(repo.includes("status = 'done'") || repo.includes('status = \\\'done\\\''), 'month marks must still detect done sets');

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
assert(pages.includes('pages/MainPage'), 'main_pages should register MainPage first');
assert(pages.includes('pages/DayDetailPage'), 'main_pages should register DayDetailPage');
assert(pages.includes('pages/BodyMetricsPage'), 'main_pages should register BodyMetricsPage');
assert(pages.includes('pages/MusclePickerPage'), 'main_pages should register MusclePickerPage');
assert(!pages.includes('pages/CalendarPage'), 'CalendarPage is a tab component, not a router page');

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
assert(dayPage.includes('viewMode'), 'day page must remember part/exercise view mode');
assert(dayPage.includes('openMusclePicker') || dayPage.includes('MusclePickerPage'), 'exercise mode opens muscle picker');
assert(!dayPage.includes('autoOpenPart'), 'empty days must not auto-open the part picker');
assert(dayPage.includes('day.exercises'), 'day model must expose ordered exercises');
assert(dayPage.includes('openExerciseInfo'), 'day page must open exercise info from added cards');
assert(dayPage.includes("sheetMode === 'info'"), 'day page must host a read-only info sheet');

const calendar = readFileSync(join(root, 'entry/src/main/ets/pages/CalendarPage.ets'), 'utf8');
assert(calendar.includes('记录今天'), 'calendar must have today shortcut');
assert(calendar.includes('todayString'), 'today shortcut must open today');
assert(calendar.includes('休息'), 'calendar legend must include rest');
assert(calendar.includes('已训练'), 'calendar legend must include trained');
assert(calendar.includes('已计划'), 'calendar legend must include planned');
assert(calendar.includes('未安排'), 'calendar legend must include empty');
assert(!calendar.includes('@Entry'), 'calendar must be a tab component without @Entry');
assert(!calendar.includes('体重'), 'weight entry moved to MinePage');
assert(!calendar.includes('导出 JSON'), 'export moved to MinePage');

const mainPage = readFileSync(join(root, 'entry/src/main/ets/pages/MainPage.ets'), 'utf8');
assert(mainPage.includes('日历'), 'main tabs must include calendar');
assert(mainPage.includes('趋势'), 'main tabs must include trends');
assert(mainPage.includes('我的'), 'main tabs must include mine');
assert(mainPage.includes('BarPosition.End'), 'tabs bar must sit at the bottom');

const mine = readFileSync(join(root, 'entry/src/main/ets/pages/MinePage.ets'), 'utf8');
assert(mine.includes('身高'), 'mine must record height');
assert(mine.includes('浅色'), 'mine must offer light theme');
assert(mine.includes('暗色'), 'mine must offer dark theme');
assert(mine.includes('导出 JSON/CSV'), 'export lives on mine');
assert(mine.includes('pages/BodyMetricsPage'), 'mine must open daily weight page');

const trends = readFileSync(join(root, 'entry/src/main/ets/pages/TrendsPage.ets'), 'utf8');
assert(trends.includes('趋势图表稍后提供'), 'trends is a placeholder');

const ability = readFileSync(join(root, 'entry/src/main/ets/entryability/EntryAbility.ets'), 'utf8');
assert(ability.includes('pages/MainPage'), 'EntryAbility must load MainPage');
assert(ability.includes('AppSettings'), 'EntryAbility must apply saved theme');

const colors = readFileSync(join(root, 'entry/src/main/resources/base/element/color.json'), 'utf8');
assert(colors.includes('dot_rest'), 'light colors must include rest dot');
assert(colors.includes('dot_planned'), 'light colors must include planned dot');
assert(colors.includes('dot_empty'), 'light colors must include empty dot');

const setRow = readFileSync(join(root, 'entry/src/main/ets/components/SetRow.ets'), 'utf8');
assert(!setRow.includes('Select(['), 'tag Select should be replaced by compact chip');
assert(setRow.includes('练到力竭') || setRow.includes('rirLabel'), 'last set should expose rir chips');

const typesSrc = readFileSync(join(root, 'entry/src/main/ets/model/types.ets'), 'utf8');
assert(typesSrc.includes("'band'"), 'equipment must include band');
assert(typesSrc.includes("'kettlebell'"), 'equipment must include kettlebell');
assert(typesSrc.includes("'ezbar'"), 'equipment must include ezbar');
assert(typesSrc.includes("return 'other'"), 'unknown equipment must not default to barbell');

const sheet = readFileSync(join(root, 'entry/src/main/ets/components/ExerciseSheet.ets'), 'utf8');
assert(sheet.includes('详情'), 'exercise sheet must have a detail entry');
assert(sheet.includes('搜索名称') || sheet.includes('searchText'), 'exercise sheet must search');
assert(sheet.includes('重试'), 'exercise sheet must retry after load failure');

const card = readFileSync(join(root, 'entry/src/main/ets/components/ExerciseCard.ets'), 'utf8');
assert(card.includes('详情'), 'added exercise cards must open details');
assert(card.includes('onOpenDetail'), 'added exercise cards must expose a detail callback');

const logic = readFileSync(join(root, 'entry/src/main/ets/common/WorkoutLogic.ets'), 'utf8');
for (const name of ['mapLegacyTag', 'parseWeight', 'statusAfterEdit', 'isWeightPr', 'retainBackupNames', 'formatLastHint', 'dayDotKind', 'calendarCellKey']) {
  assert(logic.includes(name), `WorkoutLogic missing ${name}`);
}

console.log(`project files + catalog: ${ids.length} exercises, all checks passed`);
