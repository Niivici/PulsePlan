import {
  BOARD_END_MINUTE,
  BOARD_START_MINUTE,
  MINUTE_HEIGHT,
  SNAP_MINUTES,
  WEEKDAY_TEXT
} from './PulsePlanTheme';
import { DayMeta, MonthCellMeta, ScheduleItem } from './PulsePlanModels';

export function track(eventName: string, payload: string): void {
  console.info(`[PulsePlan] ${eventName}: ${payload}`);
}

export function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function getDateKey(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function parseDateKey(dateKey: string): Date {
  const parts: number[] = dateKey.split('-').map((item: string) => Number(item));
  return new Date(parts[0], parts[1] - 1, parts[2]);
}

export function addDays(dateKey: string, offset: number): string {
  const date: Date = parseDateKey(dateKey);
  date.setDate(date.getDate() + offset);
  return getDateKey(date);
}

export function addMonths(dateKey: string, offset: number): string {
  const date: Date = parseDateKey(dateKey);
  const currentDay: number = date.getDate();
  const next: Date = new Date(date.getFullYear(), date.getMonth() + offset, 1);
  const lastDay: number = new Date(next.getFullYear(), next.getMonth() + 1, 0).getDate();
  return getDateKey(new Date(next.getFullYear(), next.getMonth(), Math.min(currentDay, lastDay)));
}

export function getWeekStart(dateKey: string): string {
  const date: Date = parseDateKey(dateKey);
  const day: number = date.getDay();
  const shift: number = day === 0 ? -6 : 1 - day;
  return addDays(dateKey, shift);
}

export function formatMinuteLabel(minute: number): string {
  const hours: number = Math.floor(minute / 60);
  const mins: number = minute % 60;
  return `${pad(hours)}:${pad(mins)}`;
}

export function formatDateTitle(dateKey: string): string {
  const date: Date = parseDateKey(dateKey);
  return `${date.getMonth() + 1}月${date.getDate()}日 周${WEEKDAY_TEXT[(date.getDay() + 6) % 7]}`;
}

export function formatWeekRangeTitle(dateKey: string): string {
  const start: string = getWeekStart(dateKey);
  const end: string = addDays(start, 6);
  const startDate: Date = parseDateKey(start);
  const endDate: Date = parseDateKey(end);
  return `${startDate.getMonth() + 1}月${startDate.getDate()}日-${endDate.getMonth() + 1}月${endDate.getDate()}日`;
}

export function formatMonthTitle(dateKey: string): string {
  const date: Date = parseDateKey(dateKey);
  return `${date.getFullYear()}年${date.getMonth() + 1}月`;
}

export function clampMinute(value: number, min: number = BOARD_START_MINUTE, max: number = BOARD_END_MINUTE): number {
  return Math.max(min, Math.min(value, max));
}

export function snapMinute(value: number): number {
  return Math.round(value / SNAP_MINUTES) * SNAP_MINUTES;
}

export function sortSchedules(items: ScheduleItem[]): ScheduleItem[] {
  return [...items].sort((left: ScheduleItem, right: ScheduleItem) => {
    if (left.dayKey === right.dayKey) {
      return left.startMinute - right.startMinute;
    }
    return left.dayKey.localeCompare(right.dayKey);
  });
}

export function buildWeekDays(dateKey: string): DayMeta[] {
  const start: string = getWeekStart(dateKey);
  return WEEKDAY_TEXT.map((label: string, index: number) => {
    const nextKey: string = addDays(start, index);
    const date: Date = parseDateKey(nextKey);
    return {
      dateKey: nextKey,
      label: `周${label}`,
      subLabel: `${date.getMonth() + 1}/${date.getDate()}`
    } as DayMeta;
  });
}

export function buildMonthCells(dateKey: string): MonthCellMeta[] {
  const date: Date = parseDateKey(dateKey);
  const monthStart: Date = new Date(date.getFullYear(), date.getMonth(), 1);
  const monthEnd: Date = new Date(date.getFullYear(), date.getMonth() + 1, 0);
  const startOffset: number = (monthStart.getDay() + 6) % 7;
  const cells: MonthCellMeta[] = [];
  for (let index: number = 0; index < 42; index++) {
    const current: Date = new Date(monthStart.getFullYear(), monthStart.getMonth(), index - startOffset + 1);
    cells.push({
      dateKey: getDateKey(current),
      dayNumber: current.getDate(),
      inCurrentMonth: current.getMonth() === monthEnd.getMonth()
    } as MonthCellMeta);
  }
  return cells;
}

export function getSchedulesForDay(scheduleItems: ScheduleItem[], dayKey: string): ScheduleItem[] {
  return sortSchedules(scheduleItems.filter((item: ScheduleItem) => item.dayKey === dayKey));
}

export function toBoardOffset(minute: number): number {
  return (minute - BOARD_START_MINUTE) * MINUTE_HEIGHT;
}

export function getWeekMinutes(scheduleItems: ScheduleItem[], dateKey: string): number {
  const weekStart: string = getWeekStart(dateKey);
  const weekEnd: string = addDays(weekStart, 6);
  const weekItems: ScheduleItem[] =
    scheduleItems.filter((item: ScheduleItem) => item.dayKey >= weekStart && item.dayKey <= weekEnd);
  return weekItems.reduce((sum: number, item: ScheduleItem) => sum + (item.endMinute - item.startMinute), 0);
}

export function getCompletionRate(scheduleItems: ScheduleItem[]): number {
  if (scheduleItems.length === 0) {
    return 0;
  }
  const completed: number = scheduleItems.filter((item: ScheduleItem) => item.completed).length;
  return Math.round((completed / scheduleItems.length) * 100);
}
