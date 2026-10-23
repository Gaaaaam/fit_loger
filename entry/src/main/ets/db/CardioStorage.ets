import { relationalStore } from '@kit.ArkData';
import { CardioMetrics } from '../model/CardioModels';

export const CARDIO_COLUMNS: string[] = ['duration_sec', 'distance_m', 'speed_kmh', 'incline_pct', 'level',
  'steps', 'floors', 'cadence_per_min', 'avg_power_w', 'avg_heart_rate_bpm', 'energy_kcal'];

export const CARDIO_SELECT: string = 's.duration_sec, s.distance_m, s.speed_kmh, s.incline_pct, s.level, ' +
  's.steps, s.floors, s.cadence_per_min, s.avg_power_w, s.avg_heart_rate_bpm, s.energy_kcal';

export function cardioValues(metrics: CardioMetrics): relationalStore.ValuesBucket {
  return {
    'duration_sec': metrics.durationSec, 'distance_m': metrics.distanceM, 'speed_kmh': metrics.speedKmh,
    'incline_pct': metrics.inclinePct, 'level': metrics.level, 'steps': metrics.steps, 'floors': metrics.floors,
    'cadence_per_min': metrics.cadencePerMin, 'avg_power_w': metrics.avgPowerW,
    'avg_heart_rate_bpm': metrics.avgHeartRateBpm, 'energy_kcal': metrics.energyKcal
  };
}

function numeric(rs: relationalStore.ResultSet, column: string): number | null {
  const index: number = rs.getColumnIndex(column);
  return index < 0 || rs.isColumnNull(index) ? null : rs.getDouble(index);
}

export function readCardioMetrics(rs: relationalStore.ResultSet): CardioMetrics {
  const metrics: CardioMetrics = new CardioMetrics();
  metrics.durationSec = numeric(rs, 'duration_sec');
  metrics.distanceM = numeric(rs, 'distance_m');
  metrics.speedKmh = numeric(rs, 'speed_kmh');
  metrics.inclinePct = numeric(rs, 'incline_pct');
  metrics.level = numeric(rs, 'level');
  metrics.steps = numeric(rs, 'steps');
  metrics.floors = numeric(rs, 'floors');
  metrics.cadencePerMin = numeric(rs, 'cadence_per_min');
  metrics.avgPowerW = numeric(rs, 'avg_power_w');
  metrics.avgHeartRateBpm = numeric(rs, 'avg_heart_rate_bpm');
  metrics.energyKcal = numeric(rs, 'energy_kcal');
  return metrics;
}

export function putCardioValues(bucket: relationalStore.ValuesBucket, metrics: CardioMetrics): void {
  const values: relationalStore.ValuesBucket = cardioValues(metrics);
  for (let i = 0; i < CARDIO_COLUMNS.length; i++) {
    bucket[CARDIO_COLUMNS[i]] = values[CARDIO_COLUMNS[i]];
  }
}
