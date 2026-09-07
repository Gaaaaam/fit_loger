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

export const PART_ORDER = [
  'chest', 'shoulder', 'back', 'arm', 'glute', 'leg', 'abs', 'core', 'cardio'
];

export function isWorkSet(row) {
  return row.status === 'done' && row.isWarmup === 0;
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
  if (!isWorkSet(row)) {
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

export function digestQueryStart(today, rangeKind) {
  const volumeFrom = addDays(isoWeekStart(today), -28);
  if (rangeKind === 'all') {
    return '';
  }
  const chartFrom = chartFromDate(today, rangeKind);
  if (chartFrom.length === 0 || chartFrom < volumeFrom) {
    return chartFrom;
  }
  return volumeFrom;
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
    return '次数';
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

export function weightDeltaText(digest) {
  if (!digest.hasWeight) {
    return '未记录';
  }
  const latest = `${formatTrendNumber(digest.weightKg)} kg`;
  if (!digest.hasDelta) {
    return latest;
  }
  if (digest.weightDelta === 0) {
    return `${latest} · 持平`;
  }
  const sign = digest.weightDelta > 0 ? '+' : '';
  return `${latest} · ${sign}${formatTrendNumber(digest.weightDelta)}`;
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
  let metric = 'top_weight';
  if (pick.isBodyweight === 1) {
    metric = 'reps';
  } else if (pick.isCompound) {
    let e1rmCount = 0;
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
    const day = days[i];
    let value = null;
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

export function partVolumeRows(rows, today) {
  const thisStart = isoWeekStart(today);
  const thisEnd = addDays(thisStart, 6);
  const histStart = addDays(thisStart, -28);
  const histEnd = addDays(thisStart, -1);
  const thisCounts = new Map();
  const histCounts = new Map();
  for (let i = 0; i < PART_ORDER.length; i++) {
    thisCounts.set(PART_ORDER[i], 0);
    histCounts.set(PART_ORDER[i], 0);
  }
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (!isWorkSet(row)) {
      continue;
    }
    if (!thisCounts.has(row.partKey)) {
      continue;
    }
    if (row.date >= thisStart && row.date <= thisEnd) {
      thisCounts.set(row.partKey, thisCounts.get(row.partKey) + 1);
    } else if (row.date >= histStart && row.date <= histEnd) {
      histCounts.set(row.partKey, histCounts.get(row.partKey) + 1);
    }
  }
  const result = [];
  for (let i = 0; i < PART_ORDER.length; i++) {
    const key = PART_ORDER[i];
    const thisWeek = thisCounts.get(key);
    const avg4 = histCounts.get(key) / 4;
    if (thisWeek === 0 && avg4 === 0) {
      continue;
    }
    result.push({ partKey: key, thisWeek, avg4 });
  }
  return result;
}

export function buildTrendDigest(rows, weights, today, rangeKind) {
  const digest = {
    sessions: 0,
    workSets: 0,
    hasWeight: false,
    weightKg: 0,
    weightDate: '',
    hasDelta: false,
    weightDelta: 0,
    lifts: [],
    parts: [],
    weights: []
  };
  const summary = weekSummary(rows, today);
  digest.sessions = summary[0];
  digest.workSets = summary[1];
  applyWeightSummary(digest, weights, today);
  const chartFrom = chartFromDate(today, rangeKind);
  const chartRows = filterSetsFrom(rows, chartFrom, today);
  const picks = pickKeyLifts(chartRows, 4);
  for (let i = 0; i < picks.length; i++) {
    const series = buildLiftSeries(chartRows, picks[i]);
    if (series.points.length === 0) {
      continue;
    }
    digest.lifts.push(series);
  }
  digest.parts = partVolumeRows(rows, today);
  digest.weights = filterWeights(weights, chartFrom, today);
  return digest;
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

function applyWeightSummary(digest, weights, today) {
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
    return;
  }
  const latest = past[past.length - 1];
  digest.hasWeight = true;
  digest.weightKg = latest.weightKg;
  digest.weightDate = latest.date;
  if (past.length < 2) {
    return;
  }
  digest.hasDelta = true;
  digest.weightDelta = latest.weightKg - past[past.length - 2].weightKg;
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
    picked.push({
      exerciseId: stat.exerciseId,
      name: stat.name,
      partKey: stat.partKey,
      movementPattern: stat.movementPattern,
      isBodyweight: stat.isBodyweight,
      isCompound: compound,
      sessions: stat.sessions,
      workSets: stat.workSets
    });
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
        totalReps: 0,
        hasReps: false
      });
      idx = list.length - 1;
    }
    const day = list[idx];
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
    if (row.reps !== null && row.reps !== undefined) {
      day.totalReps += row.reps;
      day.hasReps = true;
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
