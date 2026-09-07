import { addDays, isoWeekStart, rangeStart } from './DateUtil';

export const PART_ORDER: string[] = [
  'chest', 'shoulder', 'back', 'arm', 'glute', 'leg', 'abs', 'core', 'cardio'
];

export class TrendSetRow {
  date: string = '';
  exerciseId: string = '';
  exerciseName: string = '';
  partKey: string = '';
  movementPattern: string = '';
  isBodyweight: number = 0;
  weight: number | null = null;
  reps: number | null = null;
  rir: number | null = null;
  isWarmup: number = 0;
  status: string = 'done';
}

export class TrendWeightRow {
  date: string = '';
  weightKg: number = 0;
}

export class TrendPoint {
  date: string = '';
  value: number = 0;
}

export class KeyLiftPick {
  exerciseId: string = '';
  name: string = '';
  partKey: string = '';
  movementPattern: string = '';
  isBodyweight: number = 0;
  isCompound: boolean = false;
  sessions: number = 0;
  workSets: number = 0;
}

export class KeyLiftSeries {
  exerciseId: string = '';
  name: string = '';
  metric: string = 'top_weight';
  points: TrendPoint[] = [];
  firstValue: number = 0;
  lastValue: number = 0;
}

export class PartVolumeRow {
  partKey: string = '';
  thisWeek: number = 0;
  avg4: number = 0;
}

export class TrendDigest {
  sessions: number = 0;
  workSets: number = 0;
  hasWeight: boolean = false;
  weightKg: number = 0;
  weightDate: string = '';
  hasDelta: boolean = false;
  weightDelta: number = 0;
  lifts: KeyLiftSeries[] = [];
  parts: PartVolumeRow[] = [];
  weights: TrendPoint[] = [];
}

class ExerciseStat {
  exerciseId: string = '';
  name: string = '';
  partKey: string = '';
  movementPattern: string = '';
  isBodyweight: number = 0;
  sessions: number = 0;
  workSets: number = 0;
  dateSeen: Map<string, boolean> = new Map();
}

class DayAgg {
  date: string = '';
  bestE1rm: number | null = null;
  topWeight: number | null = null;
  totalReps: number = 0;
  hasReps: boolean = false;
}

export function isWorkSet(row: TrendSetRow): boolean {
  return row.status === 'done' && row.isWarmup === 0;
}

export function isCompoundLift(pattern: string, partKey: string): boolean {
  if (partKey === 'abs' || partKey === 'core' || partKey === 'cardio') {
    return false;
  }
  return pattern === 'push' || pattern === 'pull' || pattern === 'hinge' || pattern === 'squat';
}

export function epleyE1rm(weight: number | null, reps: number | null): number | null {
  if (weight === null || reps === null) {
    return null;
  }
  if (reps < 1) {
    return null;
  }
  return weight * (1 + reps / 30);
}

export function isE1rmEligible(row: TrendSetRow): boolean {
  if (!isWorkSet(row)) {
    return false;
  }
  if (row.rir === null || row.rir > 1) {
    return false;
  }
  if (row.reps === null || row.reps < 1 || row.reps > 8) {
    return false;
  }
  if (row.weight === null) {
    return false;
  }
  return true;
}

export function chartFromDate(today: string, rangeKind: string): string {
  if (rangeKind === 'all') {
    return '';
  }
  let weeks: number = 12;
  if (rangeKind === '4') {
    weeks = 4;
  }
  return rangeStart(today, weeks);
}

export function digestQueryStart(today: string, rangeKind: string): string {
  const volumeFrom: string = addDays(isoWeekStart(today), -28);
  if (rangeKind === 'all') {
    return '';
  }
  const chartFrom: string = chartFromDate(today, rangeKind);
  if (chartFrom.length === 0 || chartFrom < volumeFrom) {
    return chartFrom;
  }
  return volumeFrom;
}

