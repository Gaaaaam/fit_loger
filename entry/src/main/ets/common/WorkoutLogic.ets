export class ParseResult {
  ok: boolean = true;
  value: number | null = null;
  error: string = '';
}

export class LegacyTagMapped {
  isWarmup: number = 0;
  technique: string = '';
}

export class WeightReps {
  weight: number | null = null;
  reps: number | null = null;
}

export class StatusChange {
  status: string = 'planned';
  completedAt: number | null = null;
}

export class BackupRetainResult {
  keep: string[] = [];
  remove: string[] = [];
}

export class LegacyExRow {
  id: number = 0;
  partId: number = 0;
  partSort: number = 0;
  exSort: number = 0;
  exerciseId: string = '';
}

export class FlatExRow {
  id: number = 0;
  exerciseId: string = '';
  sortOrder: number = 0;
}

export class GroupEx {
  id: number = 0;
  exerciseId: string = '';
  partKey: string = '';
  sortOrder: number = 0;
  name: string = '';
}

export class PartGroup {
  partKey: string = '';
  exercises: GroupEx[] = [];
}

export class HintSet {
  weight: number | null = null;
  reps: number | null = null;
}

export class CsvSetRow {
  date: string = '';
  exerciseName: string = '';
  exerciseId: string = '';
  partKey: string = '';
  weight: number | null = null;
  reps: number | null = null;
  isWarmup: number = 0;
  technique: string = '';
  rir: number | null = null;
  status: string = 'done';
  completedAt: number | null = null;
  note: string = '';
  sortOrder: number = 0;
}

export class DateStatusRow {
  date: string = '';
  status: string = '';
}

export class HistSet {
  weight: number = 0;
  reps: number = 0;
}

export function mapLegacyTag(tag: string): LegacyTagMapped {
  const mapped: LegacyTagMapped = new LegacyTagMapped();
  if (tag === 'warmup') {
    mapped.isWarmup = 1;
    mapped.technique = '';
    return mapped;
  }
  if (tag === 'drop' || tag === 'ramp') {
    mapped.isWarmup = 0;
    mapped.technique = tag;
    return mapped;
  }
  mapped.isWarmup = 0;
  mapped.technique = '';
  return mapped;
}

export function flattenDayExerciseOrder(rows: LegacyExRow[]): FlatExRow[] {
  const copy: LegacyExRow[] = [];
  for (let i = 0; i < rows.length; i++) {
    copy.push(rows[i]);
  }
  copy.sort((a: LegacyExRow, b: LegacyExRow) => {
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
  const result: FlatExRow[] = [];
  for (let i = 0; i < copy.length; i++) {
    const item: FlatExRow = new FlatExRow();
    item.id = copy[i].id;
    item.exerciseId = copy[i].exerciseId;
    item.sortOrder = i;
    result.push(item);
  }
  return result;
}

export function parseWeight(text: string): ParseResult {
  const result: ParseResult = new ParseResult();
  const trimmed: string = text.trim();
  if (trimmed.length === 0) {
    result.ok = true;
    result.value = null;
    result.error = '';
    return result;
  }
  if (trimmed === '.' || trimmed === '-' || trimmed.charAt(trimmed.length - 1) === '.') {
    result.ok = false;
    result.value = null;
    result.error = '重量无效';
    return result;
  }
  const value: number = Number(trimmed);
  if (!isFinite(value) || value < 0) {
    result.ok = false;
    result.value = null;
    result.error = '重量无效';
    return result;
  }
  result.ok = true;
  result.value = value;
  result.error = '';
  return result;
}

export function parseReps(text: string): ParseResult {
  const result: ParseResult = new ParseResult();
  const trimmed: string = text.trim();
  if (trimmed.length === 0) {
    result.ok = true;
    result.value = null;
    result.error = '';
    return result;
  }
  if (trimmed.indexOf('.') >= 0) {
    result.ok = false;
    result.value = null;
    result.error = '次数必须是整数';
    return result;
  }
  const value: number = Number(trimmed);
  if (!isFinite(value) || value < 0 || Math.floor(value) !== value) {
    result.ok = false;
    result.value = null;
    result.error = '次数无效';
    return result;
  }
  result.ok = true;
  result.value = value;
  result.error = '';
  return result;
}

export function inheritFromPreviousSet(previousInSession: WeightReps | null,
  lastSessionFirstWork: WeightReps | null): WeightReps {
  const result: WeightReps = new WeightReps();
  const previous: WeightReps | null = previousInSession;
  if (previous !== null && (previous.weight !== null || previous.reps !== null)) {
    result.weight = previous.weight;
    result.reps = previous.reps;
    return result;
  }
  const lastWork: WeightReps | null = lastSessionFirstWork;
  if (lastWork !== null && (lastWork.weight !== null || lastWork.reps !== null)) {
    result.weight = lastWork.weight;
    result.reps = lastWork.reps;
    return result;
  }
  return result;
}

export function insertIndexBySortOrder(sortOrders: number[], newSort: number): number {
  for (let i = 0; i < sortOrders.length; i++) {
    if (sortOrders[i] > newSort) {
      return i;
    }
  }
  return sortOrders.length;
}

export function statusAfterEdit(currentStatus: string, nowMs: number): StatusChange {
  const change: StatusChange = new StatusChange();
  // Editing values never completes a set or changes its completion time.
  change.status = currentStatus;
  change.completedAt = null;
  return change;
}

export function toggleSetStatus(currentStatus: string, nowMs: number): StatusChange {
  const change: StatusChange = new StatusChange();
  if (currentStatus === 'planned') {
    change.status = 'done';
    change.completedAt = nowMs;
    return change;
  }
  change.status = 'planned';
  change.completedAt = null;
  return change;
}

export function isWeightPr(weight: number | null, historicalWeights: number[], status: string): boolean {
  if (status !== 'done' || weight === null) {
    return false;
  }
  if (historicalWeights.length === 0) {
    return true;
  }
  let max: number = historicalWeights[0];
  for (let i = 1; i < historicalWeights.length; i++) {
    if (historicalWeights[i] > max) {
      max = historicalWeights[i];
    }
  }
  return weight > max;
}

export function isRepsPr(weight: number | null, reps: number | null, historical: HistSet[],
  status: string): boolean {
  if (status !== 'done' || weight === null || reps === null) {
    return false;
  }
  let maxReps: number = -1;
  let found: boolean = false;
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

export function retainBackupNames(names: string[]): BackupRetainResult {
  const filtered: string[] = [];
  for (let i = 0; i < names.length; i++) {
    if (names[i].indexOf('workout_backup_') === 0 && names[i].endsWith('.db')) {
      filtered.push(names[i]);
    }
  }
  filtered.sort();
  const result: BackupRetainResult = new BackupRetainResult();
  const keepCount: number = 5;
  if (filtered.length <= keepCount) {
    result.keep = filtered;
    return result;
  }
  for (let i = 0; i < filtered.length - keepCount; i++) {
    result.remove.push(filtered[i]);
  }
  for (let i = filtered.length - keepCount; i < filtered.length; i++) {
    result.keep.push(filtered[i]);
  }
  return result;
}

export function groupExercisesByPart(exercises: GroupEx[]): PartGroup[] {
  const groups: PartGroup[] = [];
  const indexOf: Map<string, number> = new Map();
  for (let i = 0; i < exercises.length; i++) {
    const ex: GroupEx = exercises[i];
    const existing: number | undefined = indexOf.get(ex.partKey);
    if (existing === undefined) {
      const group: PartGroup = new PartGroup();
      group.partKey = ex.partKey;
      group.exercises.push(ex);
      indexOf.set(ex.partKey, groups.length);
      groups.push(group);
    } else {
      groups[existing].exercises.push(ex);
    }
  }
  return groups;
}

export function calendarCellKey(date: string, dotKind: string): string {
  return `${date}#${dotKind}`;
}

export function dayDotKind(date: string, today: string, hasDone: boolean, hasRecord: boolean): string {
  if (hasDone) {
    return 'trained';
  }
  if (hasRecord) {
    return 'planned';
  }
  if (date < today) {
    return 'rest';
  }
  return 'empty';
}

export function datesWithDoneSets(rows: DateStatusRow[]): string[] {
  const seen: Map<string, boolean> = new Map();
  const dates: string[] = [];
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].status !== 'done') {
      continue;
    }
    const date: string = rows[i].date;
    if (seen.get(date) === true) {
      continue;
    }
    seen.set(date, true);
    dates.push(date);
  }
  return dates;
}

