import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { monthRange } from '../common/DateUtil';
import { BatchPlan, planBatchAdd } from '../common/MuscleLogic';
import {
  customExerciseId,
  formatLastHint,
  formatWeight,
  GroupEx,
  groupExercisesByPart,
  HintSet,
  HistSet,
  inheritFromPreviousSet,
  isRepsPr,
  isWeightPr,
  ParseResult,
  parseReps,
  parseWeight,
  PartGroup,
  WeightReps
} from '../common/WorkoutLogic';
import { ExerciseDef } from '../model/exerciseCatalog';
import { BodyMetric, DayMark, DayModel, ExerciseItem, PartItem, PrResult, RecentDayInfo, SetItem } from '../model/DayModels';
import {
  Equipment,
  PartKey,
  partName,
  toEquipment,
  toPartKey,
  toSetStatus
} from '../model/types';
import { WorkoutDatabase } from './WorkoutDatabase';
import { ExportService } from './ExportService';

export class WorkoutRepository {
  private static batchBusy: boolean = false;
  private static EMPTY_ARGS: Array<string | number> = [];

  static async listMonthDayMarks(year: number, monthIndex: number): Promise<DayMark[]> {
    const range: string[] = monthRange(year, monthIndex);
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT d.date AS date, ' +
      'MAX(CASE WHEN s.status = \'done\' THEN 1 ELSE 0 END) AS has_done, ' +
      'MAX(CASE WHEN e.id IS NOT NULL THEN 1 ELSE 0 END) AS has_record ' +
      'FROM workout_days d ' +
      'LEFT JOIN day_exercises e ON e.day_id = d.id ' +
      'LEFT JOIN workout_sets s ON s.day_exercise_id = e.id ' +
      'WHERE d.date >= ? AND d.date <= ? GROUP BY d.date ORDER BY d.date';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [range[0], range[1]]);
    const marks: DayMark[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const mark: DayMark = new DayMark();
      mark.date = rs.getString(rs.getColumnIndex('date'));
      mark.hasDone = rs.getLong(rs.getColumnIndex('has_done')) > 0;
      mark.hasRecord = rs.getLong(rs.getColumnIndex('has_record')) > 0;
      marks.push(mark);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return marks;
  }

  static async loadDay(date: string): Promise<DayModel> {
    const day: DayModel = new DayModel();
    day.date = date;
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT d.id AS day_id, e.id AS ex_row_id, e.exercise_id AS exercise_id, e.sort_order AS ex_sort, e.note AS ex_note, ' +
      'x.name AS ex_name, x.part_key AS part_key, x.weight_step AS weight_step, x.is_bodyweight AS is_bodyweight, ' +
      's.id AS set_id, s.weight AS weight, s.reps AS reps, s.is_warmup AS is_warmup, s.technique AS technique, ' +
      's.rir AS rir, s.status AS status, s.completed_at AS completed_at, s.note AS set_note, s.sort_order AS set_sort ' +
      'FROM workout_days d ' +
      'LEFT JOIN day_exercises e ON e.day_id = d.id ' +
      'LEFT JOIN exercises x ON x.id = e.exercise_id ' +
      'LEFT JOIN workout_sets s ON s.day_exercise_id = e.id ' +
      'WHERE d.date = ? ' +
      'ORDER BY e.sort_order, e.id, s.sort_order, s.id';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [date]);
    const exList: ExerciseItem[] = [];
    const exMap: Map<number, ExerciseItem> = new Map();
    let hasRow: boolean = rs.goToFirstRow();
    if (!hasRow) {
      rs.close();
      return day;
    }
    day.dayId = rs.getLong(rs.getColumnIndex('day_id'));
    while (hasRow) {
      WorkoutRepository.appendRow(exList, exMap, rs);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    day.exercises = exList;
    day.parts = WorkoutRepository.groupParts(exList);
    await WorkoutRepository.attachLastHints(day, date);
    return day;
  }

