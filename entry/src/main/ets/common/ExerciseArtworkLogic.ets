export type ExerciseModelPreference = 'auto' | 'female' | 'male';
export type ExerciseModelGender = 'female' | 'male';

export function toExerciseModelPreference(value: string): ExerciseModelPreference {
  if (value === 'female' || value === 'male') {
    return value;
  }
  return 'auto';
}

export function autoGenderForExercise(exerciseId: string): ExerciseModelGender {
  let hash: number = 0;
  for (let i = 0; i < exerciseId.length; i++) {
    hash = (hash * 31 + exerciseId.charCodeAt(i)) & 0x7fffffff;
  }
  return hash % 2 === 0 ? 'female' : 'male';
}

export function resolveExerciseModelGender(
  preference: ExerciseModelPreference,
  exerciseId: string
): ExerciseModelGender {
  return preference === 'auto' ? autoGenderForExercise(exerciseId) : preference;
}

export function safeArtworkFrameIndex(index: number, frameCount: number): number {
  return frameCount > 0 && index >= 0 && index < frameCount ? index : 0;
}
