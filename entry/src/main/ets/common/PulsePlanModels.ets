export interface EventBlock {
  id: number;
  title: string;
  scene: string;
  preference: string;
  habitHint: string;
  aiHint: string;
  color: string;
  quickLaunch: string;
}

export interface ScheduleItem {
  id: number;
  eventBlockId: number;
  title: string;
  scene: string;
  dayKey: string;
  startMinute: number;
  endMinute: number;
  color: string;
  modeName: string;
  quickLaunch: string;
  aiSuggestion: string;
  flexibility: string;
  completed: boolean;
}

export interface ReminderItem {
  id: number;
  scheduleItemId: number;
  title: string;
  dayKey: string;
  minute: number;
  intensity: string;
}

export interface GeneratedPlan {
  eventBlock: EventBlock;
  scheduleItems: ScheduleItem[];
  reminders: ReminderItem[];
  bufferMinutes: number;
}

export interface DayMeta {
  dateKey: string;
  label: string;
  subLabel: string;
}

export interface MonthCellMeta {
  dateKey: string;
  dayNumber: number;
  inCurrentMonth: boolean;
}

export interface NavItem {
  key: string;
  label: string;
  shortLabel: string;
  description: string;
}
