function pad2(value) {
  if (value < 10) {
    return `0${value}`;
  }
  return `${value}`;
}

function formatDate(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

function mondayFirstIndex(jsWeekday) {
  if (jsWeekday === 0) {
    return 6;
  }
  return jsWeekday - 1;
}

export function addDays(dateStr, delta) {
  const parts = dateStr.split('-');
  if (parts.length !== 3) {
    return dateStr;
  }
  const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]) + delta);
  return formatDate(date);
}

export function isoWeekStart(dateStr) {
  const parts = dateStr.split('-');
  if (parts.length !== 3) {
    return dateStr;
  }
  const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  return addDays(dateStr, -mondayFirstIndex(date.getDay()));
}

export function rangeStart(today, weeks) {
  if (weeks < 1) {
    return today;
  }
  return addDays(today, -(weeks * 7 - 1));
}

export function daysSinceEpoch(dateStr) {
  const parts = dateStr.split('-');
  if (parts.length !== 3) {
    return 0;
  }
  const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  return Math.floor(date.getTime() / 86400000);
}

export const PART_ORDER = [
  'chest', 'shoulder', 'back', 'arm', 'glute', 'leg', 'abs', 'core', 'cardio'
];

export function isWorkSet(row) {
  return row.status === 'done' && row.isWarmup === 0;
}

export function isLiftPerformancePoint(row) {
  if (!isWorkSet(row)) {
    return false;
  }
  if (row.technique === 'drop' || row.technique === 'ramp' || row.technique === 'rest_pause') {
    return false;
  }
  return true;
}

export function isCompoundLift(pattern, partKey) {
  if (partKey === 'abs' || partKey === 'core' || partKey === 'cardio') {
    return false;
  }
  return pattern === 'push' || pattern === 'pull' || pattern === 'hinge' || pattern === 'squat';
}

export function epleyE1rm(weight, reps) {
  if (weight === null || weight === undefined || reps === null || reps === undefined) {
    return null;
  }
  if (reps < 1) {
    return null;
  }
  return weight * (1 + reps / 30);
}

export function isE1rmEligible(row) {
  if (!isLiftPerformancePoint(row)) {
    return false;
  }
  if (row.rir === null || row.rir === undefined || row.rir > 1) {
    return false;
  }
  if (row.reps === null || row.reps === undefined || row.reps < 1 || row.reps > 8) {
    return false;
  }
  if (row.weight === null || row.weight === undefined) {
    return false;
  }
  return true;
}

export function chartFromDate(today, rangeKind) {
  if (rangeKind === 'all') {
    return '';
  }
  let weeks = 12;
  if (rangeKind === '4') {
    weeks = 4;
  }
  return rangeStart(today, weeks);
}

export function formatTrendNumber(value) {
  const rounded = Math.round(value * 10) / 10;
  if (rounded === Math.floor(rounded)) {
    return `${Math.floor(rounded)}`;
  }
  return rounded.toFixed(1);
}

export function liftMetricLabel(metric) {
  if (metric === 'e1rm') {
    return 'e1RM';
  }
  if (metric === 'reps') {
    return '最佳次数';
  }
  return '重量';
}

export function liftChangeText(series) {
  if (series.points.length === 0) {
    return '';
  }
  const last = formatTrendNumber(series.lastValue);
  if (series.points.length === 1) {
    return last;
  }
  return `${formatTrendNumber(series.firstValue)} → ${last}`;
}

