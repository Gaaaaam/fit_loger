export const GUIDE_STEPS = ['intro', 'weekGoal', 'lifts', 'weight', 'close'];

export const TERM_IDS = ['e1rm', 'rir', 'work_set', 'insufficient'];

const TERMS = {
  e1rm: {
    id: 'e1rm',
    title: 'e1RM',
    body: '估算的一次最大重量。用接近力竭的正式组推算「如果只做一下，大概能多重」，不是去健身房试极限。'
  },
  rir: {
    id: 'rir',
    title: 'RIR',
    body: '做完这组还能再做几下。0 是力竭，1 是还能再做一下。'
  },
  work_set: {
    id: 'work_set',
    title: '正式组',
    body: '计入训练量的组，不含热身。'
  },
  insufficient: {
    id: 'insufficient',
    title: '数据不足',
    body: '复合动作至少要有 2 次「RIR ≤ 1 且次数 ≤ 8」的正式组，才能画出比较稳定的 e1RM。'
  }
};

export function nextGuideStep(step) {
  if (step === 'intro') {
    return 'weekGoal';
  }
  if (step === 'weekGoal') {
    return 'lifts';
  }
  if (step === 'lifts') {
    return 'weight';
  }
  if (step === 'weight') {
    return 'close';
  }
  return '';
}

export function closeCtaKind(hasAnyWorkSet) {
  return hasAnyWorkSet ? 'done' : 'log_first';
}

export function guideHighlight(step) {
  if (step === 'weekGoal' || step === 'lifts' || step === 'weight') {
    return step;
  }
  return '';
}

export function findTerm(id) {
  const term = TERMS[id];
  if (term === undefined) {
    return { id: '', title: '', body: '' };
  }
  return {
    id: term.id,
    title: term.title,
    body: term.body
  };
}

export function allTermIds() {
  return TERM_IDS.slice();
}

export function guideStepCopy(step, hasAnyWorkSet) {
  const copy = {
    step: step,
    title: '',
    body: '',
    highlight: guideHighlight(step),
    primaryLabel: '下一步',
    secondaryLabel: '跳过',
    primaryCta: 'next'
  };
  if (step === 'intro') {
    copy.title = '趋势用来看三件事';
    copy.body = '本周有没有练够、关注的动作力量有没有进步、体重怎么变。';
    return copy;
  }
  if (step === 'weekGoal') {
    copy.title = '本周目标';
    copy.body = '先设每周练几天、某个部位练几组。不设也能记训练，只是这里没法告诉你本周够不够。';
    return copy;
  }
  if (step === 'lifts') {
    copy.title = '关注动作';
    copy.body = '钉住几个你在意的动作，看力量有没有涨。没钉的话，会先自动展示练得最多的动作。\n\n' +
      '复合动作看 e1RM：估算「如果只做一下，大概能多重」。只用接近力竭的正式组（不是热身；RIR ≤ 1，次数不太高）。数据不够会写「数据不足」，不是没进步。孤立动作看最重重量，自重动作看最多次数。';
    return copy;
  }
  if (step === 'weight') {
    copy.title = '身体趋势';
    copy.body = '这里看体重变化。记得越勤，越容易看出涨还是掉。';
    return copy;
  }
  if (step === 'close') {
    copy.primaryCta = closeCtaKind(hasAnyWorkSet);
    if (hasAnyWorkSet) {
      copy.title = '可以开始看了';
      copy.body = '想钉动作或设每周目标，点卡片上的设置。';
      copy.primaryLabel = '开始看趋势';
      copy.secondaryLabel = '';
    } else {
      copy.title = '先去记第一组';
      copy.body = '现在还没有可比较的数据。先去记第一组，练过几次再回来看。';
      copy.primaryLabel = '去记第一组';
      copy.secondaryLabel = '稍后再说';
    }
    return copy;
  }
  return copy;
}
