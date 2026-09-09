import { DayDotKind, PartKey, SetStatus } from './types';
import { HintSet } from '../common/WorkoutLogic';

@Observed
export class SetItem {
  id: number = 0;
  weightText: string = '';
  repsText: string = '';
  isWarmup: number = 0;
  technique: string = '';
  rir: number = -1;
  status: SetStatus = 'planned';
  completedAt: number = 0;
  note: string = '';
  sortOrder: number = 0;
  inputError: string = '';
}

@Observed
export class ExerciseItem {
  id: number = 0;
  exerciseId: string = '';
  name: string = '';
  partKey: PartKey = 'chest';
  weightStep: number = 2.5;
  isBodyweight: number = 0;
  lastHint: string = '';
  lastSets: HintSet[] = [];
  note: string = '';
  sortOrder: number = 0;
  sets: SetItem[] = [];
}

@Observed
export class PartItem {
  id: number = 0;
  partKey: PartKey = 'chest';
  name: string = '';
  exercises: ExerciseItem[] = [];
}

@Observed
export class DayModel {
  date: string = '';
  dayId: number = 0;
  exercises: ExerciseItem[] = [];
  parts: PartItem[] = [];
}

export class CalendarCell {
  key: string = '';
  day: number = 0;
  date: string = '';
  inMonth: boolean = false;
  isToday: boolean = false;
  dotKind: DayDotKind = 'empty';
}

export class DayMark {
  date: string = '';
  hasDone: boolean = false;
  hasRecord: boolean = false;
}

export class RecentDayInfo {
  date: string = '';
  summary: string = '';
}

export class PrResult {
  weightPr: boolean = false;
  repsPr: boolean = false;
}

export class BodyMetric {
  date: string = '';
  weightKg: number = 0;
  hasWeight: boolean = false;
  note: string = '';
}
