import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { CsvSetRow, rirLegacyForImport, setCsvHeader, setToCsvRow } from '../common/WorkoutLogic';
import { CardioMetrics } from '../model/CardioModels';
import { ExerciseDef, findExercise } from '../model/exerciseCatalog';
import { toRecordType } from '../model/types';
import { validateCardioMetrics } from '../common/CardioLogic';
import { CARDIO_COLUMNS, CARDIO_SELECT, readCardioMetrics } from './CardioStorage';
import { seedBuiltinExercises } from './ExerciseSeed';
import { WorkoutDatabase } from './WorkoutDatabase';

class JsonDump {
  version: number = 4;
  exportedAt: number = 0;
  exercises: relationalStore.ValuesBucket[] = [];
  workout_days: relationalStore.ValuesBucket[] = [];
  day_exercises: relationalStore.ValuesBucket[] = [];
  workout_sets: relationalStore.ValuesBucket[] = [];
  body_metrics: relationalStore.ValuesBucket[] = [];
  watched_exercises: relationalStore.ValuesBucket[] = [];
  trend_settings: relationalStore.ValuesBucket[] = [];
  trend_part_goals: relationalStore.ValuesBucket[] = [];
}

export class ExportService {
  static async exportAllJson(): Promise<string> {
    const dump: JsonDump = new JsonDump();
    dump.exportedAt = Date.now();
    dump.exercises = await ExportService.readBuckets(
      'SELECT id, name, aliases, part_key, primary_muscles, secondary_muscles, movement_pattern, equipment, ' +
        'is_unilateral, is_bodyweight, weight_step, is_builtin, is_archived, created_at, record_type FROM exercises',
      ['id', 'name', 'aliases', 'part_key', 'primary_muscles', 'secondary_muscles', 'movement_pattern',
        'equipment', 'is_unilateral', 'is_bodyweight', 'weight_step', 'is_builtin', 'is_archived', 'created_at', 'record_type']
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
      'SELECT id, day_exercise_id, weight, reps, is_warmup, technique, rir, rir_legacy, status, completed_at, note, sort_order, ' +
        CARDIO_COLUMNS.join(', ') + ' FROM workout_sets',
      ['id', 'day_exercise_id', 'weight', 'reps', 'is_warmup', 'technique', 'rir', 'rir_legacy', 'status',
        'completed_at', 'note', 'sort_order'].concat(CARDIO_COLUMNS)
    );
    dump.body_metrics = await ExportService.readBuckets(
      'SELECT date, weight_kg, note, created_at FROM body_metrics',
      ['date', 'weight_kg', 'note', 'created_at']
    );
    dump.watched_exercises = await ExportService.readBuckets(
      'SELECT exercise_id, sort_order, created_at FROM watched_exercises',
      ['exercise_id', 'sort_order', 'created_at']
    );
    dump.trend_settings = await ExportService.readBuckets(
      'SELECT id, sessions_target, updated_at FROM trend_settings',
      ['id', 'sessions_target', 'updated_at']
    );
    dump.trend_part_goals = await ExportService.readBuckets(
      'SELECT part_key, work_sets_target, updated_at FROM trend_part_goals',
      ['part_key', 'work_sets_target', 'updated_at']
    );
    return JSON.stringify(dump);
  }

  static async exportAllCsv(): Promise<string> {
    const sql: string =
      'SELECT d.date AS date, x.name AS exercise_name, e.exercise_id AS exercise_id, x.part_key AS part_key, ' +
      's.weight AS weight, s.reps AS reps, s.is_warmup AS is_warmup, s.technique AS technique, ' +
      's.rir AS rir, s.rir_legacy AS rir_legacy, s.status AS status, s.completed_at AS completed_at, s.note AS note, s.sort_order AS sort_order, ' +
      'x.record_type AS record_type, ' + CARDIO_SELECT + ' ' +
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
      row.recordType = toRecordType(ExportService.strCol(rs, 'record_type'));
      const metrics: CardioMetrics = readCardioMetrics(rs);
      row.durationSec = metrics.durationSec;
      row.distanceM = metrics.distanceM;
      row.speedKmh = metrics.speedKmh;
      row.inclinePct = metrics.inclinePct;
      row.level = metrics.level;
      row.steps = metrics.steps;
      row.floors = metrics.floors;
      row.cadencePerMin = metrics.cadencePerMin;
      row.avgPowerW = metrics.avgPowerW;
      row.avgHeartRateBpm = metrics.avgHeartRateBpm;
      row.energyKcal = metrics.energyKcal;
      row.weight = ExportService.numCol(rs, 'weight');
      row.reps = ExportService.intCol(rs, 'reps');
      const warmup: number | null = ExportService.intCol(rs, 'is_warmup');
      row.isWarmup = warmup === null ? 0 : warmup;
      row.technique = ExportService.strCol(rs, 'technique');
      row.rir = ExportService.intCol(rs, 'rir');
      const legacy: number | null = ExportService.intCol(rs, 'rir_legacy');
      row.rirLegacy = legacy === null ? 0 : legacy;
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
    if (dump.version > 4) {
      throw new Error('不支持更新版本的备份');
    }
    ExportService.normalizeImportedSets(dump);
    if (dump.exercises !== undefined && dump.exercises !== null) {
      for (let i = 0; i < dump.exercises.length; i++) {
        const value: relationalStore.ValueType = dump.exercises[i]['record_type'];
        dump.exercises[i]['record_type'] = toRecordType(typeof value === 'string' ? value : 'reps');
      }
    }
    const store: relationalStore.RdbStore = WorkoutDatabase.getStore();
    store.beginTransaction();
    try {
      await ExportService.replaceTable(store, 'workout_sets', dump.workout_sets);
      await ExportService.replaceTable(store, 'day_exercises', dump.day_exercises);
      await ExportService.replaceTable(store, 'workout_days', dump.workout_days);
      await ExportService.replaceTable(store, 'body_metrics', dump.body_metrics);
      await ExportService.replaceTable(store, 'exercises', dump.exercises);
      await seedBuiltinExercises(store);
      // v1 导出的 JSON 没有这三张表，字段在解析后是 undefined，
      // replaceTable 会直接跳过，保留本机现有的趋势配置，视为空配置兼容。
      await ExportService.replaceTable(store, 'watched_exercises', dump.watched_exercises);
      await ExportService.replaceTable(store, 'trend_settings', dump.trend_settings);
      await ExportService.replaceTable(store, 'trend_part_goals', dump.trend_part_goals);
      store.commit();
    } catch (err) {
      store.rollBack();
      throw new Error('importJsonText failed');
    }
  }

