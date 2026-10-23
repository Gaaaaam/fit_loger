import { strict as assert } from 'node:assert';
import { existsSync } from 'node:fs';
import { load } from './cardio_test_utils.mjs';

assert(existsSync(new URL('../entry/src/main/ets/common/CardioLogic.ets', import.meta.url)), 'CardioLogic must exist');
const model = load('model/CardioModels.ets', ['CardioMetrics']);
const logic = load('common/CardioLogic.ets', ['validateCardioMetrics', 'copyCardioMetrics', 'inheritCardioSettings',
  'cardioPlanMetrics', 'formatCardioSummary', 'averageCardioSpeedKmh', 'cardioPaceSecPerKm',
  'rowerSplitSecPer500m', 'formatCardioDuration'], model);
const make = values => Object.assign(new model.CardioMetrics(), values);
assert.equal(Object.keys(make({})).length, 11);
assert.equal(logic.validateCardioMetrics(make({}), false), '');
assert(logic.validateCardioMetrics(make({}), true));
assert(logic.validateCardioMetrics(make({ durationSec: 0 }), true));
for (const key of Object.keys(make({}))) {
  assert(logic.validateCardioMetrics(make({ [key]: Infinity }), false), key);
  assert(logic.validateCardioMetrics(make({ [key]: NaN }), false), key);
  if (key !== 'inclinePct') assert(logic.validateCardioMetrics(make({ [key]: -1 }), false), key);
}
assert.equal(logic.validateCardioMetrics(make({ durationSec: 61, distanceM: 0, speedKmh: 0, inclinePct: -3, level: 0, steps: 0, floors: 0 }), true), '');
assert(logic.validateCardioMetrics(make({ steps: 1.5 }), false));
assert(logic.validateCardioMetrics(make({ durationSec: 1.5 }), false));
assert(logic.validateCardioMetrics(make({ avgHeartRateBpm: 0 }), false));
const full = make({ durationSec: 600, distanceM: 2000, speedKmh: 9, inclinePct: 0, level: 0,
  steps: 100, floors: 3, cadencePerMin: 25, avgPowerW: 200, avgHeartRateBpm: 140, energyKcal: 0 });
assert.deepEqual({ ...logic.copyCardioMetrics(full) }, { ...full });
const inherited = logic.inheritCardioSettings(full);
assert.equal(inherited.speedKmh, 9); assert.equal(inherited.inclinePct, 0); assert.equal(inherited.level, 0);
for (const key of Object.keys(full).filter(key => !['speedKmh', 'inclinePct', 'level'].includes(key))) assert.equal(inherited[key], null, key);
const plan = logic.cardioPlanMetrics(full);
for (const key of ['durationSec', 'distanceM', 'speedKmh', 'inclinePct', 'level']) assert.equal(plan[key], full[key], key);
for (const key of ['steps', 'floors', 'cadencePerMin', 'avgPowerW', 'avgHeartRateBpm', 'energyKcal']) assert.equal(plan[key], null, key);
assert.equal(logic.averageCardioSpeedKmh(full), 12);
assert.equal(logic.cardioPaceSecPerKm(full), 300);
assert.equal(logic.rowerSplitSecPer500m(full), 150);
for (const values of [{}, { durationSec: 0, distanceM: 10 }, { durationSec: 10, distanceM: 0 }]) {
  for (const fn of ['averageCardioSpeedKmh', 'cardioPaceSecPerKm', 'rowerSplitSecPer500m']) assert.equal(logic[fn](make(values)), null);
}
assert.equal(logic.formatCardioDuration(3661), '1:01:01');
assert.match(logic.formatCardioSummary(full, 'cardio_treadmill'), /10:00.*2 km/);
assert.match(logic.formatCardioSummary(full, 'cardio_rower'), /2000 m/);
assert.match(logic.formatCardioSummary(full, 'cardio_stair_climber'), /100 步/);
assert(!logic.formatCardioSummary(full, 'cardio_stair_climber').includes('km'));
console.log('Actual ArkTS cardio validation, zero/null, inheritance, plan and derived metrics passed.');
