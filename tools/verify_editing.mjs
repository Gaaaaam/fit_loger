import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

// Execute the application's actual pure ArkTS logic, not its JS mirror.
const source = readFileSync(new URL('../entry/src/main/ets/common/WorkoutLogic.ets', import.meta.url), 'utf8');
const logic = await import(`data:text/javascript;base64,${Buffer.from(stripTypeScriptTypes(source)).toString('base64')}`);
let status = 'planned';
let completedAt = 0;
for (const text of ['1', '12', '12.', '12.5', '', '8', '10']) {
  const change = logic.statusAfterEdit(status, 123456);
  status = change.status;
  if (change.completedAt !== null) completedAt = change.completedAt;
  assert.equal(status, 'planned', `typing ${text} must not complete a set`);
  assert.equal(completedAt, 0);
}
const checked = logic.toggleSetStatus(status, 123456);
assert.equal(checked.status, 'done');
assert.equal(checked.completedAt, 123456);
const edited = logic.statusAfterEdit(checked.status, 234567);
assert.equal(edited.status, 'done');
assert.equal(edited.completedAt, null, 'editing must preserve the original completion time');
assert.equal(logic.toggleSetStatus(edited.status, 345678).status, 'planned');
console.log('Actual ArkTS editing state regression checks passed.');

// Exercise the real SetRow handlers with persistence and scheduling boundaries stubbed.
// ArkUI rendering/focus must additionally be checked on a HarmonyOS device.
const rowSource = readFileSync(new URL('../entry/src/main/ets/components/SetRow.ets', import.meta.url), 'utf8');
const handlers = rowSource.slice(rowSource.indexOf('export struct SetRow'), rowSource.indexOf('  @Builder'))
  .replace('export struct SetRow', 'class SetRow')
  .replace(/@(ObjectLink|Prop|State)\s+/g, '') + '\n}\n globalThis.RowHandlers = SetRow;';
const writes = [];
const sandbox = {
  ...logic,
  WorkoutRepository: { writeSet: async (item) => { writes.push({ ...item }); return ''; } },
  setTimeout: () => 1,
  clearTimeout: () => {},
  hilog: { error: () => {} }
};
runInNewContext(stripTypeScriptTypes(handlers), sandbox);
const row = new sandbox.RowHandlers();
row.setItem = { id: 1, status: 'planned', completedAt: 0, weightText: '', repsText: '', inputError: '' };
let completedEvents = 0;
let statusEvents = 0;
row.onBecameDone = () => completedEvents++;
row.onStatusChanged = () => statusEvents++;
for (const value of ['1', '12', '12.5']) {
  row.setItem.weightText = value;
  row.markEdited();
  row.flushSave();
  await Promise.resolve();
}
assert.equal(statusEvents, 0, 'typing must not refresh the parent list');
assert.equal(completedEvents, 0, 'autosave must not emit completion/PR events');
assert(writes.every((item) => item.status === 'planned' && item.completedAt === 0));
row.setItem.repsText = '10';
row.toggleDone();
await Promise.resolve();
assert.equal(row.setItem.status, 'done');
assert.equal(completedEvents, 1);
const completionTime = row.setItem.completedAt;
row.setItem.weightText = '15';
row.markEdited();
row.flushSave();
await Promise.resolve();
assert.equal(row.setItem.completedAt, completionTime);
assert.equal(completedEvents, 1);
row.toggleDone();
await Promise.resolve();
assert.equal(row.setItem.status, 'planned');
assert.equal(row.setItem.completedAt, 0);
row.setItem.weightText = '.';
row.toggleDone();
assert.equal(row.setItem.status, 'planned', 'invalid input must not mark a set done');
console.log('Actual SetRow autosave and manual completion checks passed.');