  private static normalizeImportedSets(dump: JsonDump): void {
    if (dump.workout_sets === undefined || dump.workout_sets === null) {
      return;
    }
    const version: number = dump.version > 0 ? dump.version : 2;
    const exerciseTypes: Map<string, string> = new Map();
    if (dump.exercises !== undefined && dump.exercises !== null) {
      for (let i = 0; i < dump.exercises.length; i++) {
        const exercise: relationalStore.ValuesBucket = dump.exercises[i];
        const id: relationalStore.ValueType = exercise['id'];
        const type: relationalStore.ValueType = exercise['record_type'];
        if (typeof id === 'string') {
          exerciseTypes.set(id, toRecordType(typeof type === 'string' ? type : 'reps'));
        }
      }
    }
    const dayExerciseTypes: Map<number, string> = new Map();
    if (dump.day_exercises !== undefined && dump.day_exercises !== null) {
      for (let i = 0; i < dump.day_exercises.length; i++) {
        const dayExercise: relationalStore.ValuesBucket = dump.day_exercises[i];
        const id: number | null = ExportService.bucketNumber(dayExercise, 'id');
        const exerciseId: relationalStore.ValueType = dayExercise['exercise_id'];
        if (id !== null && typeof exerciseId === 'string') {
          // Seeding restores canonical built-in types after import, so apply
          // those same types now even when an imported type is missing/wrong.
          const builtin: ExerciseDef | null = findExercise(exerciseId);
          const type: string | undefined = exerciseTypes.get(exerciseId);
          dayExerciseTypes.set(id, builtin !== null ? builtin.recordType : (type === undefined ? 'reps' : type));
        }
      }
    }
    for (let i = 0; i < dump.workout_sets.length; i++) {
      const row: relationalStore.ValuesBucket = dump.workout_sets[i];
      const rir: number | null = ExportService.bucketNumber(row, 'rir');
      const stored: number | null = ExportService.bucketNumber(row, 'rir_legacy');
      row['rir_legacy'] = rirLegacyForImport(version, rir, stored);
      for (let c = 0; c < CARDIO_COLUMNS.length; c++) {
        const key: string = CARDIO_COLUMNS[c];
        const raw: relationalStore.ValueType = row[key];
        if (raw === undefined || raw === null) {
          row[key] = null;
        } else {
          const metric: number | null = ExportService.bucketNumber(row, key);
          if (metric === null || !Number.isFinite(metric)) {
            throw new Error(`无效的心肺数据：${key}`);
          }
          row[key] = metric;
        }
      }
      const metrics: CardioMetrics = new CardioMetrics();
      metrics.durationSec = ExportService.bucketNumber(row, 'duration_sec');
      metrics.distanceM = ExportService.bucketNumber(row, 'distance_m');
      metrics.speedKmh = ExportService.bucketNumber(row, 'speed_kmh');
      metrics.inclinePct = ExportService.bucketNumber(row, 'incline_pct');
      metrics.level = ExportService.bucketNumber(row, 'level');
      metrics.steps = ExportService.bucketNumber(row, 'steps');
      metrics.floors = ExportService.bucketNumber(row, 'floors');
      metrics.cadencePerMin = ExportService.bucketNumber(row, 'cadence_per_min');
      metrics.avgPowerW = ExportService.bucketNumber(row, 'avg_power_w');
      metrics.avgHeartRateBpm = ExportService.bucketNumber(row, 'avg_heart_rate_bpm');
      metrics.energyKcal = ExportService.bucketNumber(row, 'energy_kcal');
      const exerciseRowId: number | null = ExportService.bucketNumber(row, 'day_exercise_id');
      const isCardio: boolean = exerciseRowId !== null && dayExerciseTypes.get(exerciseRowId) === 'cardio';
      const requireDuration: boolean = isCardio && row['status'] !== 'planned';
      if (validateCardioMetrics(metrics, requireDuration).length > 0) {
        throw new Error('无效的心肺数据');
      }
    }
  }

  private static bucketNumber(row: relationalStore.ValuesBucket, key: string): number | null {
    const value: relationalStore.ValueType = row[key];
    if (value === undefined || value === null) {
      return null;
    }
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string' && value.length > 0) {
      const parsed: number = Number(value);
      if (Number.isNaN(parsed)) {
        return null;
      }
      return parsed;
    }
    return null;
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
          bucket[name] = null;
          continue;
        }
        const textColumns: string[] = ['name', 'aliases', 'part_key', 'primary_muscles', 'secondary_muscles',
          'movement_pattern', 'equipment', 'record_type', 'date', 'exercise_id', 'technique', 'status', 'note'];
        if (textColumns.indexOf(name) >= 0 || (name === 'id' && sql.endsWith('FROM exercises'))) {
          bucket[name] = rs.getString(idx);
        } else {
          bucket[name] = rs.getDouble(idx);
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
