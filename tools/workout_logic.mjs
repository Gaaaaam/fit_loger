export function mapLegacyTag(tag) {
  if (tag === 'warmup') {
    return { isWarmup: 1, technique: null };
  }
  if (tag === 'drop' || tag === 'ramp') {
    return { isWarmup: 0, technique: tag };
  }
  return { isWarmup: 0, technique: null };
}

export function flattenDayExerciseOrder(rows) {
  const copy = rows.slice();
  copy.sort((a, b) => {
    if (a.partSort !== b.partSort) {
      return a.partSort - b.partSort;
    }
    if (a.partId !== b.partId) {
      return a.partId - b.partId;
    }
    if (a.exSort !== b.exSort) {
      return a.exSort - b.exSort;
    }
    return a.id - b.id;
  });
  const result = [];
  for (let i = 0; i < copy.length; i++) {
    result.push({
      id: copy[i].id,
      exerciseId: copy[i].exerciseId,
      sortOrder: i
    });
  }
  return result;
}

export function parseWeight(text) {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { ok: true, value: null, error: '' };
  }
  if (trimmed === '.' || trimmed === '-' || trimmed.charAt(trimmed.length - 1) === '.') {
    return { ok: false, value: null, error: '重量无效' };
  }
  const value = Number(trimmed);
  if (!isFinite(value) || value < 0) {
    return { ok: false, value: null, error: '重量无效' };
  }
  return { ok: true, value: value, error: '' };
}

export function parseReps(text) {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return { ok: true, value: null, error: '' };
  }
  if (trimmed.indexOf('.') >= 0) {
    return { ok: false, value: null, error: '次数必须是整数' };
  }
  const value = Number(trimmed);
  if (!isFinite(value) || value < 0 || Math.floor(value) !== value) {
    return { ok: false, value: null, error: '次数无效' };
  }
  return { ok: true, value: value, error: '' };
}

function hasInheritValues(set) {
  return set !== null && (set.weight !== null || set.reps !== null);
}

export function inheritFromPreviousSet(previousInSession, lastSessionFirstWork) {
  if (hasInheritValues(previousInSession)) {
    return { weight: previousInSession.weight, reps: previousInSession.reps };
  }
  if (hasInheritValues(lastSessionFirstWork)) {
    return { weight: lastSessionFirstWork.weight, reps: lastSessionFirstWork.reps };
  }
  return { weight: null, reps: null };
}

export function insertIndexBySortOrder(sortOrders, newSort) {
  for (let i = 0; i < sortOrders.length; i++) {
    if (sortOrders[i] > newSort) {
      return i;
    }
  }
  return sortOrders.length;
}

export function statusAfterEdit(currentStatus, nowMs) {
  return { status: currentStatus, completedAt: null };
}

export function toggleSetStatus(currentStatus, nowMs) {
  if (currentStatus === 'planned') {
    return { status: 'done', completedAt: nowMs };
  }
  return { status: 'planned', completedAt: null };
}

export function isWeightPr(weight, historicalWeights, status) {
  if (status !== 'done' || weight === null || weight === undefined) {
    return false;
  }
  if (historicalWeights.length === 0) {
    return true;
  }
  let max = historicalWeights[0];
  for (let i = 1; i < historicalWeights.length; i++) {
    if (historicalWeights[i] > max) {
      max = historicalWeights[i];
    }
  }
  return weight > max;
}

export function isRepsPr(weight, reps, historical, status) {
  if (status !== 'done' || weight === null || reps === null || weight === undefined || reps === undefined) {
    return false;
  }
  let maxReps = -1;
  let found = false;
  for (let i = 0; i < historical.length; i++) {
    if (historical[i].weight === weight) {
      found = true;
      if (historical[i].reps > maxReps) {
        maxReps = historical[i].reps;
      }
    }
  }
  if (!found) {
    return true;
  }
  return reps > maxReps;
}

export function retainBackupNames(names) {
  const filtered = names.filter((n) => n.indexOf('workout_backup_') === 0 && n.endsWith('.db'));
  filtered.sort();
  const keepCount = 5;
  if (filtered.length <= keepCount) {
    return { keep: filtered, remove: [] };
  }
  const remove = filtered.slice(0, filtered.length - keepCount);
  const keep = filtered.slice(filtered.length - keepCount);
  return { keep, remove };
}

export function formatBackupName(date) {
  const y = date.getFullYear();
  const m = pad2(date.getMonth() + 1);
  const d = pad2(date.getDate());
  const hh = pad2(date.getHours());
  const mm = pad2(date.getMinutes());
  const ss = pad2(date.getSeconds());
  return `workout_backup_${y}${m}${d}_${hh}${mm}${ss}.db`;
}

