import { CardioMetrics } from '../model/CardioModels';
import { validateCardioMetrics } from './CardioLogic';

export class CardioDraft {
  minutes: string = '';
  seconds: string = '';
  distance: string = '';
  speedKmh: string = '';
  inclinePct: string = '';
  level: string = '';
  steps: string = '';
  floors: string = '';
  cadencePerMin: string = '';
  avgPowerW: string = '';
  avgHeartRateBpm: string = '';
  energyKcal: string = '';
}

export interface CardioInputField {
  key: string;
  label: string;
}

export class CardioParseResult {
  ok: boolean = false;
  error: string = '';
  metrics: CardioMetrics = new CardioMetrics();
}

function valueText(value: number | null): string {
  return value === null ? '' : `${value}`;
}

export function cardioDraftOf(metrics: CardioMetrics, exerciseId: string): CardioDraft {
  const draft: CardioDraft = new CardioDraft();
  if (metrics.durationSec !== null) {
    draft.minutes = `${Math.floor(metrics.durationSec / 60)}`;
    draft.seconds = `${metrics.durationSec % 60}`;
  }
  draft.distance = metrics.distanceM === null ? '' : valueText(exerciseId === 'cardio_rower' ?
    metrics.distanceM : Number((metrics.distanceM / 1000).toFixed(6)));
  draft.speedKmh = valueText(metrics.speedKmh);
  draft.inclinePct = valueText(metrics.inclinePct);
  draft.level = valueText(metrics.level);
  draft.steps = valueText(metrics.steps);
  draft.floors = valueText(metrics.floors);
  draft.cadencePerMin = valueText(metrics.cadencePerMin);
  draft.avgPowerW = valueText(metrics.avgPowerW);
  draft.avgHeartRateBpm = valueText(metrics.avgHeartRateBpm);
  draft.energyKcal = valueText(metrics.energyKcal);
  return draft;
}

export function cardioFieldText(draft: CardioDraft, key: string): string {
  switch (key) {
    case 'minutes': return draft.minutes;
    case 'seconds': return draft.seconds;
    case 'distance': return draft.distance;
    case 'speedKmh': return draft.speedKmh;
    case 'inclinePct': return draft.inclinePct;
    case 'level': return draft.level;
    case 'steps': return draft.steps;
    case 'floors': return draft.floors;
    case 'cadencePerMin': return draft.cadencePerMin;
    case 'avgPowerW': return draft.avgPowerW;
    case 'avgHeartRateBpm': return draft.avgHeartRateBpm;
    case 'energyKcal': return draft.energyKcal;
    default: return '';
  }
}

export function changeCardioField(draft: CardioDraft, key: string, text: string): void {
  switch (key) {
    case 'minutes': draft.minutes = text; break;
    case 'seconds': draft.seconds = text; break;
    case 'distance': draft.distance = text; break;
    case 'speedKmh': draft.speedKmh = text; break;
    case 'inclinePct': draft.inclinePct = text; break;
    case 'level': draft.level = text; break;
    case 'steps': draft.steps = text; break;
    case 'floors': draft.floors = text; break;
    case 'cadencePerMin': draft.cadencePerMin = text; break;
    case 'avgPowerW': draft.avgPowerW = text; break;
    case 'avgHeartRateBpm': draft.avgHeartRateBpm = text; break;
    case 'energyKcal': draft.energyKcal = text; break;
    default: break;
  }
}

export function cardioDetailFields(exerciseId: string): CardioInputField[] {
  const fields: CardioInputField[] = [];
  if (exerciseId === 'cardio_treadmill') {
    fields.push({ key: 'speedKmh', label: '面板速度 km/h' }, { key: 'inclinePct', label: '坡度 %' });
  } else if (exerciseId === 'cardio_stair_climber') {
    fields.push({ key: 'steps', label: '台阶数 步' }, { key: 'floors', label: '楼层数 层' }, { key: 'level', label: '档位' });
  } else if (exerciseId === 'cardio_elliptical') {
    fields.push({ key: 'level', label: '阻力档位' }, { key: 'cadencePerMin', label: '步频 步/分' });
  } else if (exerciseId === 'cardio_stationary_bike') {
    fields.push({ key: 'level', label: '阻力档位' }, { key: 'cadencePerMin', label: '踏频 rpm' },
      { key: 'avgPowerW', label: '平均功率 W' });
  } else if (exerciseId === 'cardio_rower') {
    fields.push({ key: 'cadencePerMin', label: '桨频 次/分' }, { key: 'avgPowerW', label: '平均功率 W' });
  }
  fields.push({ key: 'avgHeartRateBpm', label: '平均心率 bpm' }, { key: 'energyKcal', label: '面板热量 kcal' });
  return fields;
}

function decimal(text: string): number | null {
  const trimmed: string = text.trim();
  if (trimmed.length === 0) {
    return null;
  }
  return /^-?(?:\d+(?:\.\d*)?|\.\d+)$/.test(trimmed) ? Number(trimmed) : Number.NaN;
}

export function parseCardioDraft(draft: CardioDraft, exerciseId: string, requireDuration: boolean): CardioParseResult {
  const result: CardioParseResult = new CardioParseResult();
  const minutes: number | null = decimal(draft.minutes);
  const seconds: number | null = decimal(draft.seconds);
  if ((minutes !== null && (!Number.isSafeInteger(minutes) || minutes < 0)) ||
    (seconds !== null && (!Number.isInteger(seconds) || seconds < 0 || seconds > 59))) {
    result.error = '分钟请输入非负整数，秒数请输入 0–59';
    return result;
  }
  const metrics: CardioMetrics = new CardioMetrics();
  metrics.durationSec = minutes === null && seconds === null ? null : (minutes === null ? 0 : minutes) * 60 +
    (seconds === null ? 0 : seconds);
  const distance: number | null = decimal(draft.distance);
  metrics.distanceM = distance === null ? null : distance * (exerciseId === 'cardio_rower' ? 1 : 1000);
  metrics.speedKmh = decimal(draft.speedKmh);
  metrics.inclinePct = decimal(draft.inclinePct);
  metrics.level = decimal(draft.level);
  metrics.steps = decimal(draft.steps);
  metrics.floors = decimal(draft.floors);
  metrics.cadencePerMin = decimal(draft.cadencePerMin);
  metrics.avgPowerW = decimal(draft.avgPowerW);
  metrics.avgHeartRateBpm = decimal(draft.avgHeartRateBpm);
  metrics.energyKcal = decimal(draft.energyKcal);
  result.error = validateCardioMetrics(metrics, requireDuration);
  result.metrics = metrics;
  result.ok = result.error.length === 0;
  return result;
}
