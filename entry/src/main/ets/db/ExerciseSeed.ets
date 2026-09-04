import { relationalStore } from '@kit.ArkData';
import { ExerciseDef, EXERCISE_CATALOG } from '../model/exerciseCatalog';

export async function seedBuiltinExercises(store: relationalStore.RdbStore): Promise<void> {
  const now: number = Date.now();
  const sql: string =
    'INSERT OR IGNORE INTO exercises (id, name, aliases, part_key, primary_muscles, secondary_muscles, ' +
    'movement_pattern, equipment, is_unilateral, is_bodyweight, weight_step, is_builtin, is_archived, created_at) ' +
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
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
      1,
      0,
      now
    ]);
  }
}
