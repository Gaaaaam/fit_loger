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
  'entry/src/main/ets/components/MonthCalendar.ets',
  'entry/src/main/ets/components/PartSection.ets',
  'entry/src/main/ets/components/ExerciseCard.ets',
  'entry/src/main/ets/components/SetRow.ets',
  'entry/src/main/ets/components/BodyPartSheet.ets',
  'entry/src/main/ets/components/ExerciseSheet.ets',
  'entry/src/main/ets/model/types.ets',
  'entry/src/main/ets/model/exerciseCatalog.ets',
  'entry/src/main/ets/model/DayModels.ets',
  'entry/src/main/ets/common/DateUtil.ets',
  'entry/src/main/ets/common/InputUtil.ets',
  'entry/src/main/ets/db/WorkoutDatabase.ets',
  'entry/src/main/ets/db/WorkoutRepository.ets',
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
  'addPart',
  'addExercise',
  'addSet',
  'updateSet',
  'deleteSet',
  'deleteExercise',
  'deletePart',
  'deleteDay',
  'cleanupEmptyDay'
]) {
  assert(repo.includes(method), `repository missing ${method}`);
}

const db = readFileSync(join(root, 'entry/src/main/ets/db/WorkoutDatabase.ets'), 'utf8');
for (const table of ['workout_days', 'day_parts', 'day_exercises', 'workout_sets']) {
  assert(db.includes(table), `schema missing table ${table}`);
}

const pages = readFileSync(join(root, 'entry/src/main/resources/base/profile/main_pages.json'), 'utf8');
assert(pages.includes('pages/CalendarPage'), 'main_pages should register CalendarPage');
assert(pages.includes('pages/DayDetailPage'), 'main_pages should register DayDetailPage');

const app = readFileSync(join(root, 'AppScope/app.json5'), 'utf8');
assert(app.includes('com.fitloger.app'), 'bundleName should be com.fitloger.app');
assert(app.includes('训练日志') === false, 'app.json5 uses string resource for label');

const strings = readFileSync(join(root, 'AppScope/resources/base/element/string.json'), 'utf8');
assert(strings.includes('训练日志'), 'app display name should be 训练日志');

const dayPage = readFileSync(join(root, 'entry/src/main/ets/pages/DayDetailPage.ets'), 'utf8');
assert(!dayPage.includes('showPartSheet'), 'DayDetailPage should not reference removed showPartSheet');
assert(dayPage.includes('$$this.showSheet'), 'DayDetailPage should two-way bind the sheet');

function observedItemKey(id, epoch) {
  return `${id}#${epoch}`;
}

const oldPart = { id: 7, exercises: [] };
const newPart = { id: 7, exercises: [{ id: 1 }] };
assert(`${oldPart.id}` === `${newPart.id}`, 'id-only ForEach key stays the same after nested add');
assert(
  observedItemKey(oldPart.id, 1) !== observedItemKey(newPart.id, 2),
  'epoch in key must change after reload so ObjectLink children remount'
);
assert(dayPage.includes('@State viewEpoch'), 'DayDetailPage must keep viewEpoch to remount ObjectLink children');
assert(dayPage.includes('this.viewEpoch++'), 'reload must bump viewEpoch after replacing day data');
assert(
  dayPage.includes('`${part.id}#${this.viewEpoch}`'),
  'parts ForEach key must include viewEpoch, otherwise nested add/delete stays invisible'
);

console.log(`project files + catalog: ${ids.length} exercises, all checks passed`);
