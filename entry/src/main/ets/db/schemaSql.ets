export const CURRENT_VERSION: number = 2;

export const SQL_CREATE_EXERCISES: string =
  'CREATE TABLE IF NOT EXISTS exercises (' +
    'id TEXT PRIMARY KEY,' +
    'name TEXT NOT NULL,' +
    'aliases TEXT,' +
    'part_key TEXT NOT NULL,' +
    'primary_muscles TEXT,' +
    'secondary_muscles TEXT,' +
    'movement_pattern TEXT,' +
    'equipment TEXT,' +
    'is_unilateral INTEGER NOT NULL DEFAULT 0,' +
    'is_bodyweight INTEGER NOT NULL DEFAULT 0,' +
    'weight_step REAL NOT NULL DEFAULT 2.5,' +
    'is_builtin INTEGER NOT NULL DEFAULT 1,' +
    'is_archived INTEGER NOT NULL DEFAULT 0,' +
    'created_at INTEGER' +
  ')';

export const SQL_IDX_EXERCISES_PART: string =
  'CREATE INDEX IF NOT EXISTS idx_exercises_part ON exercises(part_key, is_archived)';

export const SQL_CREATE_WORKOUT_DAYS: string =
  'CREATE TABLE IF NOT EXISTS workout_days (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'date TEXT NOT NULL UNIQUE,' +
    'note TEXT,' +
    'created_at INTEGER' +
  ')';

export const SQL_CREATE_DAY_EXERCISES: string =
  'CREATE TABLE IF NOT EXISTS day_exercises (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'day_id INTEGER NOT NULL,' +
    'exercise_id TEXT NOT NULL,' +
    'sort_order INTEGER NOT NULL,' +
    'note TEXT' +
  ')';

export const SQL_IDX_DAY_EXERCISES_DAY: string =
  'CREATE INDEX IF NOT EXISTS idx_day_exercises_day ON day_exercises(day_id, sort_order)';

export const SQL_IDX_DAY_EXERCISES_EX: string =
  'CREATE INDEX IF NOT EXISTS idx_day_exercises_ex ON day_exercises(exercise_id)';

export const SQL_CREATE_WORKOUT_SETS: string =
  'CREATE TABLE IF NOT EXISTS workout_sets (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'day_exercise_id INTEGER NOT NULL,' +
    'weight REAL,' +
    'reps INTEGER,' +
    'is_warmup INTEGER NOT NULL DEFAULT 0,' +
    'technique TEXT,' +
    'rir INTEGER,' +
    'status TEXT NOT NULL DEFAULT \'done\',' +
    'completed_at INTEGER,' +
    'note TEXT,' +
    'sort_order INTEGER NOT NULL' +
  ')';

export const SQL_IDX_WORKOUT_SETS_DE: string =
  'CREATE INDEX IF NOT EXISTS idx_workout_sets_de ON workout_sets(day_exercise_id, sort_order)';

export const SQL_CREATE_BODY_METRICS: string =
  'CREATE TABLE IF NOT EXISTS body_metrics (' +
    'date TEXT PRIMARY KEY,' +
    'weight_kg REAL,' +
    'note TEXT,' +
    'created_at INTEGER' +
  ')';

// v2: 趋势配置——关注动作、每周训练目标、各部位每周正式组目标。
// 这三张表只存用户偏好，不参与历史训练数据的事实记录，可安全地用
// CREATE TABLE IF NOT EXISTS 幂等创建，无需从旧表迁移数据。
export const SQL_CREATE_WATCHED_EXERCISES: string =
  'CREATE TABLE IF NOT EXISTS watched_exercises (' +
    'exercise_id TEXT PRIMARY KEY,' +
    'sort_order INTEGER NOT NULL,' +
    'created_at INTEGER' +
  ')';

export const SQL_CREATE_TREND_SETTINGS: string =
  'CREATE TABLE IF NOT EXISTS trend_settings (' +
    'id INTEGER PRIMARY KEY,' +
    'sessions_target INTEGER,' +
    'updated_at INTEGER' +
  ')';

export const SQL_CREATE_TREND_PART_GOALS: string =
  'CREATE TABLE IF NOT EXISTS trend_part_goals (' +
    'part_key TEXT PRIMARY KEY,' +
    'work_sets_target INTEGER,' +
    'updated_at INTEGER' +
  ')';
