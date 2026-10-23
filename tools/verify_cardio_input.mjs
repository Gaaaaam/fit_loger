import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { load } from './cardio_test_utils.mjs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

assert(existsSync(new URL('../entry/src/main/ets/common/CardioInputLogic.ets', import.meta.url)), 'cardio input parsing is implemented');
const model = load('model/CardioModels.ets', ['CardioMetrics']);
const logic = load('common/CardioLogic.ets', ['validateCardioMetrics'], model);
const input = load('common/CardioInputLogic.ets', ['CardioDraft', 'cardioDraftOf', 'parseCardioDraft', 'cardioDetailFields', 'cardioFieldText', 'changeCardioField'], { ...model, ...logic });
const d = new input.CardioDraft();
assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', false).ok, true);
assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', true).ok, false);
d.minutes = '30'; d.seconds = '05'; d.distance = '2.75'; d.inclinePct = '-1.5'; d.speedKmh = '6';
let parsed = input.parseCardioDraft(d, 'cardio_treadmill', true);
assert.equal(parsed.ok, true); assert.equal(parsed.metrics.durationSec, 1805); assert.equal(parsed.metrics.distanceM, 2750);
assert.equal(parsed.metrics.inclinePct, -1.5); assert.equal(parsed.metrics.speedKmh, 6);
const restored = input.cardioDraftOf(parsed.metrics, 'cardio_treadmill');
assert.equal(restored.minutes, '30'); assert.equal(restored.seconds, '5'); assert.equal(restored.distance, '2.75');
d.seconds = '60'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', false).ok, false);
d.seconds = '1.5'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', false).ok, false);
d.seconds = ''; d.minutes = '-1'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', false).ok, false);
d.minutes = '1'; d.distance = '1e3'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', false).ok, false);
d.distance = '0'; d.level = '0'; parsed = input.parseCardioDraft(d, 'cardio_treadmill', true);
assert.equal(parsed.metrics.distanceM, 0); assert.equal(parsed.metrics.level, 0); assert.equal(parsed.metrics.energyKcal, null);
d.distance = '500'; parsed = input.parseCardioDraft(d, 'cardio_rower', true); assert.equal(parsed.metrics.distanceM, 500);
d.steps = '1.5'; assert.equal(input.parseCardioDraft(d, 'cardio_stair_climber', false).ok, false);
d.steps = ''; d.avgHeartRateBpm = '0'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', true).ok, false);
d.avgHeartRateBpm = 'NaN'; assert.equal(input.parseCardioDraft(d, 'cardio_treadmill', true).ok, false);
const keys = id => Array.from(input.cardioDetailFields(id), x => x.key);
assert.deepEqual(keys('cardio_treadmill'), ['speedKmh','inclinePct','avgHeartRateBpm','energyKcal']);
assert.deepEqual(keys('cardio_stair_climber'), ['steps','floors','level','avgHeartRateBpm','energyKcal']);
assert.deepEqual(keys('cardio_elliptical'), ['level','cadencePerMin','avgHeartRateBpm','energyKcal']);
assert.deepEqual(keys('cardio_stationary_bike'), ['level','cadencePerMin','avgPowerW','avgHeartRateBpm','energyKcal']);
assert.deepEqual(keys('cardio_rower'), ['cadencePerMin','avgPowerW','avgHeartRateBpm','energyKcal']);
input.changeCardioField(d, 'level', '2.5'); assert.equal(input.cardioFieldText(d, 'level'), '2.5');
const ui = readFileSync(new URL('../entry/src/main/ets/components/CardioSetRow.ets', import.meta.url), 'utf8');
assert(ui.includes('parseCardioDraft')); assert(ui.includes('writeSet')); assert(ui.includes('aboutToDisappear'));
const card = readFileSync(new URL('../entry/src/main/ets/components/ExerciseCard.ets', import.meta.url), 'utf8');
assert(card.includes('CardioSetRow')); assert(card.includes('添加一段'));
console.log('Cardio input parsing, units, fields, and integration passed.');

