// Portable data model: no ArkUI or platform dependencies.
export class CardioMetrics {
  durationSec: number | null = null;
  distanceM: number | null = null;
  speedKmh: number | null = null;
  inclinePct: number | null = null;
  level: number | null = null;
  steps: number | null = null;
  floors: number | null = null;
  cadencePerMin: number | null = null;
  avgPowerW: number | null = null;
  avgHeartRateBpm: number | null = null;
  energyKcal: number | null = null;
}
