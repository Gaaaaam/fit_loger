import { matchesSearch } from './MuscleLogic';
import { ExerciseDef } from '../model/exerciseCatalog';
import { extraSearchText, findExerciseDetail } from '../model/exerciseDetails';
import { Equipment } from '../model/types';

export function filterPickerList(items: ExerciseDef[], query: string, equipment: string): ExerciseDef[] {
  const result: ExerciseDef[] = [];
  for (let i = 0; i < items.length; i++) {
    if (equipment.length > 0 && items[i].equipment !== equipment) {
      continue;
    }
    const extra: string = extraSearchText(findExerciseDetail(items[i].id));
    if (!matchesSearch(items[i].name, items[i].aliases, query, extra)) {
      continue;
    }
    result.push(items[i]);
  }
  return result;
}

export function equipmentKeysIn(items: ExerciseDef[]): Equipment[] {
  const keys: Equipment[] = [];
  const seen: Map<string, boolean> = new Map();
  for (let i = 0; i < items.length; i++) {
    const eq: Equipment = items[i].equipment;
    if (seen.get(eq) === true) {
      continue;
    }
    seen.set(eq, true);
    keys.push(eq);
  }
  return keys;
}

export function isCustomExercise(exerciseId: string): boolean {
  return exerciseId.indexOf('usr_') === 0;
}

export function joinZh(items: string[]): string {
  let text: string = '';
  for (let i = 0; i < items.length; i++) {
    if (i > 0) {
      text = text + '、';
    }
    text = text + items[i];
  }
  return text;
}

export function numberedLine(index: number, text: string): string {
  return `${index + 1}. ${text}`;
}