export function formatTrendNumber(value: number): string {
  const rounded: number = Math.round(value * 10) / 10;
  if (rounded === Math.floor(rounded)) {
    return `${Math.floor(rounded)}`;
  }
  return rounded.toFixed(1);
}

export function liftMetricLabel(metric: string): string {
  if (metric === 'e1rm') {
    return 'e1RM';
  }
  if (metric === 'reps') {
    return '次数';
  }
  return '重量';
}

export function liftChangeText(series: KeyLiftSeries): string {
  if (series.points.length === 0) {
    return '';
  }
  const last: string = formatTrendNumber(series.lastValue);
  if (series.points.length === 1) {
    return last;
  }
  return `${formatTrendNumber(series.firstValue)} → ${last}`;
}

export function weightDeltaText(digest: TrendDigest): string {
  if (!digest.hasWeight) {
    return '未记录';
  }
  const latest: string = `${formatTrendNumber(digest.weightKg)} kg`;
  if (!digest.hasDelta) {
    return latest;
  }
  if (digest.weightDelta === 0) {
    return `${latest} · 持平`;
  }
  const sign: string = digest.weightDelta > 0 ? '+' : '';
  return `${latest} · ${sign}${formatTrendNumber(digest.weightDelta)}`;
}

export function pickKeyLifts(rows: TrendSetRow[], limit: number): KeyLiftPick[] {
  const stats: ExerciseStat[] = collectStats(rows);
  stats.sort((a: ExerciseStat, b: ExerciseStat) => {
    if (a.sessions !== b.sessions) {
      return b.sessions - a.sessions;
    }
    if (a.workSets !== b.workSets) {
      return b.workSets - a.workSets;
    }
    if (a.name < b.name) {
      return -1;
    }
    if (a.name > b.name) {
      return 1;
    }
    return 0;
  });
  const picked: KeyLiftPick[] = [];
  const usedParts: Map<string, boolean> = new Map();
  const usedIds: Map<string, boolean> = new Map();
  appendPicks(stats, picked, usedParts, usedIds, limit, true);
  if (picked.length < limit) {
    appendPicks(stats, picked, usedParts, usedIds, limit, false);
  }
  return picked;
}

export function buildLiftSeries(rows: TrendSetRow[], pick: KeyLiftPick): KeyLiftSeries {
  const series: KeyLiftSeries = new KeyLiftSeries();
  series.exerciseId = pick.exerciseId;
  series.name = pick.name;
  const days: DayAgg[] = aggregateDays(rows, pick.exerciseId);
  let metric: string = 'top_weight';
  if (pick.isBodyweight === 1) {
    metric = 'reps';
  } else if (pick.isCompound) {
    let e1rmCount: number = 0;
    for (let i = 0; i < days.length; i++) {
      if (days[i].bestE1rm !== null) {
        e1rmCount += 1;
      }
    }
    if (e1rmCount >= 2) {
      metric = 'e1rm';
    }
  }
  series.metric = metric;
  for (let i = 0; i < days.length; i++) {
    const day: DayAgg = days[i];
    let value: number | null = null;
    if (metric === 'e1rm') {
      value = day.bestE1rm;
    } else if (metric === 'reps') {
      if (day.hasReps) {
        value = day.totalReps;
      }
    } else {
      value = day.topWeight;
    }
    if (value === null) {
      continue;
    }
    const point: TrendPoint = new TrendPoint();
    point.date = day.date;
    point.value = value;
    series.points.push(point);
  }
  if (series.points.length > 0) {
    series.firstValue = series.points[0].value;
    series.lastValue = series.points[series.points.length - 1].value;
  }
  return series;
}

export function weekSummary(rows: TrendSetRow[], today: string): number[] {
  const weekStart: string = isoWeekStart(today);
  const weekEnd: string = addDays(weekStart, 6);
  const dates: Map<string, boolean> = new Map();
  let workSets: number = 0;
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    if (row.date < weekStart || row.date > weekEnd) {
      continue;
    }
    workSets += 1;
    dates.set(row.date, true);
  }
  return [dates.size, workSets];
}