// Execute the real component handlers; only persistence/scheduling are replaced.
const handlers = ui.slice(ui.indexOf('export struct CardioSetRow'), ui.indexOf('  @Builder'))
  .replace('export struct CardioSetRow', 'class CardioSetRow')
  .replace(/@(ObjectLink|Prop|State)\s+/g, '') + '\n}\nglobalThis.Row = CardioSetRow;';
let rejectSave = false;
let completeEvents = 0;
let statusEvents = 0;
const writes = [];
const context = { ...input, setTimeout: () => 1, clearTimeout: () => {}, hilog: { error: () => {} },
  WorkoutRepository: { writeSet: async item => {
    if (rejectSave) throw new Error('storage unavailable');
    writes.push(JSON.parse(JSON.stringify(item))); return '';
  } }
};
runInNewContext(stripTypeScriptTypes(handlers), context);
const row = new context.Row();
row.exerciseId = 'cardio_treadmill';
row.setItem = { id: 1, cardio: new model.CardioMetrics(), recordType: 'cardio', exerciseId: row.exerciseId,
  status: 'planned', completedAt: 0, inputError: '', isWarmup: 0, technique: '', rir: -1, rirLegacy: 0, note: '' };
row.onBecameDone = () => completeEvents++;
row.onStatusChanged = () => statusEvents++;
row.aboutToAppear();
await row.toggleDone(); assert.equal(row.setItem.status, 'planned'); assert.equal(writes.length, 0);
row.changeField('minutes', '20'); row.changeField('distance', '2.5');
await row.persist();
assert.equal(writes.at(-1).cardio.durationSec, 1200); assert.equal(writes.at(-1).cardio.distanceM, 2500);
assert.equal(row.setItem.status, 'planned'); assert.equal(completeEvents, 0); assert.equal(statusEvents, 0);
await row.toggleDone(); assert.equal(row.setItem.status, 'done'); assert.equal(completeEvents, 1); assert.equal(statusEvents, 1);
const time = row.setItem.completedAt;
row.changeField('distance', '3'); await row.persist();
assert.equal(row.setItem.completedAt, time); assert.equal(completeEvents, 1);
row.changeField('seconds', '60'); await row.persist(); assert(row.setItem.inputError);
assert.equal(writes.at(-1).cardio.durationSec, 1200, 'invalid drafts do not replace persisted metrics');
row.changeField('seconds', '0'); row.changeField('distance', ''); await row.persist();
assert.equal(writes.at(-1).cardio.distanceM, null, 'clearing an optional metric persists null');
await row.toggleDone(); assert.equal(row.setItem.status, 'planned'); assert.equal(row.setItem.completedAt, 0);
rejectSave = true; await row.toggleDone();
assert.equal(row.setItem.status, 'planned'); assert.equal(row.setItem.completedAt, 0); assert(row.setItem.inputError);
assert.equal(completeEvents, 1, 'failed completion never emits a success callback');
rejectSave = false;
row.setItem.note = '收尾备注'; row.aboutToDisappear(); await Promise.resolve();
assert.equal(writes.at(-1).note, '收尾备注', 'closing flushes pending changes');
const beforeDelete = writes.length; row.deleting = true; row.aboutToDisappear(); await Promise.resolve();
assert.equal(writes.length, beforeDelete, 'deleted segments never flush a stale autosave');
console.log('Actual CardioSetRow autosave, manual completion, failure rollback, and close/delete checks passed.');

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((ok, fail) => { resolve = ok; reject = fail; });
  return { promise, resolve, reject };
}
function pendingRow() {
  const pending = new context.Row();
  pending.exerciseId = 'cardio_treadmill';
  pending.setItem = { id: 2, cardio: new model.CardioMetrics(), recordType: 'cardio', exerciseId: pending.exerciseId,
    status: 'planned', completedAt: 0, inputError: '', isWarmup: 0, technique: '', rir: -1, rirLegacy: 0, note: '' };
  pending.aboutToAppear();
  pending.changeField('minutes', '20');
  return pending;
}

