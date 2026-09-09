import { addDays, daysSinceEpoch, isoWeekStart, rangeStart } from './DateUtil';

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
  technique: string = '';
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

export class ChartPoint {
  date: string = '';
  value: number = 0;
  xRatio: number = 0;
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
  insufficientData: boolean = false;
  estimated: boolean = false;
}

export class PartGoalRow {
  partKey: string = '';
  workSetsTarget: number | null = null;
}

export class TrendPreferences {
  watchedExerciseIds: string[] = [];
  sessionsTarget: number | null = null;
  partGoals: PartGoalRow[] = [];
}

export class PartGoalProgress {
  partKey: string = '';
  done: number = 0;
  target: number = 0;
}

export class WeekGoalProgress {
  sessionsDone: number = 0;
  sessionsTarget: number | null = null;
  parts: PartGoalProgress[] = [];
}

export class WeightTrendSummary {
  hasWeight: boolean = false;
  latestKg: number = 0;
  latestDate: string = '';
  sparse: boolean = true;
  hasDelta: boolean = false;
  deltaKg: number = 0;
  referenceDate: string = '';
}

export class ExerciseMeta {
  exerciseId: string = '';
  name: string = '';
  partKey: string = '';
  movementPattern: string = '';
  isBodyweight: number = 0;
}

export class ExerciseSessionRow {
  date: string = '';
  value: number | null = null;
  workSets: number = 0;
  minRir: number | null = null;
}

export class ExerciseTrendDetail {
  exerciseId: string = '';
  name: string = '';
  partKey: string = '';
  metric: string = 'top_weight';
  metricLabel: string = '';
  points: TrendPoint[] = [];
  insufficientData: boolean = false;
  estimated: boolean = false;
  secondaryLabel: string = '';
  secondaryPoints: TrendPoint[] = [];
  sessions: number = 0;
  workSets: number = 0;
  recentSessions: ExerciseSessionRow[] = [];
}

export class WatchableExercise {
  exerciseId: string = '';
  name: string = '';
  partKey: string = '';
  sessions: number = 0;
  workSets: number = 0;
}

export class TrendInsight {
  kind: string = 'none'; // 'setup' | 'session_goal' | 'part_goal' | 'stall' | 'progress' | 'none'
  message: string = '';
  exerciseId: string = '';
  partKey: string = '';
  remaining: number = 0;
}

export class PrBoardRow {
  exerciseId: string = '';
  name: string = '';
  maxWeight: number = 0;
  repsAtWeight: number = 0;
  weightDate: string = '';
  repsDate: string = '';
}

export class TrendDigest {
  sessions: number = 0;
  workSets: number = 0;
  lifts: KeyLiftSeries[] = [];
  weekGoal: WeekGoalProgress = new WeekGoalProgress();
  weightTrend: WeightTrendSummary = new WeightTrendSummary();
  weightPoints: TrendPoint[] = [];
  volumePoints: TrendPoint[] = [];
  prBoard: PrBoardRow[] = [];
  insight: TrendInsight = new TrendInsight();
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
  e1rmStrict: boolean = false;
  e1rmEstimated: boolean = false;
  topWeight: number | null = null;
  bestReps: number | null = null;
}

class PrAcc {
  exerciseId: string = '';
  name: string = '';
  maxWeight: number = 0;
  hasWeight: boolean = false;
  weightDate: string = '';
  repsAtWeight: number = 0;
  hasReps: boolean = false;
  repsDate: string = '';
}

class WindowAverage {
  count: number = 0;
  avg: number = 0;
}

export function isWorkSet(row: TrendSetRow): boolean {
  return row.status === 'done' && row.isWarmup === 0;
}

