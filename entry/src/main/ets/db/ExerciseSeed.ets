import { relationalStore } from '@kit.ArkData';
import { ExerciseDef, EXERCISE_CATALOG } from '../model/exerciseCatalog';

export async function seedBuiltinExercises(store: relationalStore.RdbStore): Promise<void> {
  const now: number = Date.now();
  const sql: string =
    'INSERT OR IGNORE INTO exercises (id, name, aliases, part_key, primary_muscles, secondary_muscles, ' +
    'movement_pattern, equipment, is_unilateral, is_bodyweight, weight_step, record_type, is_builtin, is_archived, created_at) ' +
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
  const refreshSql: string =
    'UPDATE exercises SET movement_pattern = ?, is_unilateral = ?, is_bodyweight = ?, weight_step = ?, record_type = ? ' +
    'WHERE id = ? AND is_builtin = 1';
  for (let i = 0; i < EXERCISE_CATALOG.length; i++) {
    const def: ExerciseDef = EXERCISE_CATALOG[i];
    await store.executeSql(sql, [
      def.id,
      def.name,
      def.aliases,
      def.partKey,
      def.primaryMuscles,
      def.secondaryMuscles,
      def.movementPattern,
      def.equipment,
      def.isUnilateral,
      def.isBodyweight,
      def.weightStep,
      def.recordType,
      1,
      0,
      now
    ]);
    await store.executeSql(refreshSql, [
      def.movementPattern,
      def.isUnilateral,
      def.isBodyweight,
      def.weightStep,
      def.recordType,
      def.id
    ]);
  }
}