// An older storage response must never replace validation for a newer draft.
for (const outcome of ['success', 'returned error', 'rejection']) {
  const pending = pendingRow();
  const gate = deferred();
  context.WorkoutRepository.writeSet = () => gate.promise;
  const saving = pending.persist();
  pending.changeField('seconds', '60');
  const invalidError = pending.setItem.inputError;
  assert(invalidError.length > 0);
  if (outcome === 'rejection') gate.reject(new Error('storage unavailable'));
  else gate.resolve(outcome === 'success' ? '' : '保存失败');
  assert.equal(await saving, outcome === 'success');
  assert.equal(pending.draft.seconds, '60');
  assert.equal(pending.setItem.inputError, invalidError, `${outcome} must preserve the newer invalid draft error`);
}

// A failed obsolete save must not poison a newer valid edit or its successful save.
for (const saveNewer of [false, true]) {
  for (const outcome of ['returned error', 'rejection']) {
    const pending = pendingRow();
    const gate = deferred();
    context.WorkoutRepository.writeSet = () => gate.promise;
    const saving = pending.persist();
    pending.changeField('speedKmh', '7');
    if (saveNewer) {
      context.WorkoutRepository.writeSet = async () => '';
      assert.equal(await pending.persist(), true);
    }
    if (outcome === 'rejection') gate.reject(new Error('storage unavailable'));
    else gate.resolve('保存失败');
    assert.equal(await saving, false);
    assert.equal(pending.setItem.cardio.speedKmh, 7);
    assert.equal(pending.setItem.inputError, '', 'an obsolete failure must leave the newer valid state intact');
  }
}

// With no intervening edit, the latest attempt owns storage error state.
const sameDraft = pendingRow();
const oldGate = deferred();
context.WorkoutRepository.writeSet = () => oldGate.promise;
const oldSave = sameDraft.persist();
context.WorkoutRepository.writeSet = async () => '';
await sameDraft.persist();
oldGate.reject(new Error('old failure'));
await oldSave;
assert.equal(sameDraft.setItem.inputError, '', 'a completed newer retry supersedes an older failure');
context.WorkoutRepository.writeSet = async () => { throw new Error('latest failure'); };
assert.equal(await sameDraft.persist(), false);
assert(sameDraft.setItem.inputError.length > 0, 'the current unresolved storage failure remains visible');
const failure = sameDraft.setItem.inputError;
const staleSuccessGate = deferred();
context.WorkoutRepository.writeSet = () => staleSuccessGate.promise;
const staleSuccess = sameDraft.persist();
context.WorkoutRepository.writeSet = async () => { throw new Error('newer failure'); };
await sameDraft.persist();
staleSuccessGate.resolve('');
await staleSuccess;
assert.equal(sameDraft.setItem.inputError, failure, 'an older success cannot clear the latest storage failure');

for (const succeeds of [true, false]) {
  const pending = pendingRow();
  const gate = deferred();
  let doneEvents = 0;
  let changedEvents = 0;
  pending.onBecameDone = () => doneEvents++;
  pending.onStatusChanged = () => changedEvents++;
  context.WorkoutRepository.writeSet = () => gate.promise;
  const completing = pending.toggleDone();
  assert.equal(pending.completing, true);
  pending.changeField('seconds', '60');
  const invalidError = pending.setItem.inputError;
  if (succeeds) gate.resolve('');
  else gate.reject(new Error('completion failed'));
  await completing;
  assert.equal(pending.completing, false);
  assert.equal(pending.setItem.status, succeeds ? 'done' : 'planned');
  assert.equal(pending.setItem.completedAt > 0, succeeds);
  assert.equal(pending.setItem.inputError, invalidError);
  assert.equal(doneEvents, succeeds ? 1 : 0);
  assert.equal(changedEvents, succeeds ? 1 : 0);
}
console.log('Actual CardioSetRow delayed save/edit ordering, current errors, and in-flight completion checks passed.');
