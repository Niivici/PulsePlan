import {
  AchievementStats, PlanItem, PlanPreview, Profile, ProfileUpdate,
  PulsePlanApi, ReminderInput, ScheduleChange
} from '../services/PulsePlanApi';
import { AISection } from '../components/ai/AISection';
import { AchievementSection } from '../components/achievement/AchievementSection';
import { FloatingNavBar } from '../components/navigation/FloatingNavBar';
import { OverviewSection } from '../components/overview/OverviewSection';
import { ProfileSection } from '../components/profile/ProfileSection';
import { ScheduleSection } from '../components/schedule/ScheduleSection';
import {
  EventBlock,
  ReminderItem,
  ScheduleItem
} from '../common/PulsePlanModels';
import {
  NAV_AI,
  NAV_ACHIEVEMENT,
  NAV_ITEMS,
  NAV_OVERVIEW,
  NAV_PROFILE,
  NAV_SCHEDULE,
  BOARD_END_MINUTE,
  BOARD_START_MINUTE,
  PulsePalette,
  SNAP_MINUTES,
  VIEW_MONTH,
  VIEW_WEEK
} from '../common/PulsePlanTheme';
import {
  addDays,
  addMonths,
  clampMinute,
  formatDateTitle,
  getCompletionRate,
  getDateKey,
  getSchedulesForDay,
  getWeekMinutes,
  track
} from '../common/PulsePlanUtils';
import {
  createPlanFromPrompt,
  createSeedEventBlocks,
  createSeedReminders,
  createSeedSchedules,
  rebalanceDaySchedules
} from '../data/PulsePlanSeed';

AppStorage.setOrCreate('pulseplan_view_mode', VIEW_WEEK);
PersistentStorage.persistProp('pulseplan_view_mode', VIEW_WEEK);

@Component
export struct PulsePlanHome {
  @StorageLink('pulseplan_view_mode') currentViewIndex: number = VIEW_WEEK;
  @State currentNavIndex: number = NAV_SCHEDULE;
  @State selectedDateKey: string = getDateKey(new Date());
  @State eventBlocks: EventBlock[] = createSeedEventBlocks();
  @State scheduleItems: ScheduleItem[] = createSeedSchedules(createSeedEventBlocks());
  @State reminders: ReminderItem[] = createSeedReminders(createSeedSchedules(createSeedEventBlocks()));
  @State inputText: string = '下周三准备季度汇报，晚间预留 30 分钟复盘';
  @State lastPromptText: string = '';
  @State selectedScheduleId: number = 203;
  @State activeSceneMode: string = '';
  @State aiBanner: string = 'AI 已根据最近两周的拖拽与完成率，默认预留 20 分钟缓冲。';
  @State aiDetailMode: boolean = false;
  @State aiDetailShellVisible: boolean = false;
  api?: PulsePlanApi;
  onExit: () => void = () => {};
  @State serverBusy: boolean = false;
  @State serverMessage: string = '';
  @State pendingPlan: PlanPreview | undefined = undefined;
  @State profile: Profile | undefined = undefined;
  @State profileName: string = '';
  @State profileZone: string = '';
  @State achievementStats: AchievementStats | undefined = undefined;
  @State editing: boolean = false;
  @State editId: number = 0;
  @State editTitle: string = '';
  @State editStart: string = '09:00';
  @State editEnd: string = '09:30';
  @State editReminder: string = '';
  private refreshVersion: number = 0;
  private aiDetailShellTask: number = -1;
  private pageScroller: Scroller = new Scroller();
  @State topBarOpacity: number = 0.4;
  @State lastScrollOffset: number = 0;
  private readonly statusBarHeight: number = 44;

  aboutToAppear(): void {
    if (this.api) {
      this.eventBlocks = [];
      this.scheduleItems = [];
      this.reminders = [];
      this.selectedScheduleId = 0;
      this.inputText = '';
      this.aiBanner = '输入目标，生成可确认的 AI 排程建议。';
      this.refreshConnectedData();
      return;
    }
    const seedBlocks: EventBlock[] = createSeedEventBlocks();
    const seedSchedules: ScheduleItem[] = createSeedSchedules(seedBlocks);
    this.eventBlocks = seedBlocks;
    this.scheduleItems = seedSchedules;
    this.reminders = createSeedReminders(seedSchedules);
    this.selectedScheduleId = seedSchedules[2].id;
    track('page_open', 'pulseplan_single_page_prototype');
  }

  aboutToDisappear(): void {
    this.refreshVersion++;
    this.clearAIDetailShellTask();
  }

  private selectDate(date: string): void {
    this.selectedDateKey = date;
    if (this.api) {
      this.refreshConnectedData();
    }
  }

