import { ExerciseDef } from '../model/exerciseCatalog';
import { equipmentName } from '../model/types';

export interface RecommendItem {
  id: string;
  name: string;
  role: string;
  equipment: string;
  addedToday: boolean;
}

interface MuscleMapping {
  id: string;
  primary: string;
  secondary: string;
}

// Stable built-in IDs distinguish exact muscles from legacy broad category metadata.
// Custom exercises remain available through search until explicitly mapped.
const MUSCLE_MAPPING: MuscleMapping[] = [
  { id: 'chest_bb_bench', primary: 'chest', secondary: 'triceps,front_delt' },
  { id: 'chest_db_bench', primary: 'chest', secondary: 'triceps,front_delt' },
  { id: 'chest_incline_bench', primary: 'chest', secondary: 'front_delt,triceps' },
  { id: 'chest_fly', primary: 'chest', secondary: 'front_delt' },
  { id: 'chest_cable_crossover', primary: 'chest', secondary: '' },
  { id: 'chest_dip', primary: 'chest,triceps', secondary: 'front_delt' },
  { id: 'chest_pushup', primary: 'chest', secondary: 'triceps,front_delt' },
  { id: 'shoulder_bb_press', primary: 'front_delt', secondary: 'side_delt,triceps,traps' },
  { id: 'shoulder_db_press', primary: 'front_delt', secondary: 'side_delt,triceps,traps' },
  { id: 'shoulder_lateral_raise', primary: 'side_delt', secondary: 'traps' },
  { id: 'shoulder_front_raise', primary: 'front_delt', secondary: '' },
  { id: 'shoulder_reverse_fly', primary: 'rear_delt', secondary: 'upper_back,traps' },
  { id: 'shoulder_face_pull', primary: 'rear_delt,upper_back', secondary: 'traps' },
  { id: 'back_pullup', primary: 'lats', secondary: 'biceps,forearm,upper_back' },
  { id: 'back_lat_pulldown', primary: 'lats', secondary: 'biceps,upper_back' },
  { id: 'back_bb_row', primary: 'lats,upper_back', secondary: 'biceps,rear_delt,traps,erector_spinae,forearm' },
  { id: 'back_db_row', primary: 'lats,upper_back', secondary: 'biceps,rear_delt,forearm' },
  { id: 'back_seated_row', primary: 'lats,upper_back', secondary: 'biceps,rear_delt,traps' },
  { id: 'back_deadlift', primary: 'glute_max,erector_spinae', secondary: 'hamstrings,quads,traps,forearm' },
  { id: 'arm_bb_curl', primary: 'biceps', secondary: 'forearm' },
  { id: 'arm_db_curl', primary: 'biceps', secondary: 'forearm' },
  { id: 'arm_hammer_curl', primary: 'biceps,forearm', secondary: '' },
  { id: 'arm_pushdown', primary: 'triceps', secondary: '' },
  { id: 'arm_skull_crusher', primary: 'triceps', secondary: '' },
  { id: 'glute_hip_thrust', primary: 'glute_max', secondary: 'hamstrings' },
  { id: 'glute_rdl', primary: 'hamstrings,glute_max', secondary: 'erector_spinae,forearm' },
  { id: 'glute_bridge', primary: 'glute_max', secondary: 'hamstrings' },
  { id: 'glute_abduction', primary: 'glute_med', secondary: 'glute_max' },
  { id: 'leg_squat', primary: 'quads,glute_max', secondary: 'erector_spinae,glute_med' },
  { id: 'leg_press', primary: 'quads', secondary: 'glute_max' },
  { id: 'leg_extension', primary: 'quads', secondary: '' },
  { id: 'leg_curl', primary: 'hamstrings', secondary: '' },
  { id: 'leg_lunge', primary: 'quads,glute_max', secondary: 'glute_med' },
  { id: 'leg_calf_raise', primary: 'calves', secondary: '' },
  { id: 'abs_crunch', primary: 'rectus_abdominis', secondary: 'obliques' },
  { id: 'abs_reverse_crunch', primary: 'rectus_abdominis', secondary: 'obliques' },
  { id: 'abs_leg_raise', primary: 'rectus_abdominis', secondary: '' },
  { id: 'core_dead_bug', primary: 'rectus_abdominis,obliques', secondary: '' },
  { id: 'core_bird_dog', primary: 'erector_spinae,obliques', secondary: 'glute_max,rectus_abdominis' },
  { id: 'core_shoulder_tap', primary: 'obliques,rectus_abdominis', secondary: 'front_delt,triceps' }
];

function recommendation(def: ExerciseDef, role: string, added: string[]): RecommendItem {
  return { id: def.id, name: def.name, role: role, equipment: equipmentName(def.equipment),
    addedToday: added.indexOf(def.id) >= 0 };
}

export function recommendForMuscle(key: string, defs: ExerciseDef[], added: string[]): RecommendItem[] {
  const main: RecommendItem[] = [];
  const secondary: RecommendItem[] = [];
  for (let i = 0; i < MUSCLE_MAPPING.length; i++) {
    const map: MuscleMapping = MUSCLE_MAPPING[i];
    const isMain: boolean = map.primary.split(',').indexOf(key) >= 0;
    const isSecondary: boolean = map.secondary.split(',').indexOf(key) >= 0;
    if (!isMain && !isSecondary) {
      continue;
    }
    for (let j = 0; j < defs.length; j++) {
      if (defs[j].id === map.id) {
        if (isMain) {
          main.push(recommendation(defs[j], '主要', added));
        } else {
          secondary.push(recommendation(defs[j], '协同', added));
        }
        break;
      }
    }
  }
  return main.concat(secondary);
}

export function filterExercises(defs: ExerciseDef[], query: string, added: string[]): RecommendItem[] {
  const term: string = query.trim().toLowerCase();
  const result: RecommendItem[] = [];
  for (let i = 0; i < defs.length; i++) {
    const def: ExerciseDef = defs[i];
    if (term.length === 0 || def.name.toLowerCase().indexOf(term) >= 0 ||
      def.aliases.toLowerCase().indexOf(term) >= 0 || def.id.toLowerCase().indexOf(term) >= 0) {
      result.push(recommendation(def, '', added));
    }
  }
  return result;
}

export function isSelected(ids: string[], id: string): boolean {
  return ids.indexOf(id) >= 0;
}

export function toggleSelected(ids: string[], id: string, addedToday: boolean): string[] {
  if (addedToday) {
    return ids.slice();
  }
  if (isSelected(ids, id)) {
    return ids.filter((value: string) => value !== id);
  }
  return ids.concat([id]);
}
