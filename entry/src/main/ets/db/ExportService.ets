import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { CsvSetRow, setCsvHeader, setToCsvRow } from '../common/WorkoutLogic';
import { seedBuiltinExercises } from './ExerciseSeed';
import { WorkoutDatabase } from './WorkoutDatabase';

class JsonDump {
  version: number = 1;
  exportedAt: number = 0;
  exercises: relationalStore.ValuesBucket[] = [];
  workout_days: relationalStore.ValuesBucket[] = [];
  day_exercises: relationalStore.ValuesBucket[] = [];
  workout_sets: relationalStore.ValuesBucket[] = [];
  body_metrics: relationalStore.ValuesBucket[] = [];
}

export class ExportService {
  static async exportAllJson(): Promise<string> {
    const dump: JsonDump = new JsonDump();
    dump.exportedAt = Date.now();
    dump.exercises = await ExportService.readBuckets(
      'SELECT id, name, aliases, part_key, primary_muscles, secondary_muscles, movement_pattern, equipment, ' +
        'is_unilateral, is_bodyweight, weight_step, is_builtin, is_archived, created_at FROM exercises',
      ['id', 'name', 'aliases', 'part_key', 'primary_muscles', 'secondary_muscles', 'movement_pattern',
        'equipment', 'is_unilateral', 'is_bodyweight', 'weight_step', 'is_builtin', 'is_archived', 'created_at']
    );
    dump.workout_days = await ExportService.readBuckets(
      'SELECT id, date, note, created_at FROM workout_days',
      ['id', 'date', 'note', 'created_at']
    );
    dump.day_exercises = await ExportService.readBuckets(
      'SELECT id, day_id, exercise_id, sort_order, note FROM day_exercises',
      ['id', 'day_id', 'exercise_id', 'sort_order', 'note']
    );
    dump.workout_sets = await ExportService.readBuckets(
      'SELECT id, day_exercise_id, weight, reps, is_warmup, technique, rir, status, completed_at, note, sort_order FROM workout_sets',
      ['id', 'day_exercise_id', 'weight', 'reps', 'is_warmup', 'technique', 'rir', 'status', 'completed_at', 'note',
        'sort_order']
    );
    dump.body_metrics = await ExportService.readBuckets(
      'SELECT date, weight_kg, note, created_at FROM body_metrics',
      ['date', 'weight_kg', 'note', 'created_at']
    );
    return JSON.stringify(dump);
  }

  static async exportAllCsv(): Promise<string> {
    const sql: string =
      'SELECT d.date AS date, x.name AS exercise_name, e.exercise_id AS exercise_id, x.part_key AS part_key, ' +
      's.weight AS weight, s.reps AS reps, s.is_warmup AS is_warmup, s.technique AS technique, ' +
      's.rir AS rir, s.status AS status, s.completed_at AS completed_at, s.note AS note, s.sort_order AS sort_order ' +
      'FROM workout_sets s ' +
      'INNER JOIN day_exercises e ON e.id = s.day_exercise_id ' +
      'INNER JOIN workout_days d ON d.id = e.day_id ' +
      'LEFT JOIN exercises x ON x.id = e.exercise_id ' +
      'ORDER BY d.date, e.sort_order, e.id, s.sort_order, s.id';
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(sql, []);
    const lines: string[] = [setCsvHeader()];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const row: CsvSetRow = new CsvSetRow();
      row.date = ExportService.strCol(rs, 'date');
      row.exerciseName = ExportService.strCol(rs, 'exercise_name');
      row.exerciseId = ExportService.strCol(rs, 'exercise_id');
      row.partKey = ExportService.strCol(rs, 'part_key');
      row.weight = ExportService.numCol(rs, 'weight');
      row.reps = ExportService.intCol(rs, 'reps');
      const warmup: number | null = ExportService.intCol(rs, 'is_warmup');
      row.isWarmup = warmup === null ? 0 : warmup;
      row.technique = ExportService.strCol(rs, 'technique');
      row.rir = ExportService.intCol(rs, 'rir');
      row.status = ExportService.strCol(rs, 'status');
      row.completedAt = ExportService.intCol(rs, 'completed_at');
      row.note = ExportService.strCol(rs, 'note');
      const sortOrder: number | null = ExportService.intCol(rs, 'sort_order');
      row.sortOrder = sortOrder === null ? 0 : sortOrder;
      lines.push(setToCsvRow(row));
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return lines.join('\n');
  }

  static async writeExportFiles(): Promise<string> {
    const context = WorkoutDatabase.getContext();
    const dir: string = context.filesDir;
    const jsonPath: string = `${dir}/fitloger_export.json`;
    const csvPath: string = `${dir}/fitloger_export.csv`;
    ExportService.writeText(jsonPath, await ExportService.exportAllJson());
    ExportService.writeText(csvPath, await ExportService.exportAllCsv());
    return jsonPath;
  }

  static async importJsonText(text: string): Promise<void> {
    const dump: JsonDump = JSON.parse(text) as JsonDump;
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    store.beginTransaction();
    try {
      await ExportService.replaceTable(store, 'workout_sets', dump.workout_sets);
      await ExportService.replaceTable(store, 'day_exercises', dump.day_exercises);
      await ExportService.replaceTable(store, 'workout_days', dump.workout_days);
      await ExportService.replaceTable(store, 'body_metrics', dump.body_metrics);
      await ExportService.replaceTable(store, 'exercises', dump.exercises);
      await seedBuiltinExercises(store);
      store.commit();
    } catch (err) {
      store.rollBack();
      throw new Error('importJsonText failed');
    }
  }

  private static async readBuckets(sql: string, cols: string[]): Promise<relationalStore.ValuesBucket[]> {
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    const rs: relationalStore.ResultSet = await store.querySql(sql, []);
    const rows: relationalStore.ValuesBucket[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const bucket: relationalStore.ValuesBucket = {};
      for (let i = 0; i < cols.length; i++) {
        const name: string = cols[i];
        const idx: number = rs.getColumnIndex(name);
        if (idx < 0 || rs.isColumnNull(idx)) {
          continue;
        }
        try {
          bucket[name] = rs.getString(idx);
        } catch (err) {
          try {
            bucket[name] = rs.getLong(idx);
          } catch (err2) {
            bucket[name] = rs.getDouble(idx);
          }
        }
      }
      rows.push(bucket);
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return rows;
  }

  private static async replaceTable(store: relationalStore.RdbStore, table: string,
    rows: relationalStore.ValuesBucket[]): Promise<void> {
    if (rows === undefined || rows === null) {
      return;
    }
    if (table === 'exercises' && rows.length === 0) {
      return;
    }
    await store.executeSql(`DELETE FROM ${table}`, []);
    for (let i = 0; i < rows.length; i++) {
      await store.insert(table, rows[i]);
    }
  }

  private static writeText(path: string, text: string): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, text);
    fileIo.closeSync(file);
  }

  private static strCol(rs: relationalStore.ResultSet, name: string): string {
    const idx: number = rs.getColumnIndex(name);
    if (idx < 0 || rs.isColumnNull(idx)) {
      return '';
    }
    return rs.getString(idx);
  }

  private static numCol(rs: relationalStore.ResultSet, name: string): number | null {
    const idx: number = rs.getColumnIndex(name);
    if (idx < 0 || rs.isColumnNull(idx)) {
      return null;
    }
    return rs.getDouble(idx);
  }

  private static intCol(rs: relationalStore.ResultSet, name: string): number | null {
    const idx: number = rs.getColumnIndex(name);
    if (idx < 0 || rs.isColumnNull(idx)) {
      return null;
    }
    return rs.getLong(idx);
  }
}
