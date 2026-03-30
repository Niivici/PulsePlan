import { NavItem } from './PulsePlanModels';

interface Palette {
  background: string;
  backgroundDeep: string;
  surface: string;
  surfaceRaised: string;
  surfaceAlt: string;
  border: string;
  borderStrong: string;
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  accentSky: string;
  accentBlue: string;
  accentWarm: string;
  accentLeaf: string;
  accentCoral: string;
  accentGold: string;
  glowSky: string;
  glowWarm: string;
  success: string;
  warning: string;
  navIdle: string;
  blackText: string;
}

export const VIEW_DAY: number = 0;
export const VIEW_WEEK: number = 1;
export const VIEW_MONTH: number = 2;

export const NAV_OVERVIEW: number = 0;
export const NAV_SCHEDULE: number = 1;
export const NAV_AI: number = 2;
export const NAV_ACHIEVEMENT: number = 3;
export const NAV_PROFILE: number = 4;

export const TIME_RAIL_WIDTH: number = 38;
export const DAY_COLUMN_WIDTH: number = 60;
export const DAY_COLUMN_GAP: number = 3;
export const SINGLE_DAY_WIDTH: number = 304;
export const WEEK_HEADER_HEIGHT: number = 32;
export const MINUTE_HEIGHT: number = 0.72;
export const SNAP_MINUTES: number = 10;
export const BOARD_START_MINUTE: number = 0;
export const BOARD_END_MINUTE: number = 24 * 60;
export const BOARD_HEIGHT: number = (BOARD_END_MINUTE - BOARD_START_MINUTE) * MINUTE_HEIGHT;

export const HOURS: number[] = Array.from<number, number>(
  { length: BOARD_END_MINUTE / 60 - BOARD_START_MINUTE / 60 },
  (_, index: number) => BOARD_START_MINUTE / 60 + index
);

export const WEEKDAY_TEXT: string[] = ['一', '二', '三', '四', '五', '六', '日'];
export const VIEW_LABELS: string[] = ['日视图', '周视图', '月视图'];

export const NAV_ITEMS: NavItem[] = [
  { key: 'overview', label: '概览', shortLabel: '览', description: '产品价值与本周主线' },
  { key: 'schedule', label: '日程', shortLabel: '程', description: '课表式周视图与拖拽排期' },
  { key: 'ai', label: 'AI', shortLabel: 'AI', description: '自然语言排程与习惯记忆' },
  { key: 'achievement', label: '成就', shortLabel: '成', description: '反馈机制与坚持曲线' },
  { key: 'profile', label: '我的', shortLabel: '我', description: '偏好、设备与资料管理' }
];

export const PulsePalette: Palette = {
  background: '#071019',
  backgroundDeep: '#050B12',
  surface: '#101A24',
  surfaceRaised: '#152432',
  surfaceAlt: '#0B141D',
  border: '#203240',
  borderStrong: '#345066',
  textPrimary: '#F6FBFF',
  textSecondary: '#D5E1EB',
  textMuted: '#8699AA',
  accentSky: '#9BE2FF',
  accentBlue: '#4CA7FF',
  accentWarm: '#F4A261',
  accentLeaf: '#50D39D',
  accentCoral: '#FF8A57',
  accentGold: '#E7C56E',
  glowSky: '#204A68',
  glowWarm: '#824B24',
  success: '#6BE2AE',
  warning: '#F8D98B',
  navIdle: '#718392',
  blackText: '#08111A'
};