  private static appendRow(exList: ExerciseItem[], exMap: Map<number, ExerciseItem>,
    rs: relationalStore.ResultSet): void {
    if (rs.isColumnNull(rs.getColumnIndex('ex_row_id'))) {
      return;
    }
    const exId: number = rs.getLong(rs.getColumnIndex('ex_row_id'));
    let currentEx: ExerciseItem | undefined = exMap.get(exId);
    if (currentEx === undefined) {
      const createdEx: ExerciseItem = new ExerciseItem();
      createdEx.id = exId;
      createdEx.exerciseId = rs.getString(rs.getColumnIndex('exercise_id'));
      if (!rs.isColumnNull(rs.getColumnIndex('ex_name'))) {
        createdEx.name = rs.getString(rs.getColumnIndex('ex_name'));
      } else {
        createdEx.name = createdEx.exerciseId;
      }
      if (!rs.isColumnNull(rs.getColumnIndex('part_key'))) {
        createdEx.partKey = toPartKey(rs.getString(rs.getColumnIndex('part_key')));
      }
      if (!rs.isColumnNull(rs.getColumnIndex('weight_step'))) {
        createdEx.weightStep = rs.getDouble(rs.getColumnIndex('weight_step'));
      }
      if (!rs.isColumnNull(rs.getColumnIndex('is_bodyweight'))) {
        createdEx.isBodyweight = rs.getLong(rs.getColumnIndex('is_bodyweight'));
      }
      if (!rs.isColumnNull(rs.getColumnIndex('ex_sort'))) {
        createdEx.sortOrder = rs.getLong(rs.getColumnIndex('ex_sort'));
      }
      if (!rs.isColumnNull(rs.getColumnIndex('ex_note'))) {
        createdEx.note = rs.getString(rs.getColumnIndex('ex_note'));
      }
      exMap.set(exId, createdEx);
      exList.push(createdEx);
      currentEx = createdEx;
    }
    if (rs.isColumnNull(rs.getColumnIndex('set_id'))) {
      return;
    }
    currentEx.sets.push(WorkoutRepository.readSet(rs));
  }