export function groupExercisesByPart(exercises) {
  const groups = [];
  const indexOf = {};
  for (let i = 0; i < exercises.length; i++) {
    const ex = exercises[i];
    const existing = indexOf[ex.partKey];
    if (existing === undefined) {
      indexOf[ex.partKey] = groups.length;
      groups.push({ partKey: ex.partKey, exercises: [ex] });
    } else {
      groups[existing].exercises.push(ex);
    }
  }
  return groups;
}

export function calendarCellKey(date, dotKind) {
  return `${date}#${dotKind}`;
}

export function dayDotKind(date, today, hasDone, hasRecord) {
  if (hasDone) {
    return 'trained';
  }
  if (hasRecord) {
    if (date < today) {
      return 'missed';
    }
    return 'planned';
  }
  if (date < today) {
    return 'rest';
  }
  return 'empty';
}

export function datesWithDoneSets(rows) {
  const seen = {};
  const dates = [];
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].status !== 'done') {
      continue;
    }
    const date = rows[i].date;
    if (seen[date]) {
      continue;
    }
    seen[date] = true;
    dates.push(date);
  }
  return dates;
}

export function setCsvHeader() {
  return [
    'date',
    'exercise_name',
    'exercise_id',
    'part_key',
    'weight',
    'reps',
    'is_warmup',
    'technique',
    'rir',
    'status',
    'completed_at',
    'note',
    'sort_order'
  ].join(',');
}

function csvCell(value) {
  if (value === null || value === undefined) {
    return '';
  }
  const text = `${value}`;
  if (text.indexOf(',') >= 0 || text.indexOf('"') >= 0 || text.indexOf('\n') >= 0) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

export function setToCsvRow(row) {
  return [
    csvCell(row.date),
    csvCell(row.exerciseName),
    csvCell(row.exerciseId),
    csvCell(row.partKey),
    csvCell(row.weight),
    csvCell(row.reps),
    csvCell(row.isWarmup),
    csvCell(row.technique),
    csvCell(row.rir),
    csvCell(row.status),
    csvCell(row.completedAt),
    csvCell(row.note),
    csvCell(row.sortOrder)
  ].join(',');
}

export function formatLastHint(dateStr, sets) {
  if (!dateStr || sets.length === 0) {
    return '';
  }
  const parts = dateStr.split('-');
  if (parts.length !== 3) {
    return '';
  }
  const month = Number(parts[1]);
  const day = Number(parts[2]);
  const bits = [];
  for (let i = 0; i < sets.length; i++) {
    const w = sets[i].weight;
    const r = sets[i].reps;
    const wText = w === null || w === undefined ? '-' : `${w}`;
    const rText = r === null || r === undefined ? '-' : `${r}`;
    bits.push(`${wText}×${rText}`);
  }
  return `上次 ${month}月${day}日：${bits.join(' / ')}`;
}

function isHintWorkSet(set) {
  return set.isWarmup !== 1;
}

export function bestHintWorkSet(sets) {
  let best = null;
  for (let i = 0; i < sets.length; i++) {
    const set = sets[i];
    if (!isHintWorkSet(set) || set.weight === null || set.weight === undefined) {
      continue;
    }
    if (best === null || best.weight === null || best.weight === undefined) {
      best = set;
      continue;
    }
    if (set.weight > best.weight) {
      best = set;
      continue;
    }
    if (set.weight === best.weight && set.reps != null && (best.reps == null || set.reps > best.reps)) {
      best = set;
    }
  }
  return best;
}

function formatDeltaNumber(value) {
  const rounded = Math.round(value * 10) / 10;
  if (rounded === Math.floor(rounded)) {
    return `${Math.floor(rounded)}`;
  }
  return `${rounded}`;
}

export function vsLastProgressText(weight, reps, lastSets) {
  if (weight === null || weight === undefined) {
    return '';
  }
  const last = bestHintWorkSet(lastSets);
  if (last === null || last.weight === null || last.weight === undefined) {
    return '';
  }
  if (weight !== last.weight) {
    const delta = weight - last.weight;
    const shown = delta > 0 ? `+${formatDeltaNumber(delta)}` : formatDeltaNumber(delta);
    return `比上次 ${shown} kg`;
  }
  if (reps === null || reps === undefined || last.reps === null || last.reps === undefined) {
    return '与上次持平';
  }
  if (reps === last.reps) {
    return '与上次持平';
  }
  const deltaReps = reps - last.reps;
  const shownReps = deltaReps > 0 ? `+${deltaReps}` : `${deltaReps}`;
  return `比上次 ${shownReps} 次`;
}

export function vsLastCardText(currentSets, lastSets) {
  const current = bestHintWorkSet(currentSets);
  if (current === null) {
    return '';
  }
  return vsLastProgressText(current.weight, current.reps, lastSets);
}

export function customExerciseId(nowMs) {
  return `usr_${nowMs}`;
}

function pad2(value) {
  if (value < 10) {
    return `0${value}`;
  }
  return `${value}`;
}