export function partVolumeRows(rows: TrendSetRow[], today: string): PartVolumeRow[] {
  const thisStart: string = isoWeekStart(today);
  const thisEnd: string = addDays(thisStart, 6);
  const histStart: string = addDays(thisStart, -28);
  const histEnd: string = addDays(thisStart, -1);
  const thisCounts: Map<string, number> = new Map();
  const histCounts: Map<string, number> = new Map();
  for (let i = 0; i < PART_ORDER.length; i++) {
    thisCounts.set(PART_ORDER[i], 0);
    histCounts.set(PART_ORDER[i], 0);
  }
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    if (thisCounts.get(row.partKey) === undefined) {
      continue;
    }
    if (row.date >= thisStart && row.date <= thisEnd) {
      thisCounts.set(row.partKey, (thisCounts.get(row.partKey) as number) + 1);
    } else if (row.date >= histStart && row.date <= histEnd) {
      histCounts.set(row.partKey, (histCounts.get(row.partKey) as number) + 1);
    }
  }
  const result: PartVolumeRow[] = [];
  for (let i = 0; i < PART_ORDER.length; i++) {
    const key: string = PART_ORDER[i];
    const thisWeek: number = thisCounts.get(key) as number;
    const avg4: number = (histCounts.get(key) as number) / 4;
    if (thisWeek === 0 && avg4 === 0) {
      continue;
    }
    const item: PartVolumeRow = new PartVolumeRow();
    item.partKey = key;
    item.thisWeek = thisWeek;
    item.avg4 = avg4;
    result.push(item);
  }
  return result;
}

export function buildTrendDigest(rows: TrendSetRow[], weights: TrendWeightRow[], today: string,
  rangeKind: string): TrendDigest {
  const digest: TrendDigest = new TrendDigest();
  const summary: number[] = weekSummary(rows, today);
  digest.sessions = summary[0];
  digest.workSets = summary[1];
  applyWeightSummary(digest, weights, today);
  const chartFrom: string = chartFromDate(today, rangeKind);
  const chartRows: TrendSetRow[] = filterSetsFrom(rows, chartFrom, today);
  const picks: KeyLiftPick[] = pickKeyLifts(chartRows, 4);
  for (let i = 0; i < picks.length; i++) {
    const series: KeyLiftSeries = buildLiftSeries(chartRows, picks[i]);
    if (series.points.length === 0) {
      continue;
    }
    digest.lifts.push(series);
  }
  digest.parts = partVolumeRows(rows, today);
  digest.weights = filterWeights(weights, chartFrom, today);
  return digest;
}

function filterSetsFrom(rows: TrendSetRow[], fromDate: string, today: string): TrendSetRow[] {
  const result: TrendSetRow[] = [];
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].date > today) {
      continue;
    }
    if (fromDate.length > 0 && rows[i].date < fromDate) {
      continue;
    }
    result.push(rows[i]);
  }
  return result;
}

function filterWeights(rows: TrendWeightRow[], fromDate: string, today: string): TrendPoint[] {
  const points: TrendPoint[] = [];
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].date > today) {
      continue;
    }
    if (fromDate.length > 0 && rows[i].date < fromDate) {
      continue;
    }
    const point: TrendPoint = new TrendPoint();
    point.date = rows[i].date;
    point.value = rows[i].weightKg;
    points.push(point);
  }
  points.sort((a: TrendPoint, b: TrendPoint) => {
    if (a.date < b.date) {
      return -1;
    }
    if (a.date > b.date) {
      return 1;
    }
    return 0;
  });
  return points;
}