  private async refreshConnectedData(): Promise<void> {
    const api = this.api;
    if (!api) {
      return;
    }
    const version = ++this.refreshVersion;
    const day = this.selectedDateKey;
    try {
      const blocks = await api.blocks();
      const schedules = await api.schedules(addDays(day, -45), addDays(day, 46));
      const overview = await api.overview(day);
      const stats = await api.achievements();
      const profile = await api.profile();
      if (version !== this.refreshVersion) {
        return;
      }
      this.eventBlocks = blocks.map((block: EventBlock): EventBlock => ({
        id: block.id, title: block.title, scene: block.scene, color: block.color,
        preference: '', habitHint: '', aiHint: '', quickLaunch: ''
      }));
      this.scheduleItems = schedules.map((item: ScheduleItem): ScheduleItem => ({
        id: item.id, eventBlockId: item.eventBlockId, title: item.title, scene: item.scene, dayKey: item.dayKey,
        startMinute: item.startMinute, endMinute: item.endMinute, color: item.color, completed: item.completed,
        modeName: '', quickLaunch: '', aiSuggestion: '', flexibility: ''
      }));
      this.reminders = overview.reminders;
      this.achievementStats = stats;
      if (!this.profile) {
        this.profileName = profile.displayName;
        this.profileZone = profile.timeZone;
      }
      this.profile = profile;
      if (!this.getSelectedSchedule()) {
        const first = this.scheduleItems.find((item: ScheduleItem) => item.dayKey === day);
        this.selectedScheduleId = first ? first.id : 0;
      }
    } catch (error) {
      if (version === this.refreshVersion) {
        this.serverMessage = (error as Error).message;
      }
    }
  }

  private async runConnected(action: (api: PulsePlanApi) => Promise<void>): Promise<void> {
    const api = this.api;
    if (!api || this.serverBusy) {
      return;
    }
    this.serverBusy = true;
    this.serverMessage = '';
    try {
      await action(api);
    } catch (error) {
      this.serverMessage = (error as Error).message;
    } finally {
      this.serverBusy = false;
    }
  }

  private saveScheduleChange(id: number, input: ScheduleChange): void {
    this.runConnected(async (api: PulsePlanApi) => {
      const saved = await api.changeSchedule(id, input);
      this.selectedDateKey = saved.dayKey;
      this.selectedScheduleId = saved.id;
      await this.refreshConnectedData();
    });
  }

  private generateConnectedPlan(prompt: string): void {
    this.getUIContext().getFocusController().clearFocus();
    this.runConnected(async (api: PulsePlanApi) => {
      this.pendingPlan = await api.generate(prompt, this.selectedDateKey);
      this.lastPromptText = prompt;
    });
  }

  private confirmConnectedPlan(): void {
    const plan = this.pendingPlan;
    if (!plan) {
      return;
    }
    this.runConnected(async (api: PulsePlanApi) => {
      const items = await api.confirm(plan.id);
      this.pendingPlan = undefined;
      this.inputText = '';
      if (items.length > 0) {
        this.selectedDateKey = items[0].dayKey;
        this.selectedScheduleId = items[0].id;
      }
      this.aiBanner = '已保存 ' + items.length + ' 条 AI 排程。';
      this.resetAIDetailShell();
      this.currentNavIndex = NAV_SCHEDULE;
      await this.refreshConnectedData();
    });
  }

  private openEditor(id: number): void {
    const item = id === 0 ? undefined : this.getSelectedSchedule();
    this.editId = item ? item.id : 0;
    this.editTitle = item ? item.title : '';
    this.editStart = item ? this.displayTime(item.startMinute) : '09:00';
    this.editEnd = item ? this.displayTime(item.endMinute) : '09:30';
    const reminder = this.reminders.find((entry: ReminderItem) => entry.scheduleItemId === this.editId);
    this.editReminder = reminder ? this.displayTime(reminder.minute) : '';
    this.editing = true;
  }

  private displayTime(minute: number): string {
    const hour = Math.floor(minute / 60);
    const remainder = minute % 60;
    return (hour < 10 ? '0' : '') + hour + ':' + (remainder < 10 ? '0' : '') + remainder;
  }