  private static readSet(rs: relationalStore.ResultSet): SetItem {
    const setItem: SetItem = new SetItem();
    setItem.id = rs.getLong(rs.getColumnIndex('set_id'));
    if (!rs.isColumnNull(rs.getColumnIndex('weight'))) {
      setItem.weightText = formatWeight(rs.getDouble(rs.getColumnIndex('weight')));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('reps'))) {
      setItem.repsText = `${rs.getLong(rs.getColumnIndex('reps'))}`;
    }
    if (!rs.isColumnNull(rs.getColumnIndex('is_warmup'))) {
      setItem.isWarmup = rs.getLong(rs.getColumnIndex('is_warmup'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('technique'))) {
      setItem.technique = rs.getString(rs.getColumnIndex('technique'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('rir'))) {
      setItem.rir = rs.getLong(rs.getColumnIndex('rir'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('status'))) {
      setItem.status = toSetStatus(rs.getString(rs.getColumnIndex('status')));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('completed_at'))) {
      setItem.completedAt = rs.getLong(rs.getColumnIndex('completed_at'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('set_note'))) {
      setItem.note = rs.getString(rs.getColumnIndex('set_note'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('set_sort'))) {
      setItem.sortOrder = rs.getLong(rs.getColumnIndex('set_sort'));
    }
    return setItem;
  }

  private static groupParts(exList: ExerciseItem[]): PartItem[] {
    const groupsInput: GroupEx[] = [];
    for (let i = 0; i < exList.length; i++) {
      const g: GroupEx = new GroupEx();
      g.id = exList[i].id;
      g.exerciseId = exList[i].exerciseId;
      g.partKey = exList[i].partKey;
      g.sortOrder = i;
      g.name = exList[i].name;
      groupsInput.push(g);
    }
    const grouped: PartGroup[] = groupExercisesByPart(groupsInput);
    const parts: PartItem[] = [];
    for (let i = 0; i < grouped.length; i++) {
      const part: PartItem = new PartItem();
      part.partKey = toPartKey(grouped[i].partKey);
      part.name = partName(part.partKey);
      part.id = i + 1;
      for (let j = 0; j < grouped[i].exercises.length; j++) {
        const exId: number = grouped[i].exercises[j].id;
        for (let k = 0; k < exList.length; k++) {
          if (exList[k].id === exId) {
            part.exercises.push(exList[k]);
            break;
          }
        }
      }
      parts.push(part);
    }
    return parts;
  }

  private static async attachLastHints(day: DayModel, date: string): Promise<void> {
    const list: ExerciseItem[] = day.exercises.length > 0 ? day.exercises : WorkoutRepository.flattenParts(day);
    for (let i = 0; i < list.length; i++) {
      list[i].lastHint = await WorkoutRepository.lastHintFor(list[i].exerciseId, date);
    }
  }

  private static flattenParts(day: DayModel): ExerciseItem[] {
    const list: ExerciseItem[] = [];
    for (let i = 0; i < day.parts.length; i++) {
      for (let j = 0; j < day.parts[i].exercises.length; j++) {
        list.push(day.parts[i].exercises[j]);
      }
    }
    return list;
  }

  private static async lastHintFor(exerciseId: string, beforeDate: string): Promise<string> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const dateSql: string =
      'SELECT d.date AS date FROM workout_days d ' +
      'INNER JOIN day_exercises e ON e.day_id = d.id ' +
      'INNER JOIN workout_sets s ON s.day_exercise_id = e.id ' +
      'WHERE e.exercise_id = ? AND d.date < ? AND s.status = \'done\' ' +
      'ORDER BY d.date DESC LIMIT 1';
    const dateRs: relationalStore.ResultSet = await store.querySql(dateSql, [exerciseId, beforeDate]);
    if (!dateRs.goToFirstRow()) {
      dateRs.close();
      return '';
    }
    const lastDate: string = dateRs.getString(dateRs.getColumnIndex('date'));
    dateRs.close();
    const setSql: string =
      'SELECT s.weight AS weight, s.reps AS reps FROM workout_sets s ' +
      'INNER JOIN day_exercises e ON e.id = s.day_exercise_id ' +
      'INNER JOIN workout_days d ON d.id = e.day_id ' +
      'WHERE e.exercise_id = ? AND d.date = ? AND s.status = \'done\' ' +
      'ORDER BY s.sort_order, s.id';
    const setRs: relationalStore.ResultSet = await store.querySql(setSql, [exerciseId, lastDate]);
    const sets: HintSet[] = [];
    let hasRow: boolean = setRs.goToFirstRow();
    while (hasRow) {
      const hint: HintSet = new HintSet();
      if (!setRs.isColumnNull(setRs.getColumnIndex('weight'))) {
        hint.weight = setRs.getDouble(setRs.getColumnIndex('weight'));
      }
      if (!setRs.isColumnNull(setRs.getColumnIndex('reps'))) {
        hint.reps = setRs.getLong(setRs.getColumnIndex('reps'));
      }
      sets.push(hint);
      hasRow = setRs.goToNextRow();
    }
    setRs.close();
    return formatLastHint(lastDate, sets);
  }

  static async addExercise(date: string, exerciseId: string): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const dayId: number = await WorkoutRepository.ensureDayId(date);
    const order: number = await WorkoutRepository.nextOrder(
      'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM day_exercises WHERE day_id = ?',
      [dayId]
    );
    const bucket: relationalStore.ValuesBucket = {
      'day_id': dayId,
      'exercise_id': exerciseId,
      'sort_order': order
    };
    return await store.insert('day_exercises', bucket);
  }

  static async loadExerciseRow(exerciseRowId: number, date: string): Promise<ExerciseItem | null> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT e.id AS ex_row_id, e.exercise_id AS exercise_id, e.note AS ex_note, e.sort_order AS ex_sort, ' +
      'x.name AS ex_name, x.part_key AS part_key, x.weight_step AS weight_step, x.is_bodyweight AS is_bodyweight ' +
      'FROM day_exercises e LEFT JOIN exercises x ON x.id = e.exercise_id WHERE e.id = ?';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [exerciseRowId]);
    if (!rs.goToFirstRow()) {
      rs.close();
      return null;
    }
    const createdEx: ExerciseItem = new ExerciseItem();
    createdEx.id = rs.getLong(rs.getColumnIndex('ex_row_id'));
    createdEx.exerciseId = rs.getString(rs.getColumnIndex('exercise_id'));
    if (!rs.isColumnNull(rs.getColumnIndex('ex_name'))) {
      createdEx.name = rs.getString(rs.getColumnIndex('ex_name'));
    } else {
      createdEx.name = createdEx.exerciseId;
    }
    if (!rs.isColumnNull(rs.getColumnIndex('part_key'))) {
      createdEx.partKey = toPartKey(rs.getString(rs.getColumnIndex('part_key')));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('weight_step'))) {
      createdEx.weightStep = rs.getDouble(rs.getColumnIndex('weight_step'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('is_bodyweight'))) {
      createdEx.isBodyweight = rs.getLong(rs.getColumnIndex('is_bodyweight'));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('ex_sort'))) {
      createdEx.sortOrder = rs.getLong(rs.getColumnIndex('ex_sort'));
    }
    rs.close();
    createdEx.lastHint = await WorkoutRepository.lastHintFor(createdEx.exerciseId, date);
    return createdEx;
  }

  static async addSet(exerciseRowId: number): Promise<SetItem> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const order: number = await WorkoutRepository.nextOrder(
      'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM workout_sets WHERE day_exercise_id = ?',
      [exerciseRowId]
    );
    const inherited: WeightReps = await WorkoutRepository.inheritDefaults(exerciseRowId);
    const bucket: relationalStore.ValuesBucket = {
      'day_exercise_id': exerciseRowId,
      'is_warmup': 0,
      'status': 'planned',
      'sort_order': order
    };
    if (inherited.weight !== null) {
      bucket['weight'] = inherited.weight;
    }
    if (inherited.reps !== null) {
      bucket['reps'] = inherited.reps;
    }
    const id: number = await store.insert('workout_sets', bucket);
    const setItem: SetItem = new SetItem();
    setItem.id = id;
    setItem.status = 'planned';
    setItem.sortOrder = order;
    if (inherited.weight !== null) {
      setItem.weightText = formatWeight(inherited.weight);
    }
    if (inherited.reps !== null) {
      setItem.repsText = `${inherited.reps}`;
    }
    return setItem;
  }

  private static async inheritDefaults(exerciseRowId: number): Promise<WeightReps> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const prevRs: relationalStore.ResultSet = await store.querySql(
      'SELECT weight, reps FROM workout_sets WHERE day_exercise_id = ? ORDER BY sort_order DESC, id DESC LIMIT 1',
      [exerciseRowId]
    );
    let previous: WeightReps | null = null;
    if (prevRs.goToFirstRow()) {
      previous = new WeightReps();
      if (!prevRs.isColumnNull(prevRs.getColumnIndex('weight'))) {
        previous.weight = prevRs.getDouble(prevRs.getColumnIndex('weight'));
      }
      if (!prevRs.isColumnNull(prevRs.getColumnIndex('reps'))) {
        previous.reps = prevRs.getLong(prevRs.getColumnIndex('reps'));
      }
    }
    prevRs.close();
    if (previous !== null) {
      return inheritFromPreviousSet(previous, null);
    }
    const lastSql: string =
      'SELECT s.weight AS weight, s.reps AS reps FROM workout_sets s ' +
      'INNER JOIN day_exercises e ON e.id = s.day_exercise_id ' +
      'INNER JOIN workout_days d ON d.id = e.day_id ' +
      'INNER JOIN day_exercises cur ON cur.id = ? ' +
      'INNER JOIN workout_days curd ON curd.id = cur.day_id ' +
      'WHERE e.exercise_id = cur.exercise_id AND s.status = \'done\' AND s.is_warmup = 0 AND d.date < curd.date ' +
      'ORDER BY d.date DESC, s.sort_order ASC, s.id ASC LIMIT 1';
    const lastRs: relationalStore.ResultSet = await store.querySql(lastSql, [exerciseRowId]);
    let lastWork: WeightReps | null = null;
    if (lastRs.goToFirstRow()) {
      lastWork = new WeightReps();
      if (!lastRs.isColumnNull(lastRs.getColumnIndex('weight'))) {
        lastWork.weight = lastRs.getDouble(lastRs.getColumnIndex('weight'));
      }
      if (!lastRs.isColumnNull(lastRs.getColumnIndex('reps'))) {
        lastWork.reps = lastRs.getLong(lastRs.getColumnIndex('reps'));
      }
    }
    lastRs.close();
    return inheritFromPreviousSet(null, lastWork);
  }

  static async writeSet(item: SetItem): Promise<string> {
    const weightParsed: ParseResult = parseWeight(item.weightText);
    if (!weightParsed.ok) {
      return weightParsed.error;
    }
    const repsParsed: ParseResult = parseReps(item.repsText);
    if (!repsParsed.ok) {
      return repsParsed.error;
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
    predicates.equalTo('id', item.id);
    const bucket: relationalStore.ValuesBucket = {
      'is_warmup': item.isWarmup,
      'status': item.status,
      'sort_order': item.sortOrder,
      'weight': weightParsed.value,
      'reps': repsParsed.value,
      'technique': item.technique.length > 0 ? item.technique : null,
      'rir': item.rir >= 0 ? item.rir : null,
      'completed_at': item.completedAt > 0 ? item.completedAt : null,
      'note': item.note.length > 0 ? item.note : null
    };
    // Snapshot every field before awaiting: one update prevents an older autosave's
    // null-clearing pass from overwriting a newer edit during a mode switch.
    await store.update(bucket, predicates);
    return '';
  }

  static async setLastSetRir(exerciseRowId: number, rir: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM workout_sets WHERE day_exercise_id = ? ORDER BY sort_order DESC, id DESC LIMIT 1',
      [exerciseRowId]
    );
    if (!rs.goToFirstRow()) {
      rs.close();
      return;
    }
    const setId: number = rs.getLong(rs.getColumnIndex('id'));
    rs.close();
    if (rir < 0) {
      await store.executeSql('UPDATE workout_sets SET rir = NULL WHERE id = ?', [setId]);
    } else {
      await store.executeSql('UPDATE workout_sets SET rir = ? WHERE id = ?', [rir, setId]);
    }
  }

  static async deleteSet(setId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
    predicates.equalTo('id', setId);
    await store.delete(predicates);
  }

  static async insertSetCopy(exerciseRowId: number, item: SetItem): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const weightParsed: ParseResult = parseWeight(item.weightText);
    const repsParsed: ParseResult = parseReps(item.repsText);
    const bucket: relationalStore.ValuesBucket = {
      'day_exercise_id': exerciseRowId,
      'is_warmup': item.isWarmup,
      'status': item.status,
      'sort_order': item.sortOrder
    };
    if (weightParsed.ok && weightParsed.value !== null) {
      bucket['weight'] = weightParsed.value;
    }
    if (repsParsed.ok && repsParsed.value !== null) {
      bucket['reps'] = repsParsed.value;
    }
    if (item.technique.length > 0) {
      bucket['technique'] = item.technique;
    }
    if (item.rir >= 0) {
      bucket['rir'] = item.rir;
    }
    if (item.completedAt > 0) {
      bucket['completed_at'] = item.completedAt;
    }
    if (item.note.length > 0) {
      bucket['note'] = item.note;
    }
    return await store.insert('workout_sets', bucket);
  }

  static async deleteExercise(exerciseRowId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const dayRs: relationalStore.ResultSet = await store.querySql(
      'SELECT day_id FROM day_exercises WHERE id = ?',
      [exerciseRowId]
    );
    let dayId: number = 0;
    if (dayRs.goToFirstRow()) {
      dayId = dayRs.getLong(dayRs.getColumnIndex('day_id'));
    }
    dayRs.close();
    store.beginTransaction();
    try {
      const setPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
      setPred.equalTo('day_exercise_id', exerciseRowId);
      await store.delete(setPred);
      const exPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('day_exercises');
      exPred.equalTo('id', exerciseRowId);
      await store.delete(exPred);
      store.commit();
    } catch (err) {
      store.rollBack();
      WorkoutDatabase.logError('deleteExercise', err as BusinessError);
      throw new Error('deleteExercise failed');
    }
    if (dayId > 0) {
      await WorkoutRepository.cleanupEmptyDay(dayId);
    }
  }

  static async deleteExercisesOfPart(date: string, partKey: PartKey): Promise<void> {
    const day: DayModel = await WorkoutRepository.loadDay(date);
    const ids: number[] = [];
    for (let i = 0; i < day.parts.length; i++) {
      if (day.parts[i].partKey !== partKey) {
        continue;
      }
      for (let j = 0; j < day.parts[i].exercises.length; j++) {
        ids.push(day.parts[i].exercises[j].id);
      }
    }
    for (let i = 0; i < ids.length; i++) {
      await WorkoutRepository.deleteExercise(ids[i]);
    }
  }

  static async deleteDay(date: string): Promise<void> {
    const day: DayModel = await WorkoutRepository.loadDay(date);
    if (day.dayId <= 0) {
      return;
    }
    const ids: number[] = [];
    for (let i = 0; i < day.parts.length; i++) {
      for (let j = 0; j < day.parts[i].exercises.length; j++) {
        ids.push(day.parts[i].exercises[j].id);
      }
    }
    for (let i = 0; i < ids.length; i++) {
      await WorkoutRepository.deleteExercise(ids[i]);
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_days');
    predicates.equalTo('id', day.dayId);
    await store.delete(predicates);
  }

  static async listRecentDays(limit: number): Promise<RecentDayInfo[]> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT d.date AS date, COUNT(DISTINCT e.id) AS ex_count, COUNT(s.id) AS set_count ' +
      'FROM workout_days d ' +
      'INNER JOIN day_exercises e ON e.day_id = d.id ' +
      'INNER JOIN workout_sets s ON s.day_exercise_id = e.id AND s.status = \'done\' ' +
      'GROUP BY d.date ORDER BY d.date DESC LIMIT ?';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [limit]);
    const list: RecentDayInfo[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const info: RecentDayInfo = new RecentDayInfo();
      info.date = rs.getString(rs.getColumnIndex('date'));
      const exCount: number = rs.getLong(rs.getColumnIndex('ex_count'));
      const setCount: number = rs.getLong(rs.getColumnIndex('set_count'));
      info.summary = `${exCount} 个动作 · ${setCount} 组`;
      list.push(info);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return list;
  }

  static async copyDay(fromDate: string, toDate: string): Promise<void> {
    const target: DayModel = await WorkoutRepository.loadDay(toDate);
    if (target.parts.length > 0) {
      return;
    }
    const source: DayModel = await WorkoutRepository.loadDay(fromDate);
    const ordered: ExerciseItem[] = [];
    if (source.exercises.length > 0) {
      for (let i = 0; i < source.exercises.length; i++) {
        ordered.push(source.exercises[i]);
      }
    } else {
      for (let i = 0; i < source.parts.length; i++) {
        for (let j = 0; j < source.parts[i].exercises.length; j++) {
          ordered.push(source.parts[i].exercises[j]);
        }
      }
    }
    ordered.sort((a: ExerciseItem, b: ExerciseItem) => {
      return a.sortOrder - b.sortOrder;
    });
    for (let i = 0; i < ordered.length; i++) {
      const newExId: number = await WorkoutRepository.addExercise(toDate, ordered[i].exerciseId);
      for (let s = 0; s < ordered[i].sets.length; s++) {
        const copy: SetItem = new SetItem();
        copy.weightText = ordered[i].sets[s].weightText;
        copy.repsText = ordered[i].sets[s].repsText;
        copy.isWarmup = ordered[i].sets[s].isWarmup;
        copy.technique = ordered[i].sets[s].technique;
        copy.status = 'planned';
        copy.completedAt = 0;
        copy.rir = -1;
        copy.sortOrder = s;
        await WorkoutRepository.insertSetCopy(newExId, copy);
      }
    }
  }

  static async clearPlannedSets(date: string): Promise<void> {
    const day: DayModel = await WorkoutRepository.loadDay(date);
    if (day.dayId <= 0) {
      return;
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    await store.executeSql(
      'DELETE FROM workout_sets WHERE status = ? AND day_exercise_id IN (SELECT id FROM day_exercises WHERE day_id = ?)',
      ['planned', day.dayId]
    );
  }

  static async listExercises(partKey: PartKey): Promise<ExerciseDef[]> {
    return await WorkoutRepository.queryExercises(
      'SELECT id, name, part_key, equipment, movement_pattern, weight_step, is_bodyweight, is_unilateral, ' +
        'aliases, primary_muscles, secondary_muscles ' +
        'FROM exercises WHERE part_key = ? AND is_archived = 0 ORDER BY is_builtin DESC, name',
      [partKey]
    );
  }

  static async listExercisesAll(): Promise<ExerciseDef[]> {
    return await WorkoutRepository.queryExercises(
      'SELECT id, name, part_key, equipment, movement_pattern, weight_step, is_bodyweight, is_unilateral, ' +
        'aliases, primary_muscles, secondary_muscles ' +
        'FROM exercises WHERE is_archived = 0 ORDER BY is_builtin DESC, name',
      WorkoutRepository.EMPTY_ARGS
    );
  }

  static async listAddedExerciseIds(date: string): Promise<string[]> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT e.exercise_id AS exercise_id FROM workout_days d ' +
        'INNER JOIN day_exercises e ON e.day_id = d.id WHERE d.date = ? ' +
        'ORDER BY e.sort_order, e.id',
      [date]
    );
    const ids: string[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      ids.push(rs.getString(rs.getColumnIndex('exercise_id')));
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return ids;
  }

  static async addExercisesBatch(date: string, exerciseIds: string[]): Promise<number> {
    if (WorkoutRepository.batchBusy) {
      throw new Error('busy');
    }
    WorkoutRepository.batchBusy = true;
    try {
      const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
      store.beginTransaction();
      try {
        // Validate and deduplicate against the same snapshot used for insertion.
        const validIds: string[] = await WorkoutRepository.listValidExerciseIds();
        const already: string[] = await WorkoutRepository.listAddedExerciseIds(date);
        const plan: BatchPlan = planBatchAdd(exerciseIds, already, validIds);
        if (!plan.ok) {
          throw new Error(plan.error);
        }
        if (plan.toInsert.length === 0) {
          store.commit();
          return 0;
        }
        const dayId: number = await WorkoutRepository.ensureDayId(date);
        let order: number = await WorkoutRepository.nextOrder(
          'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM day_exercises WHERE day_id = ?',
          [dayId]
        );
        for (let i = 0; i < plan.toInsert.length; i++) {
          const bucket: relationalStore.ValuesBucket = {
            'day_id': dayId,
            'exercise_id': plan.toInsert[i],
            'sort_order': order
          };
          await store.insert('day_exercises', bucket);
          order++;
        }
        store.commit();
        return plan.toInsert.length;
      } catch (err) {
        store.rollBack();
        WorkoutDatabase.logError('addExercisesBatch', err as BusinessError);
        throw new Error('addExercisesBatch failed');
      }
    } finally {
      WorkoutRepository.batchBusy = false;
    }
  }

  static async createCustomExercise(name: string, partKey: PartKey, equipment: Equipment): Promise<string> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const id: string = customExerciseId(Date.now());
    const isBody: number = equipment === 'bodyweight' ? 1 : 0;
    let step: number = 2.5;
    if (equipment === 'dumbbell' || equipment === 'kettlebell') {
      step = 2;
    } else if (equipment === 'cable' || equipment === 'machine') {
      step = 5;
    } else if (equipment === 'band' || equipment === 'bodyweight') {
      step = 0;
    }
    const bucket: relationalStore.ValuesBucket = {
      'id': id,
      'name': name,
      'part_key': partKey,
      'equipment': equipment,
      'is_bodyweight': isBody,
      'weight_step': step,
      'is_builtin': 0,
      'is_archived': 0,
      'is_unilateral': 0,
      'created_at': Date.now()
    };
    await store.insert('exercises', bucket);
    return id;
  }

  static async checkPr(exerciseId: string, weight: number | null, reps: number | null,
    excludeSetId: number): Promise<PrResult> {
    const result: PrResult = new PrResult();
    if (weight === null) {
      return result;
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT s.weight AS weight, s.reps AS reps FROM workout_sets s ' +
      'INNER JOIN day_exercises e ON e.id = s.day_exercise_id ' +
      'WHERE e.exercise_id = ? AND s.status = \'done\' AND s.is_warmup = 0 AND s.id != ? AND s.weight IS NOT NULL';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [exerciseId, excludeSetId]);
    const weights: number[] = [];
    const hist: HistSet[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const w: number = rs.getDouble(rs.getColumnIndex('weight'));
      weights.push(w);
      if (!rs.isColumnNull(rs.getColumnIndex('reps'))) {
        const h: HistSet = new HistSet();
        h.weight = w;
        h.reps = rs.getLong(rs.getColumnIndex('reps'));
        hist.push(h);
      }
      hasRow = rs.goToNextRow();
    }
    rs.close();
    if (weights.length === 0) {
      return result;
    }
    result.weightPr = isWeightPr(weight, weights, 'done');
    result.repsPr = isRepsPr(weight, reps, hist, 'done');
    return result;
  }

  static async upsertBodyMetric(date: string, weightKg: number | null, note: string): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'date': date,
      'note': note,
      'created_at': Date.now()
    };
    if (weightKg !== null) {
      bucket['weight_kg'] = weightKg;
    }
    try {
      await store.insert('body_metrics', bucket);
    } catch (err) {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('body_metrics');
      predicates.equalTo('date', date);
      await store.update(bucket, predicates);
      if (weightKg === null) {
        await store.executeSql('UPDATE body_metrics SET weight_kg = NULL WHERE date = ?', [date]);
      }
    }
  }

  static async loadBodyMetric(date: string): Promise<BodyMetric> {
    const metric: BodyMetric = new BodyMetric();
    metric.date = date;
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT weight_kg, note FROM body_metrics WHERE date = ?',
      [date]
    );
    if (rs.goToFirstRow()) {
      if (!rs.isColumnNull(rs.getColumnIndex('weight_kg'))) {
        metric.weightKg = rs.getDouble(rs.getColumnIndex('weight_kg'));
        metric.hasWeight = true;
      }
      if (!rs.isColumnNull(rs.getColumnIndex('note'))) {
        metric.note = rs.getString(rs.getColumnIndex('note'));
      }
    }
    rs.close();
    return metric;
  }

  static async loadLatestBodyMetric(): Promise<BodyMetric> {
    const metric: BodyMetric = new BodyMetric();
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT date, weight_kg, note FROM body_metrics WHERE weight_kg IS NOT NULL ORDER BY date DESC LIMIT 1',
      []
    );
    if (rs.goToFirstRow()) {
      metric.date = rs.getString(rs.getColumnIndex('date'));
      metric.weightKg = rs.getDouble(rs.getColumnIndex('weight_kg'));
      metric.hasWeight = true;
      if (!rs.isColumnNull(rs.getColumnIndex('note'))) {
        metric.note = rs.getString(rs.getColumnIndex('note'));
      }
    }
    rs.close();
    return metric;
  }

  static async exportAllJson(): Promise<string> {
    return await ExportService.exportAllJson();
  }

  static async exportAllCsv(): Promise<string> {
    return await ExportService.exportAllCsv();
  }

  static async writeExportFiles(): Promise<string> {
    return await ExportService.writeExportFiles();
  }

  static async importJsonText(text: string): Promise<void> {
    await ExportService.importJsonText(text);
  }

  private static async ensureDayId(date: string): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM workout_days WHERE date = ?',
      [date]
    );
    if (rs.goToFirstRow()) {
      const id: number = rs.getLong(rs.getColumnIndex('id'));
      rs.close();
      return id;
    }
    rs.close();
    const bucket: relationalStore.ValuesBucket = {
      'date': date,
      'created_at': Date.now()
    };
    return await store.insert('workout_days', bucket);
  }

  private static async cleanupEmptyDay(dayId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM day_exercises WHERE day_id = ? LIMIT 1',
      [dayId]
    );
    const hasEx: boolean = rs.goToFirstRow();
    rs.close();
    if (!hasEx) {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_days');
      predicates.equalTo('id', dayId);
      await store.delete(predicates);
    }
  }

  private static async nextOrder(sql: string, args: Array<number | string>): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(sql, args);
    let value: number = 0;
    if (rs.goToFirstRow()) {
      value = rs.getLong(rs.getColumnIndex('next_order'));
    }
    rs.close();
    return value;
  }

  private static async listValidExerciseIds(): Promise<string[]> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM exercises WHERE is_archived = 0',
      WorkoutRepository.EMPTY_ARGS
    );
    const ids: string[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      ids.push(rs.getString(rs.getColumnIndex('id')));
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return ids;
  }

  private static async queryExercises(sql: string, args: Array<string | number>): Promise<ExerciseDef[]> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(sql, args);
    const list: ExerciseDef[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const def: ExerciseDef = {
        id: rs.getString(rs.getColumnIndex('id')),
        partKey: toPartKey(rs.getString(rs.getColumnIndex('part_key'))),
        name: rs.getString(rs.getColumnIndex('name')),
        equipment: toEquipment(WorkoutRepository.strOr(rs, 'equipment', 'other')),
        movementPattern: 'isolation',
        weightStep: rs.isColumnNull(rs.getColumnIndex('weight_step')) ? 2.5 :
          rs.getDouble(rs.getColumnIndex('weight_step')),
        isBodyweight: rs.isColumnNull(rs.getColumnIndex('is_bodyweight')) ? 0 :
          rs.getLong(rs.getColumnIndex('is_bodyweight')),
        isUnilateral: rs.isColumnNull(rs.getColumnIndex('is_unilateral')) ? 0 :
          rs.getLong(rs.getColumnIndex('is_unilateral')),
        aliases: WorkoutRepository.strOr(rs, 'aliases', ''),
        primaryMuscles: WorkoutRepository.strOr(rs, 'primary_muscles', ''),
        secondaryMuscles: WorkoutRepository.strOr(rs, 'secondary_muscles', '')
      };
      const pattern: string = WorkoutRepository.strOr(rs, 'movement_pattern', 'isolation');
      if (pattern === 'push' || pattern === 'pull' || pattern === 'hinge' || pattern === 'squat' ||
        pattern === 'lunge' || pattern === 'carry' || pattern === 'isolation') {
        def.movementPattern = pattern;
      }
      list.push(def);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return list;
  }
  private static strOr(rs: relationalStore.ResultSet, name: string, fallback: string): string {
    const idx: number = rs.getColumnIndex(name);
    if (idx < 0 || rs.isColumnNull(idx)) {
      return fallback;
    }
    return rs.getString(idx);
  }
}
