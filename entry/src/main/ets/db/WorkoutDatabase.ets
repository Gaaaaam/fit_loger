import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN: number = 0xF170;
const TAG: string = 'WorkoutDB';
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'workout.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

export class WorkoutDatabase {
  private static store: relationalStore.RdbStore | undefined = undefined;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (WorkoutDatabase.store !== undefined) {
      return;
    }
    const rdb: relationalStore.RdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await rdb.executeSql(
      'CREATE TABLE IF NOT EXISTS workout_days (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        'date TEXT NOT NULL UNIQUE' +
      ')'
    );
    await rdb.executeSql(
      'CREATE TABLE IF NOT EXISTS day_parts (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        'day_id INTEGER NOT NULL,' +
        'part_key TEXT NOT NULL,' +
        'sort_order INTEGER NOT NULL' +
      ')'
    );
    await rdb.executeSql(
      'CREATE TABLE IF NOT EXISTS day_exercises (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        'day_part_id INTEGER NOT NULL,' +
        'exercise_id TEXT NOT NULL,' +
        'sort_order INTEGER NOT NULL' +
      ')'
    );
    await rdb.executeSql(
      'CREATE TABLE IF NOT EXISTS workout_sets (' +
        'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        'exercise_row_id INTEGER NOT NULL,' +
        'weight REAL,' +
        'reps INTEGER,' +
        'tag TEXT NOT NULL,' +
        'sort_order INTEGER NOT NULL' +
      ')'
    );
    WorkoutDatabase.store = rdb;
    hilog.info(DOMAIN, TAG, 'database ready');
  }

  static getStore(): relationalStore.RdbStore {
    if (WorkoutDatabase.store === undefined) {
      throw new Error('database not initialized');
    }
    return WorkoutDatabase.store;
  }

  static logError(action: string, err: BusinessError): void {
    hilog.error(DOMAIN, TAG, '%{public}s failed, code %{public}d, %{public}s', action, err.code, err.message);
  }
}