export function setCsvHeader(): string {
  return 'date,exercise_name,exercise_id,part_key,weight,reps,is_warmup,technique,rir,status,completed_at,note,sort_order';
}

function csvCell(value: string): string {
  if (value.indexOf(',') >= 0 || value.indexOf('"') >= 0 || value.indexOf('\n') >= 0) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

function csvNullable(value: number | null): string {
  if (value === null) {
    return '';
  }
  return `${value}`;
}

export function setToCsvRow(row: CsvSetRow): string {
  const cells: string[] = [
    csvCell(row.date),
    csvCell(row.exerciseName),
    csvCell(row.exerciseId),
    csvCell(row.partKey),
    csvNullable(row.weight),
    csvNullable(row.reps),
    `${row.isWarmup}`,
    csvCell(row.technique),
    csvNullable(row.rir),
    csvCell(row.status),
    csvNullable(row.completedAt),
    csvCell(row.note),
    `${row.sortOrder}`
  ];
  return cells.join(',');
}

export function formatLastHint(dateStr: string, sets: HintSet[]): string {
  if (dateStr.length === 0 || sets.length === 0) {
    return '';
  }
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return '';
  }
  const month: number = Number(parts[1]);
  const day: number = Number(parts[2]);
  const bits: string[] = [];
  for (let i = 0; i < sets.length; i++) {
    const wText: string = sets[i].weight === null ? '-' : `${sets[i].weight}`;
    const rText: string = sets[i].reps === null ? '-' : `${sets[i].reps}`;
    bits.push(`${wText}×${rText}`);
  }
  return `上次 ${month}月${day}日：${bits.join(' / ')}`;
}

export function customExerciseId(nowMs: number): string {
  return `usr_${nowMs}`;
}

function pad2(value: number): string {
  if (value < 10) {
    return `0${value}`;
  }
  return `${value}`;
}

export function formatBackupName(date: Date): string {
  const y: number = date.getFullYear();
  const m: string = pad2(date.getMonth() + 1);
  const d: string = pad2(date.getDate());
  const hh: string = pad2(date.getHours());
  const mm: string = pad2(date.getMinutes());
  const ss: string = pad2(date.getSeconds());
  return `workout_backup_${y}${m}${d}_${hh}${mm}${ss}.db`;
}

export function formatWeight(weight: number): string {
  if (weight === Math.floor(weight)) {
    return weight.toFixed(0);
  }
  return `${weight}`;
}
