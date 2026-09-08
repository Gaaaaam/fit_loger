import { strict as assert } from 'assert';
import {
  GUIDE_STEPS,
  TERM_IDS,
  nextGuideStep,
  closeCtaKind,
  guideHighlight,
  findTerm,
  allTermIds,
  guideStepCopy
} from './trend_guide.mjs';

assert.deepEqual(GUIDE_STEPS, ['intro', 'weekGoal', 'lifts', 'weight', 'close']);
assert.equal(nextGuideStep('intro'), 'weekGoal');
assert.equal(nextGuideStep('weekGoal'), 'lifts');
assert.equal(nextGuideStep('lifts'), 'weight');
assert.equal(nextGuideStep('weight'), 'close');
assert.equal(nextGuideStep('close'), '', 'next on close finishes the guide');
assert.equal(nextGuideStep('unknown'), '');

let step = 'intro';
const walked = [step];
while (step.length > 0) {
  step = nextGuideStep(step);
  if (step.length > 0) {
    walked.push(step);
  }
}
assert.deepEqual(walked, GUIDE_STEPS);

assert.equal(closeCtaKind(false), 'log_first');
assert.equal(closeCtaKind(true), 'done');

assert.equal(guideHighlight('intro'), '');
assert.equal(guideHighlight('weekGoal'), 'weekGoal');
assert.equal(guideHighlight('lifts'), 'lifts');
assert.equal(guideHighlight('weight'), 'weight');
assert.equal(guideHighlight('close'), '');

const emptyClose = guideStepCopy('close', false);
assert.equal(emptyClose.primaryCta, 'log_first');
assert.equal(emptyClose.primaryLabel, '去记第一组');
assert.equal(emptyClose.secondaryLabel, '稍后再说');
assert.ok(emptyClose.body.indexOf('没有可比较') >= 0);

const filledClose = guideStepCopy('close', true);
assert.equal(filledClose.primaryCta, 'done');
assert.equal(filledClose.primaryLabel, '开始看趋势');
assert.equal(filledClose.secondaryLabel, '');

const intro = guideStepCopy('intro', false);
assert.equal(intro.primaryCta, 'next');
assert.equal(intro.primaryLabel, '下一步');
assert.equal(intro.secondaryLabel, '跳过');
assert.ok(intro.body.indexOf('本周') >= 0);

const lifts = guideStepCopy('lifts', false);
assert.ok(lifts.body.indexOf('e1RM') >= 0);
assert.ok(lifts.body.indexOf('RIR') >= 0);
assert.ok(lifts.body.indexOf('正式组') >= 0);
assert.ok(lifts.body.indexOf('数据不足') >= 0);

assert.deepEqual(allTermIds(), TERM_IDS);
for (let i = 0; i < TERM_IDS.length; i++) {
  const term = findTerm(TERM_IDS[i]);
  assert.equal(term.id, TERM_IDS[i]);
  assert.ok(term.title.length > 0, `${TERM_IDS[i]} needs a title`);
  assert.ok(term.body.length > 0, `${TERM_IDS[i]} needs a body`);
}

assert.equal(findTerm('missing').id, '');
assert.equal(findTerm('e1rm').title, 'e1RM');
assert.ok(findTerm('insufficient').body.indexOf('RIR') >= 0);

console.log('trend guide checks passed');