// 递减组/递增组/休息暂停组的重量或次数不代表该动作当天的真实上限，
// 会污染力量表现指标（e1RM、top weight）。AMRAP 组本身就是往上限做的
// 一组，仍然可以参与力量表现判定，只是继续受 RIR / reps 条件约束。
export function isLiftPerformancePoint(row: TrendSetRow): boolean {
  if (!isWorkSet(row)) {
    return false;
  }
  if (row.technique === 'drop' || row.technique === 'ramp' || row.technique === 'rest_pause') {
    return false;
  }
  return true;
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
  if (!isLiftPerformancePoint(row)) {
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

export function isE1rmEstimated(row: TrendSetRow): boolean {
  if (!isLiftPerformancePoint(row)) {
    return false;
  }
  if (row.rir !== null) {
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

export function isE1rmCountable(row: TrendSetRow): boolean {
  return isE1rmEligible(row) || isE1rmEstimated(row);
}

export function setVolume(row: TrendSetRow): number | null {
  if (!isWorkSet(row) || row.weight === null || row.reps === null) {
    return null;
  }
  return row.weight * row.reps;
}

export function buildVolumeSeries(rows: TrendSetRow[]): TrendPoint[] {
  const totals: Map<string, number> = new Map();
  const dates: string[] = [];
  for (let i = 0; i < rows.length; i++) {
    const vol: number | null = setVolume(rows[i]);
    if (vol === null) {
      continue;
    }
    const date: string = rows[i].date;
    const prev: number | undefined = totals.get(date);
    if (prev === undefined) {
      dates.push(date);
      totals.set(date, vol);
    } else {
      totals.set(date, prev + vol);
    }
  }
  dates.sort();
  const points: TrendPoint[] = [];
  for (let i = 0; i < dates.length; i++) {
    const point: TrendPoint = new TrendPoint();
    point.date = dates[i];
    point.value = totals.get(dates[i]) as number;
    points.push(point);
  }
  return points;
}

export function buildPrBoard(rows: TrendSetRow[]): PrBoardRow[] {
  const accs: PrAcc[] = [];
  const indexOf: Map<string, number> = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (!isWorkSet(row) || row.weight === null) {
      continue;
    }
    let idx: number | undefined = indexOf.get(row.exerciseId);
    if (idx === undefined) {
      const acc: PrAcc = new PrAcc();
      acc.exerciseId = row.exerciseId;
      acc.name = row.exerciseName;
      indexOf.set(row.exerciseId, accs.length);
      accs.push(acc);
      idx = accs.length - 1;
    }
    const acc: PrAcc = accs[idx];
    const weight: number = row.weight as number;
    if (!acc.hasWeight || weight > acc.maxWeight) {
      acc.maxWeight = weight;
      acc.hasWeight = true;
      acc.weightDate = row.date;
      acc.repsAtWeight = 0;
      acc.hasReps = false;
      acc.repsDate = '';
      if (row.reps !== null) {
        acc.repsAtWeight = row.reps;
        acc.hasReps = true;
        acc.repsDate = row.date;
      }
    } else if (weight === acc.maxWeight) {
      if (row.reps !== null && (!acc.hasReps || row.reps > acc.repsAtWeight)) {
        acc.repsAtWeight = row.reps;
        acc.hasReps = true;
        acc.repsDate = row.date;
      }
    }
  }
  const board: PrBoardRow[] = [];
  for (let i = 0; i < accs.length; i++) {
    const acc: PrAcc = accs[i];
    if (!acc.hasWeight) {
      continue;
    }
    const item: PrBoardRow = new PrBoardRow();
    item.exerciseId = acc.exerciseId;
    item.name = acc.name;
    item.maxWeight = acc.maxWeight;
    item.repsAtWeight = acc.repsAtWeight;
    item.weightDate = acc.weightDate;
    item.repsDate = acc.repsDate.length > 0 ? acc.repsDate : acc.weightDate;
    board.push(item);
  }
  board.sort((a: PrBoardRow, b: PrBoardRow) => {
    const aLast: string = a.repsDate > a.weightDate ? a.repsDate : a.weightDate;
    const bLast: string = b.repsDate > b.weightDate ? b.repsDate : b.weightDate;
    if (aLast > bLast) {
      return -1;
    }
    if (aLast < bLast) {
      return 1;
    }
    if (a.exerciseId < b.exerciseId) {
      return -1;
    }
    return 1;
  });
  return board;
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
    return '最佳次数';
  }
  return '重量';
}

export function liftChangeText(series: KeyLiftSeries): string {
  if (series.points.length === 0) {
    return '';
  }
  const last: string = formatTrendNumber(series.lastValue);
  let text: string = last;
  if (series.points.length > 1) {
    text = `${formatTrendNumber(series.firstValue)} → ${last}`;
  }
  if (series.estimated) {
    return `${text} · 估算`;
  }
  return text;
}

export function volumeChangeText(points: TrendPoint[]): string {
  if (points.length === 0) {
    return '';
  }
  const last: string = formatTrendNumber(points[points.length - 1].value);
  if (points.length === 1) {
    return last;
  }
  return `${formatTrendNumber(points[0].value)} → ${last}`;
}

export function prBoardLine(row: PrBoardRow): string {
  if (row.repsAtWeight > 0) {
    return `${formatTrendNumber(row.maxWeight)} kg × ${row.repsAtWeight}`;
  }
  return `${formatTrendNumber(row.maxWeight)} kg`;
}

export function weightDeltaText(trend: WeightTrendSummary): string {
  if (!trend.hasWeight) {
    return '未记录';
  }
  const latest: string = `${formatTrendNumber(trend.latestKg)} kg`;
  if (!trend.hasDelta) {
    return latest;
  }
  const sign: string = trend.deltaKg > 0 ? '+' : '';
  if (trend.sparse) {
    if (trend.deltaKg === 0) {
      return `${latest} · 较 ${trend.referenceDate} 持平`;
    }
    return `${latest} · 较 ${trend.referenceDate} ${sign}${formatTrendNumber(trend.deltaKg)}`;
  }
  if (trend.deltaKg === 0) {
    return `${latest} · 近7天持平`;
  }
  return `${latest} · 近7天 ${sign}${formatTrendNumber(trend.deltaKg)}`;
}

function toKeyLiftPick(stat: ExerciseStat): KeyLiftPick {
  const pick: KeyLiftPick = new KeyLiftPick();
  pick.exerciseId = stat.exerciseId;
  pick.name = stat.name;
  pick.partKey = stat.partKey;
  pick.movementPattern = stat.movementPattern;
  pick.isBodyweight = stat.isBodyweight;
  pick.isCompound = isCompoundLift(stat.movementPattern, stat.partKey);
  pick.sessions = stat.sessions;
  pick.workSets = stat.workSets;
  return pick;
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

// 已配置关注动作时严格按用户顺序展示，不再按部位强制去重——用户可以
// 同时关注两个胸部动作。只有在用户从未配置任何关注动作时，才回退到
// 自动推荐（用于新用户的空状态，且不占用户配置的名额上限）。
export function resolveWatchedLifts(rows: TrendSetRow[], watchedIds: string[], autoRecommendLimit: number): KeyLiftPick[] {
  const stats: ExerciseStat[] = collectStats(rows);
  if (watchedIds.length === 0) {
    return pickKeyLifts(rows, autoRecommendLimit);
  }
  const statById: Map<string, ExerciseStat> = new Map();
  for (let i = 0; i < stats.length; i++) {
    statById.set(stats[i].exerciseId, stats[i]);
  }
  const picked: KeyLiftPick[] = [];
  const usedIds: Map<string, boolean> = new Map();
  for (let i = 0; i < watchedIds.length; i++) {
    const id: string = watchedIds[i];
    if (usedIds.get(id) === true) {
      continue;
    }
    usedIds.set(id, true);
    const stat: ExerciseStat | undefined = statById.get(id);
    if (stat === undefined) {
      continue;
    }
    picked.push(toKeyLiftPick(stat));
  }
  return picked;
}

export function buildLiftSeries(rows: TrendSetRow[], pick: KeyLiftPick): KeyLiftSeries {
  const series: KeyLiftSeries = new KeyLiftSeries();
  series.exerciseId = pick.exerciseId;
  series.name = pick.name;
  const days: DayAgg[] = aggregateDays(rows, pick.exerciseId);
  const metric: string = liftMetricFor(pick.isBodyweight, pick.isCompound);
  series.metric = metric;
  for (let i = 0; i < days.length; i++) {
    const day: DayAgg = days[i];
    const value: number | null = metricValueOf(day, metric);
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
  if (metric === 'e1rm' && series.points.length < 2) {
    series.insufficientData = true;
  }
  if (metric === 'e1rm') {
    let anyEstimated: boolean = false;
    let anyStrict: boolean = false;
    for (let i = 0; i < days.length; i++) {
      if (days[i].bestE1rm === null) {
        continue;
      }
      if (days[i].e1rmStrict) {
        anyStrict = true;
      }
      if (days[i].e1rmEstimated) {
        anyEstimated = true;
      }
    }
    series.estimated = anyEstimated && !anyStrict;
  }
  return series;
}

// 指标由动作类型决定，不随数据量或时间范围切换：
// 自重动作看最佳单组次数；负重复合动作看 e1RM；负重孤立动作看最重重量。
// 复合动作的 e1RM 数据点不足时，交给调用方通过 insufficientData 标记提示，
// 而不是悄悄换成另一种指标——否则同一条折线在不同时间范围下含义会变。
function liftMetricFor(isBodyweight: number, isCompound: boolean): string {
  if (isBodyweight === 1) {
    return 'reps';
  }
  if (isCompound) {
    return 'e1rm';
  }
  return 'top_weight';
}

function metricValueOf(day: DayAgg, metric: string): number | null {
  if (metric === 'e1rm') {
    return day.bestE1rm;
  }
  if (metric === 'reps') {
    return day.bestReps;
  }
  return day.topWeight;
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

function weekWorkSetsByPart(rows: TrendSetRow[], today: string): Map<string, number> {
  const weekStart: string = isoWeekStart(today);
  const weekEnd: string = addDays(weekStart, 6);
  const counts: Map<string, number> = new Map();
  for (let i = 0; i < PART_ORDER.length; i++) {
    counts.set(PART_ORDER[i], 0);
  }
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    if (row.date < weekStart || row.date > weekEnd) {
      continue;
    }
    if (counts.get(row.partKey) === undefined) {
      continue;
    }
    counts.set(row.partKey, (counts.get(row.partKey) as number) + 1);
  }
  return counts;
}

// 只展示用户设置了目标的部位，且只在本周结束后才有意义地比较高低——
// 中途只展示 done/target 进度，不做「低于近 4 周」这类会被训练计划
// 尚未执行完打断的判断。
export function buildWeekGoalProgress(rows: TrendSetRow[], today: string, prefs: TrendPreferences): WeekGoalProgress {
  const progress: WeekGoalProgress = new WeekGoalProgress();
  const summary: number[] = weekSummary(rows, today);
  progress.sessionsDone = summary[0];
  progress.sessionsTarget = prefs.sessionsTarget;
  const doneByPart: Map<string, number> = weekWorkSetsByPart(rows, today);
  const goalByPart: Map<string, number> = new Map();
  for (let i = 0; i < prefs.partGoals.length; i++) {
    if (prefs.partGoals[i].workSetsTarget !== null) {
      goalByPart.set(prefs.partGoals[i].partKey, prefs.partGoals[i].workSetsTarget as number);
    }
  }
  for (let i = 0; i < PART_ORDER.length; i++) {
    const key: string = PART_ORDER[i];
    const target: number | undefined = goalByPart.get(key);
    if (target === undefined) {
      continue;
    }
    const row: PartGoalProgress = new PartGoalProgress();
    row.partKey = key;
    row.done = doneByPart.get(key) === undefined ? 0 : (doneByPart.get(key) as number);
    row.target = target;
    progress.parts.push(row);
  }
  return progress;
}

function averageInRange(weights: TrendWeightRow[], start: string, end: string): WindowAverage {
  let sum: number = 0;
  let count: number = 0;
  for (let i = 0; i < weights.length; i++) {
    if (weights[i].date < start || weights[i].date > end) {
      continue;
    }
    sum += weights[i].weightKg;
    count += 1;
  }
  const result: WindowAverage = new WindowAverage();
  result.count = count;
  if (count > 0) {
    result.avg = sum / count;
  }
  return result;
}

// 体重天然有 ±0.5~1kg 的日间噪声（喝水、排便、盐分），单日对单日的差值
// 没有意义。优先用近 7 天均值 vs 前 7 天均值；样本不够时才退化为最近两次
// 实际记录的差值，并明确标注日期与「记录较少」，不假装这是可靠趋势。
export function buildWeightTrend(weights: TrendWeightRow[], today: string): WeightTrendSummary {
  const summary: WeightTrendSummary = new WeightTrendSummary();
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
    return summary;
  }
  summary.hasWeight = true;
  const latest: TrendWeightRow = past[past.length - 1];
  summary.latestKg = latest.weightKg;
  summary.latestDate = latest.date;

  const recentStart: string = addDays(today, -6);
  const priorEnd: string = addDays(recentStart, -1);
  const priorStart: string = addDays(priorEnd, -6);
  const recentWin: WindowAverage = averageInRange(past, recentStart, today);
  const priorWin: WindowAverage = averageInRange(past, priorStart, priorEnd);
  if (recentWin.count >= 3 && priorWin.count >= 3) {
    summary.sparse = false;
    summary.hasDelta = true;
    summary.latestKg = recentWin.avg;
    summary.deltaKg = recentWin.avg - priorWin.avg;
    return summary;
  }

  summary.sparse = true;
  if (past.length < 2) {
    return summary;
  }
  const previous: TrendWeightRow = past[past.length - 2];
  summary.hasDelta = true;
  summary.deltaKg = latest.weightKg - previous.weightKg;
  summary.referenceDate = previous.date;
  return summary;
}

// 折线按真实日期间距摆放数据点，而不是按数据点序号平均分布——否则相隔
// 1 天和相隔 30 天的两个点在图上看起来完全一样。
export function datedChartPositions(points: TrendPoint[]): ChartPoint[] {
  const result: ChartPoint[] = [];
  const n: number = points.length;
  if (n === 0) {
    return result;
  }
  if (n === 1) {
    const single: ChartPoint = new ChartPoint();
    single.date = points[0].date;
    single.value = points[0].value;
    single.xRatio = 0.5;
    result.push(single);
    return result;
  }
  const firstDay: number = daysSinceEpoch(points[0].date);
  const lastDay: number = daysSinceEpoch(points[n - 1].date);
  const span: number = lastDay - firstDay;
  for (let i = 0; i < n; i++) {
    const item: ChartPoint = new ChartPoint();
    item.date = points[i].date;
    item.value = points[i].value;
    if (span <= 0) {
      item.xRatio = n === 1 ? 0.5 : i / (n - 1);
    } else {
      item.xRatio = (daysSinceEpoch(points[i].date) - firstDay) / span;
    }
    result.push(item);
  }
  return result;
}

// 提醒的优先级：先补配置，再补本周目标缺口，再看有足够数据支撑的力量
// 变化。少于 3 个可比较数据点时不对该动作下任何「进步/停滞」结论——
// 数据量太少时，任何点对点的差异都可能只是噪声。每次只给一条，多了会
// 被当成背景噪音直接忽略。
export function buildTrendInsight(prefs: TrendPreferences, weekGoal: WeekGoalProgress,
  lifts: KeyLiftSeries[]): TrendInsight {
  const insight: TrendInsight = new TrendInsight();
  const hasAnyConfig: boolean = prefs.watchedExerciseIds.length > 0 || prefs.sessionsTarget !== null ||
    prefs.partGoals.length > 0;
  if (!hasAnyConfig) {
    insight.kind = 'setup';
    insight.message = '还没有设置关注动作或每周目标，先去设置一下';
    return insight;
  }

  if (weekGoal.sessionsTarget !== null) {
    const remaining: number = (weekGoal.sessionsTarget as number) - weekGoal.sessionsDone;
    if (remaining > 0) {
      insight.kind = 'session_goal';
      insight.remaining = remaining;
      insight.message = `本周还需训练 ${remaining} 次`;
      return insight;
    }
  }
  for (let i = 0; i < weekGoal.parts.length; i++) {
    const row: PartGoalProgress = weekGoal.parts[i];
    const remaining: number = row.target - row.done;
    if (remaining > 0) {
      insight.kind = 'part_goal';
      insight.partKey = row.partKey;
      insight.remaining = remaining;
      return insight;
    }
  }

  for (let i = 0; i < lifts.length; i++) {
    const series: KeyLiftSeries = lifts[i];
    if (series.points.length < 3) {
      continue;
    }
    if (series.lastValue < series.firstValue) {
      insight.kind = 'stall';
      insight.exerciseId = series.exerciseId;
      insight.message = `${series.name} 近期${liftMetricLabel(series.metric)}在下降`;
      return insight;
    }
  }
  for (let i = 0; i < lifts.length; i++) {
    const series: KeyLiftSeries = lifts[i];
    if (series.points.length < 3) {
      continue;
    }
    if (series.lastValue > series.firstValue) {
      insight.kind = 'progress';
      insight.exerciseId = series.exerciseId;
      insight.message = `${series.name} 近期${liftMetricLabel(series.metric)}在提升`;
      return insight;
    }
  }
  return insight;
}

export function buildTrendDigest(rows: TrendSetRow[], weights: TrendWeightRow[], today: string,
  rangeKind: string, prefs: TrendPreferences): TrendDigest {
  const digest: TrendDigest = new TrendDigest();
  const summary: number[] = weekSummary(rows, today);
  digest.sessions = summary[0];
  digest.workSets = summary[1];
  digest.weekGoal = buildWeekGoalProgress(rows, today, prefs);
  digest.weightTrend = buildWeightTrend(weights, today);
  const chartFrom: string = chartFromDate(today, rangeKind);
  const chartRows: TrendSetRow[] = filterSetsFrom(rows, chartFrom, today);
  const picks: KeyLiftPick[] = resolveWatchedLifts(chartRows, prefs.watchedExerciseIds, 3);
  const pinned: boolean = prefs.watchedExerciseIds.length > 0;
  for (let i = 0; i < picks.length; i++) {
    const series: KeyLiftSeries = buildLiftSeries(chartRows, picks[i]);
    // 自动推荐仍跳过没有可比较点的动作；用户关注的动作必须留下，
    // 即使 e1RM 点不够，也要在概览上标明数据不足，而不是整行消失。
    if (series.points.length === 0 && !pinned) {
      continue;
    }
    digest.lifts.push(series);
  }
  digest.weightPoints = filterWeights(weights, chartFrom, today);
  digest.volumePoints = buildVolumeSeries(chartRows);
  digest.prBoard = buildPrBoard(chartRows);
  digest.insight = buildTrendInsight(prefs, digest.weekGoal, digest.lifts);
  return digest;
}

// 单动作详情页：指标固定由动作类型决定；负重复合动作用 e1RM 但数据点
// 不足 2 个时标记 insufficientData，交给页面显示「数据不足」而不是悄悄
// 换成别的指标；负重孤立动作在主指标（top weight）之外，额外给出「同
// 重量下的次数变化」这个设计文档里孤立动作该看的第二指标。
export function buildExerciseTrendDetail(rows: TrendSetRow[], meta: ExerciseMeta): ExerciseTrendDetail {
  const detail: ExerciseTrendDetail = new ExerciseTrendDetail();
  detail.exerciseId = meta.exerciseId;
  detail.name = meta.name;
  detail.partKey = meta.partKey;
  const isCompound: boolean = isCompoundLift(meta.movementPattern, meta.partKey);
  const metric: string = liftMetricFor(meta.isBodyweight, isCompound);
  detail.metric = metric;
  detail.metricLabel = liftMetricLabel(metric);

  let sessions: number = 0;
  let workSets: number = 0;
  const seenDates: Map<string, boolean> = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (row.exerciseId !== meta.exerciseId || !isWorkSet(row)) {
      continue;
    }
    workSets += 1;
    if (seenDates.get(row.date) !== true) {
      seenDates.set(row.date, true);
      sessions += 1;
    }
  }
  detail.sessions = sessions;
  detail.workSets = workSets;

  const days: DayAgg[] = aggregateDays(rows, meta.exerciseId);
  for (let i = 0; i < days.length; i++) {
    const value: number | null = metricValueOf(days[i], metric);
    if (value === null) {
      continue;
    }
    const point: TrendPoint = new TrendPoint();
    point.date = days[i].date;
    point.value = value;
    detail.points.push(point);
  }
  if (metric === 'e1rm' && detail.points.length < 2) {
    detail.insufficientData = true;
  }
  if (metric === 'e1rm') {
    let anyEstimated: boolean = false;
    let anyStrict: boolean = false;
    for (let i = 0; i < days.length; i++) {
      if (days[i].bestE1rm === null) {
        continue;
      }
      if (days[i].e1rmStrict) {
        anyStrict = true;
      }
      if (days[i].e1rmEstimated) {
        anyEstimated = true;
      }
    }
    detail.estimated = anyEstimated && !anyStrict;
  }
  if (metric === 'top_weight') {
    detail.secondaryLabel = '同重量下的次数';
    detail.secondaryPoints = sameWeightRepsSeries(rows, meta.exerciseId);
  }
  detail.recentSessions = exerciseSessionRows(rows, meta.exerciseId, metric);
  return detail;
}

function sameWeightRepsSeries(rows: TrendSetRow[], exerciseId: string): TrendPoint[] {
  let topWeight: number | null = null;
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (row.exerciseId !== exerciseId || !isLiftPerformancePoint(row) || row.weight === null) {
      continue;
    }
    if (topWeight === null || row.weight > topWeight) {
      topWeight = row.weight;
    }
  }
  const points: TrendPoint[] = [];
  if (topWeight === null) {
    return points;
  }
  const dates: string[] = [];
  const bestReps: number[] = [];
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (row.exerciseId !== exerciseId || !isLiftPerformancePoint(row)) {
      continue;
    }
    if (row.weight === null || row.reps === null) {
      continue;
    }
    if (Math.abs(row.weight - (topWeight as number)) > 0.001) {
      continue;
    }
    let idx: number = -1;
    for (let j = 0; j < dates.length; j++) {
      if (dates[j] === row.date) {
        idx = j;
        break;
      }
    }
    if (idx === -1) {
      dates.push(row.date);
      bestReps.push(row.reps);
    } else if (row.reps > bestReps[idx]) {
      bestReps[idx] = row.reps;
    }
  }
  const order: number[] = [];
  for (let i = 0; i < dates.length; i++) {
    order.push(i);
  }
  order.sort((a: number, b: number) => {
    if (dates[a] < dates[b]) {
      return -1;
    }
    if (dates[a] > dates[b]) {
      return 1;
    }
    return 0;
  });
  for (let i = 0; i < order.length; i++) {
    const point: TrendPoint = new TrendPoint();
    point.date = dates[order[i]];
    point.value = bestReps[order[i]];
    points.push(point);
  }
  return points;
}

