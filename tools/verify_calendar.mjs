/**
 * Mirrors entry/src/main/ets/common/DateUtil.ets so calendar math can be
 * verified without DevEco. Keep this in sync with DateUtil.ets.
 */
function pad2(value) {
  return value < 10 ? `0${value}` : `${value}`;
}

function formatYmd(year, monthIndex, day) {
  return `${year}-${pad2(monthIndex + 1)}-${pad2(day)}`;
}

function daysInMonth(year, monthIndex) {
  return new Date(year, monthIndex + 1, 0).getDate();
}

function mondayFirstIndex(jsWeekday) {
  return jsWeekday === 0 ? 6 : jsWeekday - 1;
}

function buildMonthCells(year, monthIndex, markedDates) {
  const first = new Date(year, monthIndex, 1);
  const leading = mondayFirstIndex(first.getDay());
  const count = daysInMonth(year, monthIndex);
  const total = Math.ceil((leading + count) / 7) * 7;
  const cells = [];
  for (let i = 0; i < total; i++) {
    const dayNum = i - leading + 1;
    if (dayNum < 1 || dayNum > count) {
      cells.push({ inMonth: false, date: '', marked: false, day: 0 });
      continue;
    }
    const date = formatYmd(year, monthIndex, dayNum);
    cells.push({
      inMonth: true,
      date,
      marked: markedDates.indexOf(date) >= 0,
      day: dayNum
    });
  }
  return cells;
}

function shiftMonth(year, monthIndex, delta) {
  let nextMonth = monthIndex + delta;
  let nextYear = year;
  if (nextMonth < 0) {
    nextMonth = 11;
    nextYear -= 1;
  } else if (nextMonth > 11) {
    nextMonth = 0;
    nextYear += 1;
  }
  return [nextYear, nextMonth];
}

function assert(cond, message) {
  if (!cond) {
    throw new Error(message);
  }
}

const sept2026 = buildMonthCells(2026, 8, ['2026-09-03', '2026-09-15']);
assert(sept2026.length % 7 === 0, 'grid must be full weeks');
const firstInMonth = sept2026.find((c) => c.inMonth);
assert(firstInMonth.date === '2026-09-01', `expected 2026-09-01, got ${firstInMonth.date}`);
assert(firstInMonth.day === 1, 'first in-month cell should be day 1');
// 2026-09-01 is Tuesday; Monday-first means one leading blank.
assert(!sept2026[0].inMonth, 'first cell should be leading blank (Mon)');
assert(sept2026[1].date === '2026-09-01', 'Tuesday Sep 1 should be second cell');
const marked = sept2026.filter((c) => c.marked).map((c) => c.date);
assert(marked.join(',') === '2026-09-03,2026-09-15', `marks: ${marked.join(',')}`);
const lastInMonth = [...sept2026].reverse().find((c) => c.inMonth);
assert(lastInMonth.date === '2026-09-30', `expected last day 2026-09-30, got ${lastInMonth.date}`);

const janShift = shiftMonth(2026, 0, -1);
assert(janShift[0] === 2025 && janShift[1] === 11, `prev of Jan 2026: ${janShift}`);
const decShift = shiftMonth(2026, 11, 1);
assert(decShift[0] === 2027 && decShift[1] === 0, `next of Dec 2026: ${decShift}`);

const feb2024 = buildMonthCells(2024, 1, []);
const febDays = feb2024.filter((c) => c.inMonth);
assert(febDays.length === 29, `2024 leap Feb should have 29 days, got ${febDays.length}`);

console.log('calendar math: all checks passed');

function keepWeight(value) {
  let out = '';
  let hasDot = false;
  for (let i = 0; i < value.length; i++) {
    const ch = value.charAt(i);
    if (ch >= '0' && ch <= '9') {
      out += ch;
    } else if (ch === '.' && !hasDot) {
      out += ch;
      hasDot = true;
    }
  }
  return out;
}

function keepReps(value) {
  let out = '';
  for (let i = 0; i < value.length; i++) {
    const ch = value.charAt(i);
    if (ch >= '0' && ch <= '9') {
      out += ch;
    }
  }
  return out;
}

assert(keepWeight('12.5kg') === '12.5', 'weight filter should drop letters');
assert(keepWeight('1.2.3') === '1.23', 'weight filter should keep one dot');
assert(keepReps('12a3') === '123', 'reps filter should drop letters');
console.log('input filters: all checks passed');
