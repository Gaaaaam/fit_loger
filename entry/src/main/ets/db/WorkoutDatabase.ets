import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  FlatExRow,
  flattenDayExerciseOrder,
  LegacyExRow,
  LegacyTagMapped,
  mapLegacyTag
} from '../common/WorkoutLogic';
import { BackupService } from './BackupService';
import { seedBuiltinExercises } from './ExerciseSeed';
import {
  CURRENT_VERSION,
  SQL_CREATE_BODY_METRICS,
  SQL_CREATE_DAY_EXERCISES,
  SQL_CREATE_EXERCISES,
  SQL_CREATE_TREND_PART_GOALS,
  SQL_CREATE_TREND_SETTINGS,
  SQL_CREATE_WATCHED_EXERCISES,
  SQL_CREATE_WORKOUT_DAYS,
  SQL_CREATE_WORKOUT_SETS,
  SQL_IDX_DAY_EXERCISES_DAY,
  SQL_IDX_DAY_EXERCISES_EX,
  SQL_IDX_EXERCISES_PART,
  SQL_IDX_WORKOUT_SETS_DE
} from './schemaSql';

const DOMAIN: number = 0xF170;
const TAG: string = 'WorkoutDB';
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'workout.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

export class WorkoutDatabase {
  private static store: relationalStore.RdbStore | undefined = undefined;
  private static appContext: common.UIAbilityContext | undefined = undefined;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (WorkoutDatabase.store !== undefined) {
      return;
    }
    WorkoutDatabase.appContext = context;
    const rdb: relationalStore.RdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await WorkoutDatabase.migrate(rdb, context);
    WorkoutDatabase.store = rdb;
    hilog.info(DOMAIN, TAG, 'database ready, version %{public}d', rdb.version);
  }

  static getStore(): relationalStore.RdbStore {
    if (WorkoutDatabase.store === undefined) {
      throw new Error('database not initialized');
    }
    return WorkoutDatabase.store;
  }

  static getContext(): common.UIAbilityContext {
    if (WorkoutDatabase.appContext === undefined) {
      throw new Error('database not initialized');
    }
    return WorkoutDatabase.appContext;
  }

  static logError(action: string, err: BusinessError): void {
    hilog.error(DOMAIN, TAG, '%{public}s failed, code %{public}d, %{public}s', action, err.code, err.message);
  }

  private static async migrate(store: relationalStore.RdbStore, context: common.UIAbilityContext): Promise<void> {
    if (store.version >= CURRENT_VERSION) {
      // 幂等：即便版本号已是最新，也确保趋势配置表存在（例如从中断的升级恢复）。
      await WorkoutDatabase.createTrendSchema(store);
      await seedBuiltinExercises(store);
      return;
    }
    const hasDays: boolean = await WorkoutDatabase.tableExists(store, 'workout_days');
    const hasParts: boolean = await WorkoutDatabase.tableExists(store, 'day_parts');
    const hasLegacyExCol: boolean = await WorkoutDatabase.columnExists(store, 'day_exercises', 'day_part_id');
    const hasNewExCol: boolean = await WorkoutDatabase.columnExists(store, 'day_exercises', 'day_id');
    const hasExercises: boolean = await WorkoutDatabase.tableExists(store, 'exercises');
    const needsLegacyCopy: boolean = hasParts && hasLegacyExCol;
    const alreadyV1: boolean = hasExercises && hasNewExCol && !hasLegacyExCol;

    if (hasDays || needsLegacyCopy) {
      try {
        await BackupService.backupBeforeMigrate(store, context);
      } catch (err) {
        WorkoutDatabase.logError('backupBeforeMigrate', err as BusinessError);
        throw new Error('backupBeforeMigrate failed');
      }
    }

    if (alreadyV1) {
      // v1 -> v2：只新增趋势配置表，训练历史表结构不变，无需搬数据。
      await WorkoutDatabase.createTrendSchema(store);
      await seedBuiltinExercises(store);
      store.version = CURRENT_VERSION;
      return;
    }

    if (needsLegacyCopy) {
      await WorkoutDatabase.migrateLegacy(store);
      await WorkoutDatabase.createTrendSchema(store);
      store.version = CURRENT_VERSION;
      return;
    }

    await WorkoutDatabase.createV1Schema(store);
    await WorkoutDatabase.createTrendSchema(store);
    await seedBuiltinExercises(store);
    store.version = CURRENT_VERSION;
  }

  private static async createV1Schema(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(SQL_CREATE_EXERCISES);
    await store.executeSql(SQL_IDX_EXERCISES_PART);
    await store.executeSql(SQL_CREATE_WORKOUT_DAYS);
    await store.executeSql(SQL_CREATE_DAY_EXERCISES);
    await store.executeSql(SQL_IDX_DAY_EXERCISES_DAY);
    await store.executeSql(SQL_IDX_DAY_EXERCISES_EX);
    await store.executeSql(SQL_CREATE_WORKOUT_SETS);
    await store.executeSql(SQL_IDX_WORKOUT_SETS_DE);
    await store.executeSql(SQL_CREATE_BODY_METRICS);
  }

  private static async createTrendSchema(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(SQL_CREATE_WATCHED_EXERCISES);
    await store.executeSql(SQL_CREATE_TREND_SETTINGS);
    await store.executeSql(SQL_CREATE_TREND_PART_GOALS);
  }

  private static async migrateLegacy(store: relationalStore.RdbStore): Promise<void> {
    const hasExLegacy: boolean = await WorkoutDatabase.tableExists(store, 'day_exercises_legacy');
    if (!hasExLegacy) {
      await store.executeSql('ALTER TABLE day_exercises RENAME TO day_exercises_legacy');
    }
    const hasSetLegacy: boolean = await WorkoutDatabase.tableExists(store, 'workout_sets_legacy');
    if (!hasSetLegacy) {
      await store.executeSql('ALTER TABLE workout_sets RENAME TO workout_sets_legacy');
    }

    await WorkoutDatabase.createV1Schema(store);
    await WorkoutDatabase.addDayColumns(store);
    await seedBuiltinExercises(store);

    const newExCount: number = await WorkoutDatabase.countRows(store, 'day_exercises');
    if (newExCount === 0) {
      await WorkoutDatabase.copyLegacyExercises(store);
    }
    const newSetCount: number = await WorkoutDatabase.countRows(store, 'workout_sets');
    if (newSetCount === 0) {
      await WorkoutDatabase.copyLegacySets(store);
    }
  }

  private static async addDayColumns(store: relationalStore.RdbStore): Promise<void> {
    const hasNote: boolean = await WorkoutDatabase.columnExists(store, 'workout_days', 'note');
    if (!hasNote) {
      await store.executeSql('ALTER TABLE workout_days ADD COLUMN note TEXT');
    }
    const hasCreated: boolean = await WorkoutDatabase.columnExists(store, 'workout_days', 'created_at');
    if (!hasCreated) {
      await store.executeSql('ALTER TABLE workout_days ADD COLUMN created_at INTEGER');
    }
  }

  private static async copyLegacyExercises(store: relationalStore.RdbStore): Promise<void> {
    const sql: string =
      'SELECT e.id AS id, e.exercise_id AS exercise_id, e.sort_order AS ex_sort, ' +
      'p.id AS part_id, p.sort_order AS part_sort, p.day_id AS day_id ' +
      'FROM day_exercises_legacy e INNER JOIN day_parts p ON p.id = e.day_part_id';
    const rs: relationalStore.ResultSet = await store.querySql(sql, []);
    const rows: LegacyExRow[] = [];
    const dayIds: number[] = [];
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const row: LegacyExRow = new LegacyExRow();
      row.id = rs.getLong(rs.getColumnIndex('id'));
      row.exerciseId = rs.getString(rs.getColumnIndex('exercise_id'));
      row.exSort = rs.getLong(rs.getColumnIndex('ex_sort'));
      row.partId = rs.getLong(rs.getColumnIndex('part_id'));
      row.partSort = rs.getLong(rs.getColumnIndex('part_sort'));
      rows.push(row);
      dayIds.push(rs.getLong(rs.getColumnIndex('day_id')));
      hasRow = rs.goToNextRow();
    }
    rs.close();
    const flat: FlatExRow[] = flattenDayExerciseOrder(rows);
    for (let i = 0; i < flat.length; i++) {
      const bucket: relationalStore.ValuesBucket = {
        'id': flat[i].id,
        'day_id': dayIds[indexOfLegacyId(rows, flat[i].id)],
        'exercise_id': flat[i].exerciseId,
        'sort_order': flat[i].sortOrder
      };
      await store.insert('day_exercises', bucket);
    }
  }

  private static async copyLegacySets(store: relationalStore.RdbStore): Promise<void> {
    const sql: string =
      'SELECT id, exercise_row_id, weight, reps, tag, sort_order FROM workout_sets_legacy';
    const rs: relationalStore.ResultSet = await store.querySql(sql, []);
    let hasRow: boolean = rs.goToFirstRow();
    while (hasRow) {
      const tag: string = rs.getString(rs.getColumnIndex('tag'));
      const mapped: LegacyTagMapped = mapLegacyTag(tag);
      const bucket: relationalStore.ValuesBucket = {
        'id': rs.getLong(rs.getColumnIndex('id')),
        'day_exercise_id': rs.getLong(rs.getColumnIndex('exercise_row_id')),
        'is_warmup': mapped.isWarmup,
        'status': 'done',
        'sort_order': rs.getLong(rs.getColumnIndex('sort_order'))
      };
      if (!rs.isColumnNull(rs.getColumnIndex('weight'))) {
        bucket['weight'] = rs.getDouble(rs.getColumnIndex('weight'));
      }
      if (!rs.isColumnNull(rs.getColumnIndex('reps'))) {
        bucket['reps'] = rs.getLong(rs.getColumnIndex('reps'));
      }
      if (mapped.technique.length > 0) {
        bucket['technique'] = mapped.technique;
      }
      await store.insert('workout_sets', bucket);
      hasRow = rs.goToNextRow();
    }
    rs.close();
  }

  private static async tableExists(store: relationalStore.RdbStore, name: string): Promise<boolean> {
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
      ['table', name]
    );
    const exists: boolean = rs.goToFirstRow();
    rs.close();
    return exists;
  }

  private static async columnExists(store: relationalStore.RdbStore, table: string, column: string): Promise<boolean> {
    const existsTable: boolean = await WorkoutDatabase.tableExists(store, table);
    if (!existsTable) {
      return false;
    }
    const rs: relationalStore.ResultSet = await store.querySql(`PRAGMA table_info(${table})`, []);
    let hasRow: boolean = rs.goToFirstRow();
    let found: boolean = false;
    while (hasRow) {
      const colName: string = rs.getString(rs.getColumnIndex('name'));
      if (colName === column) {
        found = true;
        break;
      }
      hasRow = rs.goToNextRow();
    }
    rs.close();
    return found;
  }

  private static async countRows(store: relationalStore.RdbStore, table: string): Promise<number> {
    const rs: relationalStore.ResultSet = await store.querySql(`SELECT COUNT(*) AS cnt FROM ${table}`, []);
    let count: number = 0;
    if (rs.goToFirstRow()) {
      count = rs.getLong(rs.getColumnIndex('cnt'));
    }
    rs.close();
    return count;
  }
}

function indexOfLegacyId(rows: LegacyExRow[], id: number): number {
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].id === id) {
      return i;
    }
  }
  return 0;
}