function exerciseSessionRows(rows: TrendSetRow[], exerciseId: string, metric: string): ExerciseSessionRow[] {
  const days: DayAgg[] = aggregateDays(rows, exerciseId);
  const valueByDate: Map<string, number | null> = new Map();
  for (let i = 0; i < days.length; i++) {
    valueByDate.set(days[i].date, metricValueOf(days[i], metric));
  }
  const dateOrder: string[] = [];
  const workSetsByDate: Map<string, number> = new Map();
  const minRirByDate: Map<string, number> = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row: TrendSetRow = rows[i];
    if (row.exerciseId !== exerciseId || !isWorkSet(row)) {
      continue;
    }
    if (workSetsByDate.get(row.date) === undefined) {
      dateOrder.push(row.date);
      workSetsByDate.set(row.date, 0);
    }
    workSetsByDate.set(row.date, (workSetsByDate.get(row.date) as number) + 1);
    if (row.rir !== null) {
      const cur: number | undefined = minRirByDate.get(row.date);
      if (cur === undefined || row.rir < cur) {
        minRirByDate.set(row.date, row.rir);
      }
    }
  }
  dateOrder.sort((a: string, b: string) => {
    if (a < b) {
      return 1;
    }
    if (a > b) {
      return -1;
    }
    return 0;
  });
  const result: ExerciseSessionRow[] = [];
  for (let i = 0; i < dateOrder.length; i++) {
    const date: string = dateOrder[i];
    const item: ExerciseSessionRow = new ExerciseSessionRow();
    item.date = date;
    const v: number | null | undefined = valueByDate.get(date);
    item.value = v === undefined ? null : v;
    item.workSets = workSetsByDate.get(date) as number;
    const rirVal: number | undefined = minRirByDate.get(date);
    item.minRir = rirVal === undefined ? null : rirVal;
    result.push(item);
  }
  return result;
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
    picked.push(toKeyLiftPick(stat));
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
    if (!isLiftPerformancePoint(row)) {
      continue;
    }
    if (isE1rmEligible(row)) {
      const e1rm: number | null = epleyE1rm(row.weight, row.reps);
      if (e1rm !== null && (day.bestE1rm === null || !day.e1rmStrict || e1rm > day.bestE1rm)) {
        day.bestE1rm = e1rm;
        day.e1rmStrict = true;
        day.e1rmEstimated = false;
      }
    } else if (!day.e1rmStrict && isE1rmEstimated(row)) {
      const e1rm: number | null = epleyE1rm(row.weight, row.reps);
      if (e1rm !== null && (day.bestE1rm === null || e1rm > day.bestE1rm)) {
        day.bestE1rm = e1rm;
        day.e1rmEstimated = true;
      }
    }
    if (row.weight !== null && (day.topWeight === null || row.weight > day.topWeight)) {
      day.topWeight = row.weight;
    }
    if (row.reps !== null && (day.bestReps === null || row.reps > day.bestReps)) {
      day.bestReps = row.reps;
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
