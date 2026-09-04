import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { monthRange } from '../common/DateUtil';
import { exerciseName } from '../model/exerciseCatalog';
import { DayModel, ExerciseItem, PartItem, SetItem } from '../model/DayModels';
import { PartKey, SetTag, partName, toPartKey, toSetTag } from '../model/types';
import { WorkoutDatabase } from './WorkoutDatabase';

export class WorkoutRepository {
  static async listDatesInMonth(year: number, monthIndex: number): Promise<string[]> {
    const range: string[] = monthRange(year, monthIndex);
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT DISTINCT d.date AS date FROM workout_days d ' +
      'INNER JOIN day_parts p ON p.day_id = d.id ' +
      'WHERE d.date >= ? AND d.date <= ? ORDER BY d.date';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [range[0], range[1]]);
    const dates: string[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      dates.push(rs.getString(rs.getColumnIndex('date')));
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return dates;
  }

  static async loadDay(date: string): Promise<DayModel> {
    const day: DayModel = new DayModel();
    day.date = date;
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const sql: string =
      'SELECT d.id AS day_id, p.id AS part_id, p.part_key AS part_key, ' +
      'e.id AS ex_row_id, e.exercise_id AS exercise_id, ' +
      's.id AS set_id, s.weight AS weight, s.reps AS reps, s.tag AS tag ' +
      'FROM workout_days d ' +
      'LEFT JOIN day_parts p ON p.day_id = d.id ' +
      'LEFT JOIN day_exercises e ON e.day_part_id = p.id ' +
      'LEFT JOIN workout_sets s ON s.exercise_row_id = e.id ' +
      'WHERE d.date = ? ' +
      'ORDER BY p.sort_order, p.id, e.sort_order, e.id, s.sort_order, s.id';
    const rs: relationalStore.ResultSet = await store.querySql(sql, [date]);
    const partMap: Map<number, PartItem> = new Map();
    const exMap: Map<number, ExerciseItem> = new Map();
    let hasRow: boolean = rs.goToFirstRow();
    if (!hasRow) {
      rs.close();
      return day;
    }
    day.dayId = rs.getLong(rs.getColumnIndex('day_id'));
    while (hasRow) {
      WorkoutRepository.appendRow(day, partMap, exMap, rs);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return day;
  }

  private static appendRow(day: DayModel, partMap: Map<number, PartItem>,
    exMap: Map<number, ExerciseItem>, rs: relationalStore.ResultSet): void {
    if (rs.isColumnNull(rs.getColumnIndex('part_id'))) {
      return;
    }
    const partId: number = rs.getLong(rs.getColumnIndex('part_id'));
    let currentPart: PartItem | undefined = partMap.get(partId);
    if (currentPart === undefined) {
      const created: PartItem = new PartItem();
      created.id = partId;
      created.partKey = toPartKey(rs.getString(rs.getColumnIndex('part_key')));
      created.name = partName(created.partKey);
      partMap.set(partId, created);
      day.parts.push(created);
      currentPart = created;
    }
    if (rs.isColumnNull(rs.getColumnIndex('ex_row_id'))) {
      return;
    }
    const exId: number = rs.getLong(rs.getColumnIndex('ex_row_id'));
    let currentEx: ExerciseItem | undefined = exMap.get(exId);
    if (currentEx === undefined) {
      const createdEx: ExerciseItem = new ExerciseItem();
      createdEx.id = exId;
      createdEx.exerciseId = rs.getString(rs.getColumnIndex('exercise_id'));
      createdEx.name = exerciseName(createdEx.exerciseId);
      exMap.set(exId, createdEx);
      currentPart.exercises.push(createdEx);
      currentEx = createdEx;
    }
    if (rs.isColumnNull(rs.getColumnIndex('set_id'))) {
      return;
    }
    const setItem: SetItem = new SetItem();
    setItem.id = rs.getLong(rs.getColumnIndex('set_id'));
    if (!rs.isColumnNull(rs.getColumnIndex('weight'))) {
      setItem.weightText = WorkoutRepository.formatWeight(rs.getDouble(rs.getColumnIndex('weight')));
    }
    if (!rs.isColumnNull(rs.getColumnIndex('reps'))) {
      setItem.repsText = `${rs.getLong(rs.getColumnIndex('reps'))}`;
    }
    setItem.tag = toSetTag(rs.getString(rs.getColumnIndex('tag')));
    currentEx.sets.push(setItem);
  }

  static async addPart(date: string, partKey: PartKey): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const dayId: number = await WorkoutRepository.ensureDayId(date);
    const existing: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM day_parts WHERE day_id = ? AND part_key = ?',
      [dayId, partKey]
    );
    if (existing.goToFirstRow()) {
      const id: number = existing.getLong(existing.getColumnIndex('id'));
      existing.close();
      return id;
    }
    existing.close();
    const order: number = await WorkoutRepository.nextOrder(
      'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM day_parts WHERE day_id = ?',
      [dayId]
    );
    const bucket: relationalStore.ValuesBucket = {
      'day_id': dayId,
      'part_key': partKey,
      'sort_order': order
    };
    return await store.insert('day_parts', bucket);
  }

  static async addExercise(partId: number, exerciseId: string): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const order: number = await WorkoutRepository.nextOrder(
      'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM day_exercises WHERE day_part_id = ?',
      [partId]
    );
    const bucket: relationalStore.ValuesBucket = {
      'day_part_id': partId,
      'exercise_id': exerciseId,
      'sort_order': order
    };
    return await store.insert('day_exercises', bucket);
  }

  static async addSet(exerciseRowId: number): Promise<number> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const order: number = await WorkoutRepository.nextOrder(
      'SELECT IFNULL(MAX(sort_order), -1) + 1 AS next_order FROM workout_sets WHERE exercise_row_id = ?',
      [exerciseRowId]
    );
    const bucket: relationalStore.ValuesBucket = {
      'exercise_row_id': exerciseRowId,
      'tag': 'working',
      'sort_order': order
    };
    return await store.insert('workout_sets', bucket);
  }

  static async updateSet(setId: number, weightText: string, repsText: string, tag: SetTag): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const weightSql: string = WorkoutRepository.weightSqlValue(weightText);
    const repsSql: string = WorkoutRepository.repsSqlValue(repsText);
    await store.executeSql(
      `UPDATE workout_sets SET weight = ${weightSql}, reps = ${repsSql}, tag = ? WHERE id = ?`,
      [tag, setId]
    );
  }

  static async deleteSet(setId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
    predicates.equalTo('id', setId);
    await store.delete(predicates);
  }

  static async deleteExercise(exerciseRowId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    store.beginTransaction();
    try {
      const setPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
      setPred.equalTo('exercise_row_id', exerciseRowId);
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
  }

  static async deletePart(partId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const dayRs: relationalStore.ResultSet = await store.querySql(
      'SELECT day_id FROM day_parts WHERE id = ?',
      [partId]
    );
    let dayId: number = 0;
    if (dayRs.goToFirstRow()) {
      dayId = dayRs.getLong(dayRs.getColumnIndex('day_id'));
    }
    dayRs.close();
    const exRs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM day_exercises WHERE day_part_id = ?',
      [partId]
    );
    const exerciseIds: number[] = [];
    let hasRow: boolean = exRs.goToFirstRow();
    while (hasRow) {
      exerciseIds.push(exRs.getLong(exRs.getColumnIndex('id')));
      hasRow = exRs.goToNextRow();
    }
    exRs.close();
    store.beginTransaction();
    try {
      for (let i = 0; i < exerciseIds.length; i++) {
        const setPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_sets');
        setPred.equalTo('exercise_row_id', exerciseIds[i]);
        await store.delete(setPred);
      }
      const exPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('day_exercises');
      exPred.equalTo('day_part_id', partId);
      await store.delete(exPred);
      const partPred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('day_parts');
      partPred.equalTo('id', partId);
      await store.delete(partPred);
      store.commit();
    } catch (err) {
      store.rollBack();
      WorkoutDatabase.logError('deletePart', err as BusinessError);
      throw new Error('deletePart failed');
    }
    if (dayId > 0) {
      await WorkoutRepository.cleanupEmptyDay(dayId);
    }
  }

  static async deleteDay(date: string): Promise<void> {
    const day: DayModel = await WorkoutRepository.loadDay(date);
    if (day.dayId <= 0) {
      return;
    }
    const partIds: number[] = [];
    for (let i = 0; i < day.parts.length; i++) {
      partIds.push(day.parts[i].id);
    }
    for (let i = 0; i < partIds.length; i++) {
      await WorkoutRepository.deletePart(partIds[i]);
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('workout_days');
    predicates.equalTo('id', day.dayId);
    await store.delete(predicates);
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
      'date': date
    };
    return await store.insert('workout_days', bucket);
  }

  private static async cleanupEmptyDay(dayId: number): Promise<void> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT id FROM day_parts WHERE day_id = ? LIMIT 1',
      [dayId]
    );
    const hasPart: boolean = rs.goToFirstRow();
    rs.close();
    if (!hasPart) {
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

  private static formatWeight(weight: number): string {
    if (weight === Math.floor(weight)) {
      return weight.toFixed(0);
    }
    return `${weight}`;
  }

  private static weightSqlValue(text: string): string {
    const trimmed: string = text.trim();
    if (trimmed.length === 0) {
      return 'NULL';
    }
    const value: number = Number(trimmed);
    if (!isFinite(value) || value < 0) {
      return 'NULL';
    }
    return `${value}`;
  }

  private static repsSqlValue(text: string): string {
    const trimmed: string = text.trim();
    if (trimmed.length === 0) {
      return 'NULL';
    }
    const value: number = Number(trimmed);
    if (!isFinite(value) || value < 0) {
      return 'NULL';
    }
    return `${Math.floor(value)}`;
  }
}
