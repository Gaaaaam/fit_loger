import { CardioMetrics } from '../model/CardioModels';

export function validateCardioMetrics(metrics: CardioMetrics, requireDuration: boolean): string {
  const values: Array<number | null> = [metrics.durationSec, metrics.distanceM, metrics.speedKmh,
    metrics.inclinePct, metrics.level, metrics.steps, metrics.floors, metrics.cadencePerMin,
    metrics.avgPowerW, metrics.avgHeartRateBpm, metrics.energyKcal];
  const labels: string[] = ['时长', '距离', '速度', '坡度', '档位', '步数', '楼层', '踏频/划频', '平均功率', '平均心率', '能量'];
  for (let i = 0; i < values.length; i++) {
    const value: number | null = values[i];
    if (value === null) {
      continue;
    }
    if (!Number.isFinite(value)) {
      return `${labels[i]}请输入有效数字`;
    }
    if (i !== 3 && value < 0) {
      return `${labels[i]}不能为负数`;
    }
  }
  if (metrics.durationSec !== null && !Number.isInteger(metrics.durationSec)) {
    return '时长请输入整数秒';
  }
  if (metrics.steps !== null && !Number.isInteger(metrics.steps)) {
    return '步数请输入整数';
  }
  if (metrics.avgHeartRateBpm !== null && metrics.avgHeartRateBpm <= 0) {
    return '平均心率必须大于 0';
  }
  if (requireDuration && (metrics.durationSec === null || metrics.durationSec <= 0)) {
    return '完成训练段前请输入大于 0 的时长';
  }
  return '';
}

export function copyCardioMetrics(metrics: CardioMetrics): CardioMetrics {
  const copy: CardioMetrics = new CardioMetrics();
  copy.durationSec = metrics.durationSec;
  copy.distanceM = metrics.distanceM;
  copy.speedKmh = metrics.speedKmh;
  copy.inclinePct = metrics.inclinePct;
  copy.level = metrics.level;
  copy.steps = metrics.steps;
  copy.floors = metrics.floors;
  copy.cadencePerMin = metrics.cadencePerMin;
  copy.avgPowerW = metrics.avgPowerW;
  copy.avgHeartRateBpm = metrics.avgHeartRateBpm;
  copy.energyKcal = metrics.energyKcal;
  return copy;
}

export function inheritCardioSettings(metrics: CardioMetrics): CardioMetrics {
  const copy: CardioMetrics = new CardioMetrics();
  copy.speedKmh = metrics.speedKmh;
  copy.inclinePct = metrics.inclinePct;
  copy.level = metrics.level;
  return copy;
}

export function cardioPlanMetrics(metrics: CardioMetrics): CardioMetrics {
  const copy: CardioMetrics = inheritCardioSettings(metrics);
  copy.durationSec = metrics.durationSec;
  copy.distanceM = metrics.distanceM;
  return copy;
}

export function averageCardioSpeedKmh(metrics: CardioMetrics): number | null {
  if (metrics.durationSec === null || metrics.distanceM === null ||
    !Number.isFinite(metrics.durationSec) || !Number.isFinite(metrics.distanceM) ||
    metrics.durationSec <= 0 || metrics.distanceM <= 0) {
    return null;
  }
  return metrics.distanceM / metrics.durationSec * 3.6;
}

export function cardioPaceSecPerKm(metrics: CardioMetrics): number | null {
  if (averageCardioSpeedKmh(metrics) === null || metrics.durationSec === null || metrics.distanceM === null) {
    return null;
  }
  return metrics.durationSec / metrics.distanceM * 1000;
}

export function rowerSplitSecPer500m(metrics: CardioMetrics): number | null {
  const pace: number | null = cardioPaceSecPerKm(metrics);
  return pace === null ? null : pace / 2;
}

export function formatCardioDuration(seconds: number): string {
  const total: number = Math.max(0, Math.round(seconds));
  const mins: number = Math.floor(total / 60);
  const secText: string = `${total % 60}`.padStart(2, '0');
  if (mins < 60) {
    return `${mins}:${secText}`;
  }
  return `${Math.floor(mins / 60)}:${`${mins % 60}`.padStart(2, '0')}:${secText}`;
}

export function formatCardioSummary(metrics: CardioMetrics, exerciseId: string): string {
  const parts: string[] = [];
  if (metrics.durationSec !== null) {
    parts.push(formatCardioDuration(metrics.durationSec));
  }
  if (exerciseId === 'cardio_stair_climber') {
    if (metrics.steps !== null) {
      parts.push(`${metrics.steps} 步`);
    }
    if (metrics.floors !== null) {
      parts.push(`${metrics.floors} 层`);
    }
  } else if (metrics.distanceM !== null) {
    if (exerciseId === 'cardio_rower') {
      parts.push(`${metrics.distanceM} m`);
    } else {
      parts.push(`${Number((metrics.distanceM / 1000).toFixed(3))} km`);
    }
  }
  return parts.join(' · ');
}
