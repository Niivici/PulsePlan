import { rcp } from '@kit.RemoteCommunicationKit';
import { EventBlock, ReminderItem, ScheduleItem } from '../common/PulsePlanModels';

export interface Profile {
  id: number;
  username: string;
  displayName: string;
  timeZone: string;
  role: string;
}

export class SessionExpiredError extends Error {}

export interface Session {
  token: string;
  user: Profile;
}

export interface Credentials {
  username: string;
  password: string;
}

export interface ScheduleChange {
  eventBlockId?: number;
  title?: string;
  dayKey?: string;
  startMinute?: number;
  endMinute?: number;
  completed?: boolean;
}

export interface PlanItem {
  title: string;
  dayKey: string;
  startMinute: number;
  endMinute: number;
}

export interface PlanPreview {
  id: string;
  title: string;
  items: PlanItem[];
}

interface PlanInput {
  prompt: string;
  from: string;
}

export interface DailyOverview {
  schedules: ScheduleItem[];
  reminders: ReminderItem[];
}

export interface AchievementStats {
  total: number;
  completed: number;
  activeDays: number;
}

export interface ReminderInput {
  title: string;
  minute: number;
  intensity: string;
}

export interface ProfileUpdate {
  displayName: string;
  timeZone: string;
}

export class PulsePlanApi {
  private base: string;
  private token: string = '';

  constructor(base: string, token: string = '') {
    this.token = token;
    this.base = base.trim().replace(/\/+$/, '');
  }

  private async request(path: string, method: rcp.HttpMethod, body?: string): Promise<string> {
    const session = rcp.createSession();
    const headers: rcp.RequestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': this.token.length > 0 ? 'Bearer ' + this.token : ''
    };
    try {
      const config: rcp.Configuration = { transfer: { timeout: { connectMs: 10000, transferMs: 55000 } } };
      const request = new rcp.Request(this.base + '/api/v1' + path, method, headers, body,
        undefined, undefined, config);
      const result = await session.fetch(request);
      if (result.statusCode === 409) {
        throw new Error('请求与现有数据冲突，请检查用户名或排程时段。');
      }
      if (result.statusCode === 401) {
        throw new SessionExpiredError('登录凭据无效或会话已过期。');
      }
      if (result.statusCode === 429) {
        throw new Error('今日 AI 排程次数已用完，请稍后再试。');
      }
      if (result.statusCode === 503) {
        throw new Error('服务暂不可用，请检查后端配置。');
      }
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw new Error('请求失败（HTTP ' + result.statusCode + '）。');
      }
      return result.toString() ?? '';
    } finally {
      session.close();
    }
  }

  async register(credentials: Credentials): Promise<void> {
    await this.request('/auth/register', 'POST', JSON.stringify(credentials));
  }

  async login(credentials: Credentials): Promise<Session> {
    const response = await this.request('/auth/login', 'POST', JSON.stringify(credentials));
    const session = JSON.parse(response) as Session;
    this.token = session.token;
    return session;
  }

  async logout(): Promise<void> {
    try {
      await this.request('/auth/logout', 'POST');
    } finally {
      this.token = '';
    }
  }

  async blocks(): Promise<EventBlock[]> {
    return JSON.parse(await this.request('/event-blocks', 'GET')) as EventBlock[];
  }

  async schedules(from: string, to: string): Promise<ScheduleItem[]> {
    const path = '/schedules?from=' + encodeURIComponent(from) + '&to=' + encodeURIComponent(to);
    return JSON.parse(await this.request(path, 'GET')) as ScheduleItem[];
  }

  async createSchedule(input: ScheduleChange): Promise<ScheduleItem> {
    return JSON.parse(await this.request('/schedules', 'POST', JSON.stringify(input))) as ScheduleItem;
  }

  async changeSchedule(id: number, input: ScheduleChange): Promise<ScheduleItem> {
    return JSON.parse(await this.request('/schedules/' + id, 'PATCH',
      JSON.stringify(input))) as ScheduleItem;
  }

  async deleteSchedule(id: number): Promise<void> {
    await this.request('/schedules/' + id, 'DELETE');
  }

  async setReminders(id: number, input: ReminderInput[]): Promise<void> {
    await this.request('/schedules/' + id + '/reminders', 'PUT', JSON.stringify(input));
  }

  async overview(date: string): Promise<DailyOverview> {
    return JSON.parse(await this.request('/overview?date=' + encodeURIComponent(date),
      'GET')) as DailyOverview;
  }

  async achievements(): Promise<AchievementStats> {
    return JSON.parse(await this.request('/achievements', 'GET')) as AchievementStats;
  }

  async profile(): Promise<Profile> {
    return JSON.parse(await this.request('/me', 'GET')) as Profile;
  }

  async updateProfile(input: ProfileUpdate): Promise<Profile> {
    return JSON.parse(await this.request('/me', 'PATCH', JSON.stringify(input))) as Profile;
  }

  async generate(prompt: string, from: string): Promise<PlanPreview> {
    const input: PlanInput = { prompt: prompt, from: from };
    return JSON.parse(await this.request('/ai/plans', 'POST', JSON.stringify(input))) as PlanPreview;
  }

  async confirm(id: string): Promise<ScheduleItem[]> {
    return JSON.parse(await this.request('/ai/plans/' + id + '/confirm', 'POST')) as ScheduleItem[];
  }
}
