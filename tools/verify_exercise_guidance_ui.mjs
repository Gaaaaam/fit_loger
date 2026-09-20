import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';

const read = relative => readFileSync(new URL(`../entry/src/main/ets/${relative}`, import.meta.url), 'utf8');
assert(existsSync(new URL('../entry/src/main/ets/components/ExerciseGuidanceCarousel.ets', import.meta.url)),
  'missing ExerciseGuidanceCarousel.ets: guidance must render one frame per page');
const carousel = read('components/ExerciseGuidanceCarousel.ets');
const info = read('components/ExerciseInfoView.ets');
const sheet = read('components/ExerciseSheet.ets');
const dayDetail = read('pages/DayDetailPage.ets');

assert(carousel.includes('export struct ExerciseGuidanceCarousel'));
assert(carousel.includes('Swiper()'));
assert(carousel.includes('.loop(false)'));
assert(carousel.includes('.indicator('));
assert(carousel.includes('.onChange((index: number)'));
assert(carousel.includes("Text('第 '"));
assert(carousel.includes('.displayCount(1)'), 'each page must contain exactly one frame');
assert(carousel.includes('.objectFit(ImageFit.Contain)'));
assert(!carousel.includes('indicatorStyle'), 'use the supported indicator API');
assert(carousel.includes('.index(this.currentIndex)'), 'reset must also update the visible Swiper page');
assert(/if \(this\.frames\.length > 0\) \{\s*Swiper\(\)/.test(carousel), 'empty frames must not render a Swiper');
assert(/Text\('第 '[\s\S]*Text\(this\.captions\[this\.currentIndex\][\s\S]*\n      }/.test(carousel),
  'step count and caption must stay inside the nonempty branch');
assert(info.includes('ExerciseGuidanceCarousel'));
assert(!info.includes("Text('起始')"));
assert(!info.includes("Text('结束')"));
assert(info.includes("@Prop modelPreference: ExerciseModelPreference = 'auto'"));
assert(info.includes('guidanceFramesOf(this.exerciseId, this.resolvedPart(), this.modelPreference)'));
assert(info.includes('guidanceCaptionsOf(this.exerciseId)'));
for (const label of ['动作步骤', '注意点', '计次口径']) {
  assert(info.indexOf(`Text('${label}')`) > info.indexOf('ExerciseGuidanceCarousel({'), `${label} must remain below images`);
}
assert(sheet.includes('modelPreference'));
assert(sheet.includes('cardImageOf(item.id, item.partKey, this.modelPreference)'));
assert(sheet.includes('modelPreference: this.modelPreference'));
assert(dayDetail.includes('loadExerciseModelPreference'));
assert(dayDetail.includes('modelPreference: this.exerciseModelPreference'));
for (const name of ['ExerciseSheet', 'ExerciseInfoView']) {
  const instances = [...dayDetail.matchAll(new RegExp(`\\b${name}\\(\\{([^}]+)`, 'g'))];
  assert(instances.length > 0);
  for (const instance of instances) {
    assert(instance[1].includes('modelPreference: this.exerciseModelPreference'), `${name} must receive the page preference`);
  }
}
assert(!/loadExerciseModelPreference/.test(sheet + info), 'children must share the page load');
assert.equal((dayDetail.match(/AppSettings\.loadExerciseModelPreference\(/g) || []).length, 1);
assert(dayDetail.includes('this.loadExerciseModelPreference();'), 'page appearance must start the preference load');

// Execute production handlers: missing reset, stale onChange, or a second load must fail.
function handlers(source, name, end, dependencies = {}) {
  const start = source.indexOf(`struct ${name}`);
  const body = source.slice(start, source.indexOf(end, start))
    .replace(`struct ${name}`, `class ${name}`)
    .replace(/@Watch\([^)]*\)\s*/g, '')
    .replace(/@(?:Prop|State)\s*/g, '');
  const context = { ...dependencies };
  runInNewContext(stripTypeScriptTypes(`${body}\n}\nglobalThis.Component = ${name};`), context);
  return new context.Component();
}
const logic = read('common/ExerciseArtworkLogic.ets').replace(/\bexport /g, '');
const logicContext = {};
runInNewContext(stripTypeScriptTypes(logic) + '\nglobalThis.safeIndex = safeArtworkFrameIndex;', logicContext);
const component = handlers(carousel, 'ExerciseGuidanceCarousel', '  build()', {
  safeArtworkFrameIndex: logicContext.safeIndex
});
const watcher = carousel.match(/@Prop\s+@Watch\('([^']+)'\)\s+frames/);
assert(watcher, 'frames changes must invoke a state-reset watcher');
const change = carousel.match(/\.onChange\(\(index: number\) => \{([\s\S]*?)\}\)/);
assert(change, 'Swiper must update through the production handler');
const onChange = new Function('index', change[1]);
const key = carousel.match(/}, \((_?frame): Resource, index: number\) => ([^\n]+)\)/);
assert(key, 'frame rendering must supply a resource-sensitive key');
const frameKey = new Function(key[1], 'index', `return ${key[2]};`);
assert.notEqual(frameKey({ id: 1 }, 0), frameKey({ id: 2 }, 0),
  'changing action or model at the same index must replace the displayed image');
assert.notEqual(frameKey({ id: 1 }, 0), frameKey({ id: 1 }, 1), 'repeated resources still need unique page keys');
component.frames = [1, 2, 3, 4];
component.captions = ['one', 'two', 'three', 'four'];
onChange.call(component, 3);
assert.equal(component.currentIndex, 3);
component.frames = [5, 6];
component.captions = ['start', 'end'];
component[watcher[1]]();
assert.equal(component.currentIndex, 0, '4 to 2 frames must reset to the first page');
assert.equal(component.captions[component.currentIndex], 'start');
onChange.call(component, 3);
assert.equal(component.currentIndex, 0, 'a stale Swiper event must not restore the out-of-range index');
onChange.call(component, 1);
assert.equal(component.currentIndex, 1);
component.frames = [7, 8];
component[watcher[1]]();
assert.equal(component.currentIndex, 0, 'a different action of equal length must also reset');
component.frames = [];
component.captions = [];
component[watcher[1]]();
onChange.call(component, -1);
assert.equal(component.currentIndex, 0, 'empty frames and invalid callbacks must leave safe state');

let loads = 0;
const page = handlers(dayDetail, 'DayDetailPage', '  private hasPlanned()', {
  DayModel: class {}, SetItem: class {}, Scroller: class {},
  AppSettings: { loadExerciseModelPreference: async () => { loads++; return 'female'; } }
});
await Promise.all([page.loadExerciseModelPreference(), page.loadExerciseModelPreference()]);
await page.loadExerciseModelPreference();
assert.equal(loads, 1, 'repeated appearance/loading must only read the preference once per page instance');
assert.equal(page.exerciseModelPreference, 'female');
const failedPage = handlers(dayDetail, 'DayDetailPage', '  private hasPlanned()', {
  DayModel: class {}, SetItem: class {}, Scroller: class {},
  hilog: { warn: () => {} },
  AppSettings: { loadExerciseModelPreference: async () => { throw new Error('preference read failed'); } }
});
await assert.doesNotReject(() => failedPage.loadExerciseModelPreference(), 'page appearance must tolerate failed preference reads');
assert.equal(failedPage.exerciseModelPreference, 'auto', 'failed preference reads must keep the shared default without rejecting');

console.log('Exercise guidance UI passed: single-frame Swiper, 4→2/equal-length/empty resets, stale index guard, one shared preference load.');
