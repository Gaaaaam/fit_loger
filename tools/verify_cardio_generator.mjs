import { strict as assert } from 'node:assert';
import { mkdtempSync, mkdirSync, copyFileSync, writeFileSync, readFileSync, existsSync, readdirSync, renameSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

// Execute the actual generator in an isolated fixture to prove it cannot overwrite existing art.
const root = mkdtempSync(join(tmpdir(), 'fitlog-cardio-generator-'));
const generator = join(root, 'tools/exercises');
const model = join(root, 'entry/src/main/ets/model');
const media = join(root, 'entry/src/main/resources/base/media');
for (const path of [generator, model, media]) mkdirSync(path, { recursive: true });
for (const file of ['generate.mjs', 'data.mjs', 'svg.mjs']) copyFileSync(new URL(`./exercises/${file}`, import.meta.url), join(generator, file));
writeFileSync(join(model, 'exerciseArtwork.ets'), 'resolver sentinel');
writeFileSync(join(media, 'ex_chest_bb_bench_card.svg'), 'svg sentinel');
writeFileSync(join(media, 'ex_unrelated_card.svg'), 'unrelated sentinel');
const run = args => {
  const result = spawnSync(process.execPath, [join(generator, 'generate.mjs'), ...args], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
};
run(['--catalog-only']);
assert.equal(readdirSync(media).length, 2);
assert.equal(readFileSync(join(model, 'exerciseArtwork.ets'), 'utf8'), 'resolver sentinel');
const data = JSON.parse(readFileSync(join(generator, 'curated.json'), 'utf8'));
assert.equal(data.count, 125); assert.equal(data.exercises.filter(x => x.recordType === 'cardio').length, 5);
run([]);
assert.equal(readFileSync(join(model, 'exerciseArtwork.ets'), 'utf8'), 'resolver sentinel');
assert.equal(readFileSync(join(media, 'ex_chest_bb_bench_card.svg'), 'utf8'), 'svg sentinel');
assert.equal(readFileSync(join(media, 'ex_unrelated_card.svg'), 'utf8'), 'unrelated sentinel');
for (const item of data.exercises.filter(x => x.recordType === 'cardio')) {
  assert(!existsSync(join(media, `ex_${item.id}_card.svg`)), 'cardio requires guidance, never a legacy SVG');
  assert(item.pose.guidance);
}
renameSync(join(model, 'exerciseArtwork.ets'), join(model, 'exerciseArtwork.saved.ets'));
run([]);
assert(!readFileSync(join(model, 'exerciseArtwork.ets'), 'utf8').includes('ex_cardio_treadmill_card'), 'a fresh legacy resolver must never reference nonexistent cardio SVGs');
console.log('Actual catalog-only and normal generators preserve resolver/SVGs and skip cardio legacy SVGs.');
