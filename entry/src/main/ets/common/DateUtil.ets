import { CalendarCell, DayMark } from '../model/DayModels';
import { dayDotKind } from './WorkoutLogic';
import { toDayDotKind } from '../model/types';

const WEEKDAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

export function weekdayLabels(): string[] {
  return WEEKDAY_LABELS;
}

export function pad2(value: number): string {
  if (value < 10) {
    return `0${value}`;
  }
  return `${value}`;
}

export function formatYmd(year: number, monthIndex: number, day: number): string {
  return `${year}-${pad2(monthIndex + 1)}-${pad2(day)}`;
}

export function formatDate(date: Date): string {
  return formatYmd(date.getFullYear(), date.getMonth(), date.getDate());
}

export function todayString(): string {
  return formatDate(new Date());
}

export function daysInMonth(year: number, monthIndex: number): number {
  return new Date(year, monthIndex + 1, 0).getDate();
}

export function mondayFirstIndex(jsWeekday: number): number {
  if (jsWeekday === 0) {
    return 6;
  }
  return jsWeekday - 1;
}

export function displayChineseDate(dateStr: string): string {
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return dateStr;
  }
  const year: number = Number(parts[0]);
  const month: number = Number(parts[1]);
  const day: number = Number(parts[2]);
  const date: Date = new Date(year, month - 1, day);
  const week: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  return `${year}年${month}月${day}日 星期${week[date.getDay()]}`;
}

export function displayMonthTitle(year: number, monthIndex: number): string {
  return `${year}年${monthIndex + 1}月`;
}

export function buildMonthCells(year: number, monthIndex: number, marks: DayMark[], today: string): CalendarCell[] {
  const first: Date = new Date(year, monthIndex, 1);
  const leading: number = mondayFirstIndex(first.getDay());
  const count: number = daysInMonth(year, monthIndex);
  const total: number = Math.ceil((leading + count) / 7) * 7;
  const markMap: Map<string, DayMark> = new Map();
  for (let m = 0; m < marks.length; m++) {
    markMap.set(marks[m].date, marks[m]);
  }
  const cells: CalendarCell[] = [];
  for (let i = 0; i < total; i++) {
    const cell: CalendarCell = new CalendarCell();
    const dayNum: number = i - leading + 1;
    if (dayNum < 1 || dayNum > count) {
      cell.key = `empty-${year}-${monthIndex}-${i}`;
      cells.push(cell);
      continue;
    }
    cell.key = formatYmd(year, monthIndex, dayNum);
    cell.day = dayNum;
    cell.date = cell.key;
    cell.inMonth = true;
    cell.isToday = cell.date === today;
    const mark: DayMark | undefined = markMap.get(cell.date);
    let hasDone: boolean = false;
    let hasRecord: boolean = false;
    if (mark !== undefined) {
      hasDone = mark.hasDone;
      hasRecord = mark.hasRecord;
    }
    cell.dotKind = toDayDotKind(dayDotKind(cell.date, today, hasDone, hasRecord));
    cells.push(cell);
  }
  return cells;
}

export function shiftMonth(year: number, monthIndex: number, delta: number): number[] {
  let nextMonth: number = monthIndex + delta;
  let nextYear: number = year;
  if (nextMonth < 0) {
    nextMonth = 11;
    nextYear -= 1;
  } else if (nextMonth > 11) {
    nextMonth = 0;
    nextYear += 1;
  }
  return [nextYear, nextMonth];
}

export function monthRange(year: number, monthIndex: number): string[] {
  const start: string = formatYmd(year, monthIndex, 1);
  const end: string = formatYmd(year, monthIndex, daysInMonth(year, monthIndex));
  return [start, end];
}

export function addDays(dateStr: string, delta: number): string {
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return dateStr;
  }
  const date: Date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]) + delta);
  return formatDate(date);
}

export function isoWeekStart(dateStr: string): string {
  const parts: string[] = dateStr.split('-');
  if (parts.length !== 3) {
    return dateStr;
  }
  const date: Date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  return addDays(dateStr, -mondayFirstIndex(date.getDay()));
}

export function rangeStart(today: string, weeks: number): string {
  if (weeks < 1) {
    return today;
  }
  return addDays(today, -(weeks * 7 - 1));
}