export function weightDeltaText(trend) {
  if (!trend.hasWeight) {
    return '未记录';
  }
  const latest = `${formatTrendNumber(trend.latestKg)} kg`;
  if (!trend.hasDelta) {
    return latest;
  }
  const sign = trend.deltaKg > 0 ? '+' : '';
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

function toKeyLiftPick(stat) {
  return {
    exerciseId: stat.exerciseId,
    name: stat.name,
    partKey: stat.partKey,
    movementPattern: stat.movementPattern,
    isBodyweight: stat.isBodyweight,
    isCompound: isCompoundLift(stat.movementPattern, stat.partKey),
    sessions: stat.sessions,
    workSets: stat.workSets
  };
}

export function pickKeyLifts(rows, limit) {
  const stats = collectStats(rows);
  stats.sort((a, b) => {
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
  const picked = [];
  const usedParts = new Map();
  const usedIds = new Map();
  appendPicks(stats, picked, usedParts, usedIds, limit, true);
  if (picked.length < limit) {
    appendPicks(stats, picked, usedParts, usedIds, limit, false);
  }
  return picked;
}

export function resolveWatchedLifts(rows, watchedIds, autoRecommendLimit) {
  const stats = collectStats(rows);
  if (watchedIds.length === 0) {
    return pickKeyLifts(rows, autoRecommendLimit);
  }
  const statById = new Map();
  for (let i = 0; i < stats.length; i++) {
    statById.set(stats[i].exerciseId, stats[i]);
  }
  const picked = [];
  const usedIds = new Map();
  for (let i = 0; i < watchedIds.length; i++) {
    const id = watchedIds[i];
    if (usedIds.get(id) === true) {
      continue;
    }
    usedIds.set(id, true);
    const stat = statById.get(id);
    if (stat === undefined) {
      continue;
    }
    picked.push(toKeyLiftPick(stat));
  }
  return picked;
}

function liftMetricFor(isBodyweight, isCompound) {
  if (isBodyweight === 1) {
    return 'reps';
  }
  if (isCompound) {
    return 'e1rm';
  }
  return 'top_weight';
}

function metricValueOf(day, metric) {
  if (metric === 'e1rm') {
    return day.bestE1rm;
  }
  if (metric === 'reps') {
    return day.bestReps;
  }
  return day.topWeight;
}

export function buildLiftSeries(rows, pick) {
  const series = {
    exerciseId: pick.exerciseId,
    name: pick.name,
    metric: 'top_weight',
    points: [],
    firstValue: 0,
    lastValue: 0
  };
  const days = aggregateDays(rows, pick.exerciseId);
  const metric = liftMetricFor(pick.isBodyweight, pick.isCompound);
  series.metric = metric;
  for (let i = 0; i < days.length; i++) {
    const day = days[i];
    const value = metricValueOf(day, metric);
    if (value === null) {
      continue;
    }
    series.points.push({ date: day.date, value });
  }
  if (series.points.length > 0) {
    series.firstValue = series.points[0].value;
    series.lastValue = series.points[series.points.length - 1].value;
  }
  return series;
}

export function weekSummary(rows, today) {
  const weekStart = isoWeekStart(today);
  const weekEnd = addDays(weekStart, 6);
  const dates = new Map();
  let workSets = 0;
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
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

function weekWorkSetsByPart(rows, today) {
  const weekStart = isoWeekStart(today);
  const weekEnd = addDays(weekStart, 6);
  const counts = new Map();
  for (let i = 0; i < PART_ORDER.length; i++) {
    counts.set(PART_ORDER[i], 0);
  }
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    if (row.date < weekStart || row.date > weekEnd) {
      continue;
    }
    if (!counts.has(row.partKey)) {
      continue;
    }
    counts.set(row.partKey, counts.get(row.partKey) + 1);
  }
  return counts;
}

export function buildWeekGoalProgress(rows, today, prefs) {
  const progress = { sessionsDone: 0, sessionsTarget: null, parts: [] };
  const summary = weekSummary(rows, today);
  progress.sessionsDone = summary[0];
  progress.sessionsTarget = prefs.sessionsTarget;
  const doneByPart = weekWorkSetsByPart(rows, today);
  const goalByPart = new Map();
  for (let i = 0; i < prefs.partGoals.length; i++) {
    if (prefs.partGoals[i].workSetsTarget !== null) {
      goalByPart.set(prefs.partGoals[i].partKey, prefs.partGoals[i].workSetsTarget);
    }
  }
  for (let i = 0; i < PART_ORDER.length; i++) {
    const key = PART_ORDER[i];
    if (!goalByPart.has(key)) {
      continue;
    }
    progress.parts.push({
      partKey: key,
      done: doneByPart.get(key) === undefined ? 0 : doneByPart.get(key),
      target: goalByPart.get(key)
    });
  }
  return progress;
}

function averageInRange(weights, start, end) {
  let sum = 0;
  let count = 0;
  for (let i = 0; i < weights.length; i++) {
    if (weights[i].date < start || weights[i].date > end) {
      continue;
    }
    sum += weights[i].weightKg;
    count += 1;
  }
  return { count, avg: count > 0 ? sum / count : 0 };
}

export function buildWeightTrend(weights, today) {
  const summary = {
    hasWeight: false,
    latestKg: 0,
    latestDate: '',
    sparse: true,
    hasDelta: false,
    deltaKg: 0,
    referenceDate: ''
  };
  const past = [];
  for (let i = 0; i < weights.length; i++) {
    if (weights[i].date <= today) {
      past.push(weights[i]);
    }
  }
  past.sort((a, b) => {
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
  const latest = past[past.length - 1];
  summary.latestKg = latest.weightKg;
  summary.latestDate = latest.date;

  const recentStart = addDays(today, -6);
  const priorEnd = addDays(recentStart, -1);
  const priorStart = addDays(priorEnd, -6);
  const recentWin = averageInRange(past, recentStart, today);
  const priorWin = averageInRange(past, priorStart, priorEnd);
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
  const previous = past[past.length - 2];
  summary.hasDelta = true;
  summary.deltaKg = latest.weightKg - previous.weightKg;
  summary.referenceDate = previous.date;
  return summary;
}

export function datedChartPositions(points) {
  const result = [];
  const n = points.length;
  if (n === 0) {
    return result;
  }
  if (n === 1) {
    result.push({ date: points[0].date, value: points[0].value, xRatio: 0.5 });
    return result;
  }
  const firstDay = daysSinceEpoch(points[0].date);
  const lastDay = daysSinceEpoch(points[n - 1].date);
  const span = lastDay - firstDay;
  for (let i = 0; i < n; i++) {
    let xRatio;
    if (span <= 0) {
      xRatio = i / (n - 1);
    } else {
      xRatio = (daysSinceEpoch(points[i].date) - firstDay) / span;
    }
    result.push({ date: points[i].date, value: points[i].value, xRatio });
  }
  return result;
}

export function buildTrendInsight(prefs, weekGoal, lifts) {
  const insight = { kind: 'none', message: '', exerciseId: '', partKey: '', remaining: 0 };
  const hasAnyConfig = prefs.watchedExerciseIds.length > 0 || prefs.sessionsTarget !== null ||
    prefs.partGoals.length > 0;
  if (!hasAnyConfig) {
    insight.kind = 'setup';
    insight.message = '还没有设置关注动作或每周目标，先去设置一下';
    return insight;
  }

  if (weekGoal.sessionsTarget !== null) {
    const remaining = weekGoal.sessionsTarget - weekGoal.sessionsDone;
    if (remaining > 0) {
      insight.kind = 'session_goal';
      insight.remaining = remaining;
      insight.message = `本周还需训练 ${remaining} 次`;
      return insight;
    }
  }
  for (let i = 0; i < weekGoal.parts.length; i++) {
    const row = weekGoal.parts[i];
    const remaining = row.target - row.done;
    if (remaining > 0) {
      insight.kind = 'part_goal';
      insight.partKey = row.partKey;
      insight.remaining = remaining;
      return insight;
    }
  }

  for (let i = 0; i < lifts.length; i++) {
    const series = lifts[i];
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
    const series = lifts[i];
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

export function buildTrendDigest(rows, weights, today, rangeKind, prefs) {
  const digest = {
    sessions: 0,
    workSets: 0,
    lifts: [],
    weekGoal: { sessionsDone: 0, sessionsTarget: null, parts: [] },
    weightTrend: {
      hasWeight: false, latestKg: 0, latestDate: '', sparse: true, hasDelta: false, deltaKg: 0, referenceDate: ''
    },
    weightPoints: [],
    insight: { kind: 'none', message: '', exerciseId: '', partKey: '', remaining: 0 }
  };
  const summary = weekSummary(rows, today);
  digest.sessions = summary[0];
  digest.workSets = summary[1];
  digest.weekGoal = buildWeekGoalProgress(rows, today, prefs);
  digest.weightTrend = buildWeightTrend(weights, today);
  const chartFrom = chartFromDate(today, rangeKind);
  const chartRows = filterSetsFrom(rows, chartFrom, today);
  const picks = resolveWatchedLifts(chartRows, prefs.watchedExerciseIds, 3);
  for (let i = 0; i < picks.length; i++) {
    const series = buildLiftSeries(chartRows, picks[i]);
    if (series.points.length === 0) {
      continue;
    }
    digest.lifts.push(series);
  }
  digest.weightPoints = filterWeights(weights, chartFrom, today);
  digest.insight = buildTrendInsight(prefs, digest.weekGoal, digest.lifts);
  return digest;
}

export function buildExerciseTrendDetail(rows, meta) {
  const detail = {
    exerciseId: meta.exerciseId,
    name: meta.name,
    partKey: meta.partKey,
    metric: 'top_weight',
    metricLabel: '',
    points: [],
    insufficientData: false,
    secondaryLabel: '',
    secondaryPoints: [],
    sessions: 0,
    workSets: 0,
    recentSessions: []
  };
  const isCompound = isCompoundLift(meta.movementPattern, meta.partKey);
  const metric = liftMetricFor(meta.isBodyweight, isCompound);
  detail.metric = metric;
  detail.metricLabel = liftMetricLabel(metric);

  let sessions = 0;
  let workSets = 0;
  const seenDates = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
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

  const days = aggregateDays(rows, meta.exerciseId);
  for (let i = 0; i < days.length; i++) {
    const value = metricValueOf(days[i], metric);
    if (value === null) {
      continue;
    }
    detail.points.push({ date: days[i].date, value });
  }
  if (metric === 'e1rm' && detail.points.length < 2) {
    detail.insufficientData = true;
  }
  if (metric === 'top_weight') {
    detail.secondaryLabel = '同重量下的次数';
    detail.secondaryPoints = sameWeightRepsSeries(rows, meta.exerciseId);
  }
  detail.recentSessions = exerciseSessionRows(rows, meta.exerciseId, metric);
  return detail;
}

function sameWeightRepsSeries(rows, exerciseId) {
  let topWeight = null;
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (row.exerciseId !== exerciseId || !isLiftPerformancePoint(row) || row.weight === null) {
      continue;
    }
    if (topWeight === null || row.weight > topWeight) {
      topWeight = row.weight;
    }
  }
  const points = [];
  if (topWeight === null) {
    return points;
  }
  const dates = [];
  const bestReps = [];
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (row.exerciseId !== exerciseId || !isLiftPerformancePoint(row)) {
      continue;
    }
    if (row.weight === null || row.reps === null) {
      continue;
    }
    if (Math.abs(row.weight - topWeight) > 0.001) {
      continue;
    }
    const idx = dates.indexOf(row.date);
    if (idx === -1) {
      dates.push(row.date);
      bestReps.push(row.reps);
    } else if (row.reps > bestReps[idx]) {
      bestReps[idx] = row.reps;
    }
  }
  const order = dates.map((_, i) => i);
  order.sort((a, b) => {
    if (dates[a] < dates[b]) {
      return -1;
    }
    if (dates[a] > dates[b]) {
      return 1;
    }
    return 0;
  });
  for (let i = 0; i < order.length; i++) {
    points.push({ date: dates[order[i]], value: bestReps[order[i]] });
  }
  return points;
}

function exerciseSessionRows(rows, exerciseId, metric) {
  const days = aggregateDays(rows, exerciseId);
  const valueByDate = new Map();
  for (let i = 0; i < days.length; i++) {
    valueByDate.set(days[i].date, metricValueOf(days[i], metric));
  }
  const dateOrder = [];
  const workSetsByDate = new Map();
  const minRirByDate = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (row.exerciseId !== exerciseId || !isWorkSet(row)) {
      continue;
    }
    if (workSetsByDate.get(row.date) === undefined) {
      dateOrder.push(row.date);
      workSetsByDate.set(row.date, 0);
    }
    workSetsByDate.set(row.date, workSetsByDate.get(row.date) + 1);
    if (row.rir !== null) {
      const cur = minRirByDate.get(row.date);
      if (cur === undefined || row.rir < cur) {
        minRirByDate.set(row.date, row.rir);
      }
    }
  }
  dateOrder.sort((a, b) => {
    if (a < b) {
      return 1;
    }
    if (a > b) {
      return -1;
    }
    return 0;
  });
  const result = [];
  for (let i = 0; i < dateOrder.length; i++) {
    const date = dateOrder[i];
    const v = valueByDate.get(date);
    result.push({
      date,
      value: v === undefined ? null : v,
      workSets: workSetsByDate.get(date),
      minRir: minRirByDate.get(date) === undefined ? null : minRirByDate.get(date)
    });
  }
  return result;
}

function filterSetsFrom(rows, fromDate, today) {
  const result = [];
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

function filterWeights(rows, fromDate, today) {
  const points = [];
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].date > today) {
      continue;
    }
    if (fromDate.length > 0 && rows[i].date < fromDate) {
      continue;
    }
    points.push({ date: rows[i].date, value: rows[i].weightKg });
  }
  points.sort((a, b) => {
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

function collectStats(rows) {
  const list = [];
  const indexOf = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    let idx = indexOf.get(row.exerciseId);
    if (idx === undefined) {
      indexOf.set(row.exerciseId, list.length);
      list.push({
        exerciseId: row.exerciseId,
        name: row.exerciseName,
        partKey: row.partKey,
        movementPattern: row.movementPattern,
        isBodyweight: row.isBodyweight,
        sessions: 0,
        workSets: 0,
        dateSeen: new Map()
      });
      idx = list.length - 1;
    }
    const stat = list[idx];
    stat.workSets += 1;
    if (stat.dateSeen.get(row.date) !== true) {
      stat.dateSeen.set(row.date, true);
      stat.sessions += 1;
    }
  }
  return list;
}

function appendPicks(stats, picked, usedParts, usedIds, limit, compoundsOnly) {
  for (let i = 0; i < stats.length; i++) {
    if (picked.length >= limit) {
      return;
    }
    const stat = stats[i];
    if (usedIds.get(stat.exerciseId) === true) {
      continue;
    }
    if (usedParts.get(stat.partKey) === true) {
      continue;
    }
    const compound = isCompoundLift(stat.movementPattern, stat.partKey);
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

function aggregateDays(rows, exerciseId) {
  const list = [];
  const indexOf = new Map();
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (row.exerciseId !== exerciseId || !isWorkSet(row)) {
      continue;
    }
    let idx = indexOf.get(row.date);
    if (idx === undefined) {
      indexOf.set(row.date, list.length);
      list.push({
        date: row.date,
        bestE1rm: null,
        topWeight: null,
        bestReps: null
      });
      idx = list.length - 1;
    }
    const day = list[idx];
    if (!isLiftPerformancePoint(row)) {
      continue;
    }
    if (isE1rmEligible(row)) {
      const e1rm = epleyE1rm(row.weight, row.reps);
      if (e1rm !== null && (day.bestE1rm === null || e1rm > day.bestE1rm)) {
        day.bestE1rm = e1rm;
      }
    }
    if (row.weight !== null && row.weight !== undefined &&
      (day.topWeight === null || row.weight > day.topWeight)) {
      day.topWeight = row.weight;
    }
    if (row.reps !== null && row.reps !== undefined &&
      (day.bestReps === null || row.reps > day.bestReps)) {
      day.bestReps = row.reps;
    }
  }
  list.sort((a, b) => {
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