function applyWeightSummary(digest: TrendDigest, weights: TrendWeightRow[], today: string): void {
  const past: TrendWeightRow[] = [];
  for (let i = 0; i < weights.length; i++) {
    if (weights[i].date <= today) {
      past.push(weights[i]);
    }
  }
  past.sort((a: TrendWeightRow, b: TrendWeightRow) => {
    if (a.date < b.date) {
      return -1;
    }
    if (a.date > b.date) {
      return 1;
    }
    return 0;
  });
  if (past.length === 0) {
    return;
  }
  const latest: TrendWeightRow = past[past.length - 1];
  digest.hasWeight = true;
  digest.weightKg = latest.weightKg;
  digest.weightDate = latest.date;
  if (past.length < 2) {
    return;
  }
  digest.hasDelta = true;
  digest.weightDelta = latest.weightKg - past[past.length - 2].weightKg;
}

function collectStats(rows: TrendSetRow[]): ExerciseStat[] {
  const list: ExerciseStat[] = [];
  const indexOf: Map<string, number> = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    let idx: number | undefined = indexOf.get(row.exerciseId);
    if (idx === undefined) {
      const stat: ExerciseStat = new ExerciseStat();
      stat.exerciseId = row.exerciseId;
      stat.name = row.exerciseName;
      stat.partKey = row.partKey;
      stat.movementPattern = row.movementPattern;
      stat.isBodyweight = row.isBodyweight;
      indexOf.set(row.exerciseId, list.length);
      list.push(stat);
      idx = list.length - 1;
    }
    const stat: ExerciseStat = list[idx];
    stat.workSets += 1;
    if (stat.dateSeen.get(row.date) !== true) {
      stat.dateSeen.set(row.date, true);
      stat.sessions += 1;
    }
  }
  return list;
}

function appendPicks(stats: ExerciseStat[], picked: KeyLiftPick[], usedParts: Map<string, boolean>,
  usedIds: Map<string, boolean>, limit: number, compoundsOnly: boolean): void {
  for (let i = 0; i < stats.length; i++) {
    if (picked.length >= limit) {
      return;
    }
    const stat: ExerciseStat = stats[i];
    if (usedIds.get(stat.exerciseId) === true) {
      continue;
    }
    if (usedParts.get(stat.partKey) === true) {
      continue;
    }
    const compound: boolean = isCompoundLift(stat.movementPattern, stat.partKey);
    if (compoundsOnly) {
      if (!compound) {
        continue;
      }
    } else if (stat.partKey === 'cardio') {
      continue;
    }
    usedIds.set(stat.exerciseId, true);
    usedParts.set(stat.partKey, true);
    const pick: KeyLiftPick = new KeyLiftPick();
    pick.exerciseId = stat.exerciseId;
    pick.name = stat.name;
    pick.partKey = stat.partKey;
    pick.movementPattern = stat.movementPattern;
    pick.isBodyweight = stat.isBodyweight;
    pick.isCompound = compound;
    pick.sessions = stat.sessions;
    pick.workSets = stat.workSets;
    picked.push(pick);
  }
}

function aggregateDays(rows: TrendSetRow[], exerciseId: string): DayAgg[] {
  const list: DayAgg[] = [];
  const indexOf: Map<string, number> = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (row.exerciseId !== exerciseId || !isWorkSet(row)) {
      continue;
    }
    let idx: number | undefined = indexOf.get(row.date);
    if (idx === undefined) {
      const day: DayAgg = new DayAgg();
      day.date = row.date;
      indexOf.set(row.date, list.length);
      list.push(day);
      idx = list.length - 1;
    }
    const day: DayAgg = list[idx];
    if (isE1rmEligible(row)) {
      const e1rm: number | null = epleyE1rm(row.weight, row.reps);
      if (e1rm !== null && (day.bestE1rm === null || e1rm > day.bestE1rm)) {
        day.bestE1rm = e1rm;
      }
    }
    if (row.weight !== null && (day.topWeight === null || row.weight > day.topWeight)) {
      day.topWeight = row.weight;
    }
    if (row.reps !== null) {
      day.totalReps += row.reps;
      day.hasReps = true;
    }
  }
  list.sort((a: DayAgg, b: DayAgg) => {
    if (a.date < b.date) {
      return -1;
    }
    if (a.date > b.date) {
      return 1;
    }
    return 0;
  });
  return list;
}
