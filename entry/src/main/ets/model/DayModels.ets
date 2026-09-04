import { PartKey, SetTag } from './types';

@Observed
export class SetItem {
  id: number = 0;
  weightText: string = '';
  repsText: string = '';
  tag: SetTag = 'working';
}

@Observed
export class ExerciseItem {
  id: number = 0;
  exerciseId: string = '';
  name: string = '';
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
  parts: PartItem[] = [];
}

export class CalendarCell {
  key: string = '';
  day: number = 0;
  date: string = '';
  inMonth: boolean = false;
  isToday: boolean = false;
  marked: boolean = false;
}