  private parseTime(value: string): number {
    if (value === '24:00') {
      return 1440;
    }
    if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(value)) {
      return -1;
    }
    const parts = value.split(':');
    return Number(parts[0]) * 60 + Number(parts[1]);
  }

  private saveEditor(): void {
    const start = this.parseTime(this.editStart);
    const end = this.parseTime(this.editEnd);
    const title = this.editTitle.trim();
    if (title.length === 0 || start < 0 || end <= start) {
      this.serverMessage = '请输入标题和有效的开始、结束时间，格式为 HH:mm。';
      return;
    }
    const id = this.editId;
    const day = this.selectedDateKey;
    this.runConnected(async (api: PulsePlanApi) => {
      const input: ScheduleChange = { title: title, startMinute: start, endMinute: end };
      let saved: ScheduleItem;
      if (id > 0) {
        saved = await api.changeSchedule(id, input);
      } else {
        input.dayKey = day;
        saved = await api.createSchedule(input);
      }
      this.selectedScheduleId = saved.id;
      this.editing = false;
      await this.refreshConnectedData();
    });
  }

  private removeSelected(): void {
    const item = this.scheduleItems.find((schedule: ScheduleItem) => schedule.id === this.editId);
    if (!item) {
      return;
    }
    this.runConnected(async (api: PulsePlanApi) => {
      await api.deleteSchedule(item.id);
      this.editing = false;
      await this.refreshConnectedData();
    });
  }

  private saveReminder(): void {
    const id = this.editId;
    const minute = this.parseTime(this.editReminder);
    if (id === 0 || minute < 0 || minute >= 1440) {
      this.serverMessage = '请输入有效的提醒时间，格式为 HH:mm。';
      return;
    }
    const input: ReminderInput = { title: this.editTitle, minute: minute, intensity: '普通' };
    this.runConnected(async (api: PulsePlanApi) => {
      await api.setReminders(id, [input]);
      await this.refreshConnectedData();
    });
  }

  private saveProfile(): void {
    const input: ProfileUpdate = { displayName: this.profileName, timeZone: this.profileZone };
    this.runConnected(async (api: PulsePlanApi) => {
      const profile = await api.updateProfile(input);
      this.profile = profile;
      this.profileName = profile.displayName;
      this.profileZone = profile.timeZone;
      this.serverMessage = '个人设置已保存。';
    });
  }

  private exitAccount(): void {
    this.runConnected(async (api: PulsePlanApi) => {
      try {
        await api.logout();
      } finally {
        this.onExit();
      }
    });
  }

  @Builder
  private connectedOverview(): void {
    Column({ space: 12 }) {
      Text('日程概览').fontSize(24).fontColor(PulsePalette.textPrimary)
      Text('今日完成 ' + this.getTodayCompletion()).fontColor(PulsePalette.textSecondary)
      Text('本周已安排 ' + this.getWeekFocusHours()).fontColor(PulsePalette.textSecondary)
      if (this.eventBlocks.length > 0) {
        Text('事件块').fontSize(18).fontColor(PulsePalette.textPrimary)
        ForEach(this.eventBlocks, (block: EventBlock) => {
          Button(block.title).onClick(() => {
            this.handleSelectEventBlock(block.id);
            this.currentNavIndex = NAV_SCHEDULE;
          })
        }, (block: EventBlock) => block.id.toString())
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private connectedAi(): void {
    Column({ space: 14 }) {
      Text('AI 排程').fontSize(24).fontColor(PulsePalette.textPrimary)
      Text('告诉我目标、日期和预计时长。确认建议后，日程才会保存。')
        .fontColor(PulsePalette.textSecondary)
      TextArea({ placeholder: '例如：明天下午安排 30 分钟阅读', text: this.inputText })
        .height(110)
        .backgroundColor(PulsePalette.surfaceRaised)
        .fontColor(PulsePalette.textPrimary)
        .placeholderColor(PulsePalette.textSecondary)
        .caretColor(PulsePalette.accentSky)
        .onChange((value: string) => { this.inputText = value; })
      Button(this.serverBusy ? '正在生成…' : '生成排程')
        .enabled(!this.serverBusy && this.inputText.trim().length > 0)
        .onClick(() => { this.handleCreateFromPrompt(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private connectedEditor(): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Button('新增日程').enabled(!this.serverBusy).onClick(() => { this.openEditor(0); })
        Button('编辑日程').enabled(!this.serverBusy && this.selectedScheduleId > 0)
          .onClick(() => { this.openEditor(this.selectedScheduleId); })
      }
      if (this.editing) {
        TextInput({ placeholder: '日程标题', text: this.editTitle })
          .backgroundColor(PulsePalette.surfaceRaised)
          .fontColor(PulsePalette.textPrimary)
          .placeholderColor(PulsePalette.textSecondary)
          .caretColor(PulsePalette.accentSky)
          .border({ width: 1, color: PulsePalette.borderStrong })
          .onChange((value: string) => { this.editTitle = value; })
        Row({ space: 8 }) {
          TextInput({ placeholder: '开始 HH:mm', text: this.editStart }).layoutWeight(1)
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .placeholderColor(PulsePalette.textSecondary)
            .caretColor(PulsePalette.accentSky)
            .border({ width: 1, color: PulsePalette.borderStrong })
            .onChange((value: string) => { this.editStart = value; })
          TextInput({ placeholder: '结束 HH:mm', text: this.editEnd }).layoutWeight(1)
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .placeholderColor(PulsePalette.textSecondary)
            .caretColor(PulsePalette.accentSky)
            .border({ width: 1, color: PulsePalette.borderStrong })
            .onChange((value: string) => { this.editEnd = value; })
        }
        Row({ space: 8 }) {
          Button('保存').enabled(!this.serverBusy).onClick(() => { this.saveEditor(); })
          Button('取消').enabled(!this.serverBusy).onClick(() => { this.editing = false; })
          if (this.editId > 0) {
            Button('删除日程').enabled(!this.serverBusy).onClick(() => { this.removeSelected(); })
          }
        }
        if (this.editId > 0) {
          Row({ space: 8 }) {
            TextInput({ placeholder: '提醒 HH:mm', text: this.editReminder }).layoutWeight(1)
              .backgroundColor(PulsePalette.surfaceRaised)
              .fontColor(PulsePalette.textPrimary)
              .placeholderColor(PulsePalette.textSecondary)
              .caretColor(PulsePalette.accentSky)
              .border({ width: 1, color: PulsePalette.borderStrong })
              .onChange((value: string) => { this.editReminder = value; })
            Button('保存提醒').enabled(!this.serverBusy).onClick(() => { this.saveReminder(); })
          }
        }
      }
    }
    .width('100%')
  }

  @Builder
  private connectedAchievements(): void {
    Column({ space: 10 }) {
      Text('成就').fontSize(24).fontColor(PulsePalette.textPrimary)
      if (this.achievementStats) {
        Text('已完成日程 ' + this.achievementStats.completed + ' / ' + this.achievementStats.total)
          .fontColor(PulsePalette.textPrimary)
        Text('有完成记录的天数 ' + this.achievementStats.activeDays).fontColor(PulsePalette.textPrimary)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private connectedProfile(): void {
    Column({ space: 10 }) {
      if (this.profile) {
        Text(this.profile.username).fontSize(24).fontColor(PulsePalette.textPrimary)
        TextInput({ placeholder: '显示名称', text: this.profileName })
          .backgroundColor(PulsePalette.surfaceRaised)
          .fontColor(PulsePalette.textPrimary)
          .placeholderColor(PulsePalette.textSecondary)
          .caretColor(PulsePalette.accentSky)
          .border({ width: 1, color: PulsePalette.borderStrong })
          .onChange((value: string) => { this.profileName = value; })
        TextInput({ placeholder: '时区，例如 Asia/Shanghai', text: this.profileZone })
          .backgroundColor(PulsePalette.surfaceRaised)
          .fontColor(PulsePalette.textPrimary)
          .placeholderColor(PulsePalette.textSecondary)
          .caretColor(PulsePalette.accentSky)
          .border({ width: 1, color: PulsePalette.borderStrong })
          .onChange((value: string) => { this.profileZone = value; })
        Button('保存设置').enabled(!this.serverBusy).onClick(() => { this.saveProfile(); })
      }
      Button('退出登录').enabled(!this.serverBusy).onClick(() => { this.exitAccount(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private serverFeedback(): void {
    Column({ space: 8 }) {
      if (this.serverMessage.length > 0) {
        Text(this.serverMessage).fontColor(PulsePalette.textPrimary)
        Button('关闭提示').onClick(() => { this.serverMessage = ''; })
      }
      if (this.pendingPlan) {
        Text(this.pendingPlan.title).fontSize(18).fontColor(PulsePalette.textPrimary)
        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.pendingPlan.items, (item: PlanItem) => {
              Text(item.dayKey + ' ' + this.displayTime(item.startMinute) + '–' +
                this.displayTime(item.endMinute) + ' ' + item.title).fontColor(PulsePalette.textPrimary)
            }, (item: PlanItem) => item.dayKey + ':' + item.startMinute)
          }
        }
        .constraintSize({ maxHeight: 210 })
        Row({ space: 8 }) {
          Button('确认保存').enabled(!this.serverBusy).onClick(() => { this.confirmConnectedPlan(); })
          Button('取消').enabled(!this.serverBusy).onClick(() => { this.pendingPlan = undefined; })
        }
      }
    }
    .width('90%')
    .padding(12)
    .margin({ bottom: 76 })
    .borderRadius(14)
    .backgroundColor(PulsePalette.background)
  }

  private scrollToPageTop(): void {
    this.pageScroller.scrollEdge(Edge.Top);
  }

  private getSelectedSchedule(): ScheduleItem | undefined {
    return this.scheduleItems.find((item: ScheduleItem) => item.id === this.selectedScheduleId);
  }

  private getSelectedEventBlock(): EventBlock | undefined {
    const selected: ScheduleItem | undefined = this.getSelectedSchedule();
    if (!selected) {
      return undefined;
    }
    return this.eventBlocks.find((item: EventBlock) => item.id === selected.eventBlockId);
  }

  private getTodayCompletion(): string {
    const todayItems: ScheduleItem[] = getSchedulesForDay(this.scheduleItems, this.selectedDateKey);
    if (todayItems.length === 0) {
      return '0 / 0';
    }
    const completed: number = todayItems.filter((item: ScheduleItem) => item.completed).length;
    return `${completed} / ${todayItems.length}`;
  }

  private getWeekFocusHours(): string {
    return `${(getWeekMinutes(this.scheduleItems, this.selectedDateKey) / 60).toFixed(1)}h`;
  }

  private getCurrentNavLabel(): string {
    return NAV_ITEMS[this.currentNavIndex].label;
  }

  private getTopSummary(): string {
    if (this.currentNavIndex === NAV_SCHEDULE) {
      return `本周专注 ${this.getWeekFocusHours()} · 今日完成 ${this.getTodayCompletion()}`;
    }
    if (this.currentNavIndex === NAV_OVERVIEW) {
      return '查看本周主线、关键指标与事件块进展';
    }
    if (this.currentNavIndex === NAV_AI) {
      return '自然语言创建、习惯记忆与 AI 编排建议';
    }
    if (this.currentNavIndex === NAV_ACHIEVEMENT) {
      return `当前总完成率 ${getCompletionRate(this.scheduleItems)}% · 连续反馈已同步`;
    }
    return this.activeSceneMode.length > 0 ? `当前场景：${this.activeSceneMode}` : '偏好、设备协同与资料管理';
  }

  private getTopTag(): string {
    if (this.currentNavIndex === NAV_SCHEDULE) {
      return '当前主工作台';
    }
    if (this.currentNavIndex === NAV_AI) {
      return 'AI 能力区';
    }
    if (this.currentNavIndex === NAV_ACHIEVEMENT) {
      return '反馈系统';
    }
    if (this.currentNavIndex === NAV_PROFILE) {
      return '个人中心';
    }
    return '总览';
  }

  private isAIDetailPage(): boolean {
    return this.currentNavIndex === NAV_AI && (this.aiDetailMode || this.aiDetailShellVisible);
  }

  private clearAIDetailShellTask(): void {
    if (this.aiDetailShellTask >= 0) {
      clearTimeout(this.aiDetailShellTask);
      this.aiDetailShellTask = -1;
    }
  }

  private resetAIDetailShell(): void {
    this.clearAIDetailShellTask();
    this.aiDetailMode = false;
    this.aiDetailShellVisible = false;
  }

  private openAIDetail(prompt: string): void {
    if (prompt.length > 0) {
      this.inputText = prompt;
    }
    this.clearAIDetailShellTask();
    this.aiDetailShellVisible = true;
    this.aiDetailMode = true;
    this.scrollToPageTop();
    track('ai_detail_open', prompt.length > 0 ? prompt : 'empty');
  }

  private closeAIDetail(): void {
    this.clearAIDetailShellTask();
    this.aiDetailMode = false;
    this.scrollToPageTop();
    track('ai_detail_close', 'back');
    this.aiDetailShellTask = setTimeout(() => {
      if (this.currentNavIndex === NAV_AI && !this.aiDetailMode) {
        this.aiDetailShellVisible = false;
      }
      this.aiDetailShellTask = -1;
    }, 320);
  }

  private changeView(index: number): void {
    this.currentViewIndex = index;
    track('view_changed', `${index}`);
  }

  private shiftTimeline(offset: number): void {
    if (this.currentViewIndex === VIEW_MONTH) {
      this.selectDate(addMonths(this.selectedDateKey, offset));
      return;
    }
    this.selectDate(addDays(this.selectedDateKey, this.currentViewIndex === VIEW_WEEK ? offset * 7 : offset));
  }

  private handleSelectSchedule(scheduleId: number): void {
    this.selectedScheduleId = scheduleId;
    track('schedule_selected', `${scheduleId}`);
  }

  private handleSelectEventBlock(eventBlockId: number): void {
    const matched: ScheduleItem | undefined =
      this.scheduleItems.find((item: ScheduleItem) => item.eventBlockId === eventBlockId);
    if (matched) {
      this.selectedScheduleId = matched.id;
      this.selectDate(matched.dayKey);
    }
    track('event_block_selected', `${eventBlockId}`);
  }

  private handleMoveSchedule(scheduleId: number, targetDayKey: string, targetStartMinute: number): void {
    const target: ScheduleItem | undefined = this.scheduleItems.find((item: ScheduleItem) => item.id === scheduleId);
    if (!target) {
      return;
    }
    const duration: number = target.endMinute - target.startMinute;
    const nextStart: number = clampMinute(
      Math.round(targetStartMinute / SNAP_MINUTES) * SNAP_MINUTES,
      BOARD_START_MINUTE,
      BOARD_END_MINUTE - duration
    );
    if (this.api) {
      this.saveScheduleChange(scheduleId, { dayKey: targetDayKey, startMinute: nextStart, endMinute: nextStart + duration });
      return;
    }
    this.selectedDateKey = targetDayKey;
    this.scheduleItems = this.scheduleItems.map((item: ScheduleItem) => {
      if (item.id !== scheduleId) {
        return item;
      }
      return {
        id: item.id,
        eventBlockId: item.eventBlockId,
        title: item.title,
        scene: item.scene,
        dayKey: targetDayKey,
        startMinute: nextStart,
        endMinute: nextStart + duration,
        color: item.color,
        modeName: item.modeName,
        quickLaunch: item.quickLaunch,
        aiSuggestion: item.aiSuggestion,
        flexibility: item.flexibility,
        completed: item.completed
      };
    }).sort((left: ScheduleItem, right: ScheduleItem) => left.dayKey === right.dayKey ? left.startMinute - right.startMinute : left.dayKey.localeCompare(right.dayKey));
    track('schedule_dragged', `${scheduleId}`);
  }

  private handleResizeSchedule(scheduleId: number, minuteDelta: number): void {
    if (this.api) {
      const item = this.scheduleItems.find((schedule: ScheduleItem) => schedule.id === scheduleId);
      if (item) {
        const end = clampMinute(Math.round((item.endMinute + minuteDelta) / SNAP_MINUTES) * SNAP_MINUTES,
          item.startMinute + SNAP_MINUTES, BOARD_END_MINUTE);
        this.saveScheduleChange(scheduleId, { endMinute: end });
      }
      return;
    }
    this.scheduleItems = this.scheduleItems.map((item: ScheduleItem) => {
      if (item.id !== scheduleId) {
        return item;
      }
      const nextEnd: number = clampMinute(
        Math.round((item.endMinute + minuteDelta) / SNAP_MINUTES) * SNAP_MINUTES,
        item.startMinute + SNAP_MINUTES,
        BOARD_END_MINUTE
      );
      return {
        id: item.id,
        eventBlockId: item.eventBlockId,
        title: item.title,
        scene: item.scene,
        dayKey: item.dayKey,
        startMinute: item.startMinute,
        endMinute: nextEnd,
        color: item.color,
        modeName: item.modeName,
        quickLaunch: item.quickLaunch,
        aiSuggestion: item.aiSuggestion,
        flexibility: item.flexibility,
        completed: item.completed
      };
    });
    track('schedule_resized', `${scheduleId}`);
  }

  private handleCreateFromPrompt(): void {
    if (this.inputText.trim().length === 0) {
      return;
    }
    const normalizedPrompt: string = this.inputText.trim();
    if (this.api) {
      this.generateConnectedPlan(normalizedPrompt);
      return;
    }
    const plan = createPlanFromPrompt(normalizedPrompt, this.selectedDateKey, this.scheduleItems);
    this.eventBlocks = [plan.eventBlock, ...this.eventBlocks];
    this.scheduleItems = [...this.scheduleItems, ...plan.scheduleItems]
      .sort((left: ScheduleItem, right: ScheduleItem) => left.dayKey === right.dayKey ? left.startMinute - right.startMinute : left.dayKey.localeCompare(right.dayKey));
    this.reminders = [...plan.reminders, ...this.reminders].slice(0, 12);
    this.selectedScheduleId = plan.scheduleItems[0].id;
    this.lastPromptText = normalizedPrompt;
    this.aiBanner = `AI 已完成 ${plan.scheduleItems.length} 个日程块编排，并预留 ${plan.bufferMinutes} 分钟缓冲。`;
    this.inputText = '';
    this.scrollToPageTop();
    track('ai_plan_generated', plan.eventBlock.title);
  }

  private handleEmergencyInsert(): void {
    if (this.api) {
      this.generateConnectedPlan('今天安排一个 30 分钟的紧急事项，尽量使用最早的空闲时段。');
      return;
    }
    const urgentItem: ScheduleItem = {
      id: Number(`${Date.now()}88`),
      eventBlockId: 101,
      title: '紧急插入 · 临时任务',
      scene: '工作',
      dayKey: this.selectedDateKey,
      startMinute: 9 * 60,
      endMinute: 9 * 60 + 30,
      color: '#FF6F61',
      modeName: '会议模式',
      quickLaunch: '打开临时议程',
      aiSuggestion: '系统已插入应急任务，并尽量保持原有排程稳定。',
      flexibility: '刚性',
      completed: false
    };
    this.scheduleItems = rebalanceDaySchedules([...this.scheduleItems, urgentItem], this.selectedDateKey);
    this.lastPromptText = '今天插入一个紧急任务，尽量少打乱原计划';
    this.selectedScheduleId = urgentItem.id;
    this.aiBanner = '应急插入完成，周视图已自动重排。';
    track('emergency_inserted', this.selectedDateKey);
  }

  private handleToggleComplete(): void {
    const selected: ScheduleItem | undefined = this.getSelectedSchedule();
    if (!selected) {
      return;
    }
    const nextCompleted: boolean = !selected.completed;
    if (this.api) {
      this.saveScheduleChange(selected.id, { completed: nextCompleted });
      return;
    }
    this.scheduleItems = this.scheduleItems.map((item: ScheduleItem) => {
      if (item.id !== selected.id) {
        return item;
      }
      return {
        id: item.id,
        eventBlockId: item.eventBlockId,
        title: item.title,
        scene: item.scene,
        dayKey: item.dayKey,
        startMinute: item.startMinute,
        endMinute: item.endMinute,
        color: item.color,
        modeName: item.modeName,
        quickLaunch: item.quickLaunch,
        aiSuggestion: item.aiSuggestion,
        flexibility: item.flexibility,
        completed: nextCompleted
      };
    });
    this.aiBanner = nextCompleted ? '完成已记录，成就链与事件块进度同步更新。' : '已取消完成标记。';
    track('schedule_completed_toggled', `${selected.id}`);
  }

  private handleLaunchSceneMode(): void {
    const selected: ScheduleItem | undefined = this.getSelectedSchedule();
    if (!selected) {
      return;
    }
    this.activeSceneMode = selected.modeName;
    this.aiBanner = `${selected.modeName} 已激活：将模拟免打扰、工具直达与手表打卡。`;
    track('scene_mode_started', selected.modeName);
  }

  private handleQuickLaunch(): void {
    const selected: ScheduleItem | undefined = this.getSelectedSchedule();
    if (!selected) {
      return;
    }
    this.aiBanner = `已直达 ${selected.quickLaunch}，进入执行态。`;
    track('quick_launch', selected.quickLaunch);
  }

  @Builder
  private buildTopBanner(): void {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text('PulsePlan')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textMuted)

          Text('/')
            .fontSize(12)
            .fontColor(PulsePalette.navIdle)

          Text(this.getCurrentNavLabel())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(PulsePalette.textPrimary)
        }

        Text(this.getTopSummary())
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text(this.getTopTag())
          .fontSize(11)
          .fontColor(PulsePalette.blackText)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(PulsePalette.accentSky)
          .borderRadius(14)

        Text(this.api ? '已连接服务' : '本地演示')
          .fontSize(11)
          .fontColor(PulsePalette.textMuted)
      }
      .alignItems(HorizontalAlign.End)
    }
    .padding({ left: 4, right: 4, top: 2, bottom: 4 })
  }

  @Builder
  private buildCurrentSection(): void {
    if (this.currentNavIndex === NAV_OVERVIEW && this.api) {
      this.connectedOverview()
    } else if (this.currentNavIndex === NAV_OVERVIEW) {
      OverviewSection({
        bannerText: this.aiBanner,
        todayCompletion: this.getTodayCompletion(),
        weekFocusHours: this.getWeekFocusHours(),
        completionRate: `${getCompletionRate(this.scheduleItems)}%`,
        activeSceneMode: this.activeSceneMode,
        selectedDateTitle: formatDateTitle(this.selectedDateKey),
        eventBlocks: this.eventBlocks,
        scheduleItems: this.scheduleItems,
        selectedEventBlockId: this.getSelectedEventBlock() ? this.getSelectedEventBlock()!.id : 0,
        onSelectEventBlock: (eventBlockId: number) => {
          this.handleSelectEventBlock(eventBlockId);
        }
      })
    } else if (this.currentNavIndex === NAV_SCHEDULE) {
      if (this.api) {
        this.connectedEditor()
      }
      ScheduleSection({
        currentViewIndex: this.currentViewIndex,
        selectedDateKey: this.selectedDateKey,
        scheduleItems: this.scheduleItems,
        eventBlocks: this.eventBlocks,
        reminders: this.reminders,
        inputText: this.inputText,
        selectedScheduleId: this.selectedScheduleId,
        activeSceneMode: this.activeSceneMode,
        onInputChange: (value: string) => {
          this.inputText = value;
        },
        onCreatePlan: () => {
          this.handleCreateFromPrompt();
        },
        onEmergencyInsert: () => {
          this.handleEmergencyInsert();
        },
        onChangeView: (index: number) => {
          this.changeView(index);
        },
        onShiftTimeline: (offset: number) => {
          this.shiftTimeline(offset);
        },
        onSelectSchedule: (scheduleId: number) => {
          this.handleSelectSchedule(scheduleId);
        },
        onMoveSchedule: (scheduleId: number, targetDayKey: string, targetStartMinute: number) => {
          this.handleMoveSchedule(scheduleId, targetDayKey, targetStartMinute);
        },
        onResizeSchedule: (scheduleId: number, minuteDelta: number) => {
          this.handleResizeSchedule(scheduleId, minuteDelta);
        },
        onSelectDay: (dateKey: string) => {
          this.selectDate(dateKey);
        },
        onToggleComplete: () => {
          this.handleToggleComplete();
        },
        onLaunchScene: () => {
          this.handleLaunchSceneMode();
        },
        onQuickLaunch: () => {
          this.handleQuickLaunch();
        },
        onSelectEventBlock: (eventBlockId: number) => {
          this.handleSelectEventBlock(eventBlockId);
        }
      })
    } else if (this.currentNavIndex === NAV_AI && this.api) {
      this.connectedAi()
    } else if (this.currentNavIndex === NAV_AI) {
      AISection({
        inputText: this.inputText,
        lastPromptText: this.lastPromptText,
        selectedDateKey: this.selectedDateKey,
        selectedScheduleId: this.selectedScheduleId,
        eventBlocks: this.eventBlocks,
        scheduleItems: this.scheduleItems,
        reminders: this.reminders,
        activeSceneMode: this.activeSceneMode,
        aiBanner: this.aiBanner,
        detailMode: this.aiDetailMode,
        onInputChange: (value: string) => {
          this.inputText = value;
        },
        onGenerate: () => {
          this.handleCreateFromPrompt();
        },
        onEmergencyInsert: () => {
          this.handleEmergencyInsert();
        },
        onOpenSchedule: () => {
          this.resetAIDetailShell();
          this.currentNavIndex = NAV_SCHEDULE;
          this.scrollToPageTop();
          track('nav_changed', 'schedule_from_ai');
        },
        onLaunchScene: () => {
          this.handleLaunchSceneMode();
        },
        onQuickLaunch: () => {
          this.handleQuickLaunch();
        },
        onToggleComplete: () => {
          this.handleToggleComplete();
        },
        onEnterDetail: (prompt: string) => {
          this.openAIDetail(prompt);
        },
        onCloseDetail: () => {
          this.closeAIDetail();
        }
      })
    } else if (this.currentNavIndex === NAV_ACHIEVEMENT && this.api) {
      this.connectedAchievements()
    } else if (this.currentNavIndex === NAV_PROFILE && this.api) {
      this.connectedProfile()
    } else if (this.currentNavIndex === NAV_ACHIEVEMENT) {
      AchievementSection({
        scheduleItems: this.scheduleItems,
        selectedDateKey: this.selectedDateKey
      })
    } else if (this.currentNavIndex === NAV_PROFILE) {
      ProfileSection({
        activeSceneMode: this.activeSceneMode,
        eventBlocks: this.eventBlocks,
        scheduleItems: this.scheduleItems,
        selectedScheduleId: this.selectedScheduleId
      })
      Button('返回登录').onClick(() => { this.onExit(); })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(PulsePalette.background)

        Column()
          .width(220)
          .height(220)
          .backgroundColor(PulsePalette.glowSky)
          .opacity(0.16)
          .borderRadius(110)
          .position({ x: -70, y: -20 })

        Column()
          .width(260)
          .height(260)
          .backgroundColor(PulsePalette.glowWarm)
          .opacity(0.14)
          .borderRadius(130)
          .position({ x: 180, y: 340 })

        if (this.isAIDetailPage()) {
          Column() {
            this.buildCurrentSection()
          }
          .width('100%')
          .height('100%')
          .padding({ left: 0, right: 0, top: this.statusBarHeight + 18, bottom: 0 })
        } else if (this.currentNavIndex === NAV_AI) {
          Column({ space: 18 }) {
            this.buildCurrentSection()
          }
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16, top: this.statusBarHeight + 18, bottom: 76 })
        } else {
          Scroll(this.pageScroller) {
            Column({ space: 18 }) {
              if (this.currentNavIndex !== NAV_AI) {
                this.buildTopBanner()
              }
              this.buildCurrentSection()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: this.statusBarHeight + 18, bottom: 76 })
          }
          .scrollBar(BarState.Off)
          .onScroll((xOffset: number, yOffset: number) => {
            const currentOffset = this.pageScroller.currentOffset().yOffset;
            if (currentOffset > this.lastScrollOffset) {
              this.topBarOpacity = Math.min(0.8, this.topBarOpacity + 0.02);
            } else if (currentOffset < this.lastScrollOffset) {
              this.topBarOpacity = Math.max(0.2, this.topBarOpacity - 0.02);
            }
            this.lastScrollOffset = currentOffset;
          })
        }
      }
      .width('100%')
      .height('100%')

      if (!this.isAIDetailPage()) {
        Column()
          .width('100%')
          .height(this.statusBarHeight)
          .position({ x: 0, y: 0 })
          .backgroundColor(PulsePalette.background)
          .opacity(this.topBarOpacity)
          .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
      }

      if (this.api && (this.pendingPlan || this.serverMessage.length > 0)) {
        this.serverFeedback()
      }

      FloatingNavBar({
        items: NAV_ITEMS,
        currentIndex: this.currentNavIndex,
        onChange: (index: number) => {
          this.resetAIDetailShell();
          this.currentNavIndex = index;
          this.scrollToPageTop();
          this.topBarOpacity = 0.4;
          track('nav_changed', NAV_ITEMS[index].key);
        }
      })
      .translate({ x: 0, y: this.isAIDetailPage() ? 180 : 0 })
      .opacity(this.isAIDetailPage() ? 0 : 1)
      .animation({ duration: 380, curve: Curve.Friction })
      .margin({ left: 16, right: 16, bottom: 8 })
    }
  }
}
