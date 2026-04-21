import { EventBlock, ReminderItem, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';
import {
  addDays,
  formatDateTitle,
  formatMinuteLabel,
  getCompletionRate,
  getSchedulesForDay,
  getWeekMinutes,
  track
} from '../../common/PulsePlanUtils';

interface PromptPreset {
  title: string;
  prompt: string;
  detail: string;
}

interface LogicPoint {
  title: string;
  detail: string;
}

const AI_PROMPT_PRESETS: PromptPreset[] = [
  {
    title: '按习惯排明天',
    prompt: '帮我按最近习惯把明天的学习和工作都排出来',
    detail: '从已有日程和偏好直接生成第一版方案'
  },
  {
    title: '分析规划习惯',
    prompt: '分析我最近的规划习惯，并给我优化建议',
    detail: '总结高效时段、节奏密度和缓冲偏好'
  },
  {
    title: '插入紧急任务',
    prompt: '今天下午插入一个 45 分钟紧急任务，尽量别打乱主线',
    detail: '用最小扰动策略自动重排'
  },
  {
    title: '生成情景模式',
    prompt: '为我的重点任务生成一个可直接启动的情景模式',
    detail: '把执行建议、入口和场景一起挂上去'
  }
];

const AI_LOGIC_POINTS: LogicPoint[] = [
  {
    title: '个性化排程',
    detail: '把分块密度、时间弹性和习惯画像都收进对话结果'
  },
  {
    title: '时间成本清减',
    detail: '创建、排程、插队都在同一条对话里完成'
  },
  {
    title: '成就反馈',
    detail: '完成后立刻更新连续表现、进度和行为曲线'
  },
  {
    title: '执行直达',
    detail: '文档、会议、学习平台入口都能挂在当前任务上'
  },
  {
    title: '情景搭建',
    detail: '会议、写作、学习、记录等模式可由 AI 直接启动'
  },
  {
    title: '设备协同',
    detail: '手机负责编排，手表负责提醒、打卡和状态回传'
  }
];

interface ChatMessage {
  id: string;
  isUser: boolean;
  content: string;
  timestamp: number;
  visible: boolean;
}

interface DisplaySection {
  id: string;
  type: 'plan' | 'execution' | 'capability';
  visible: boolean;
}

@Component
export struct AIDetailSection {
  @Prop inputText: string = '';
  @State localInputText: string = '';
  @State chatMessages: ChatMessage[] = [];
  @State displaySections: DisplaySection[] = [];
  lastPromptText: string = '';
  @Prop selectedDateKey: string = '';
  @Prop selectedScheduleId: number = 0;
  @Prop eventBlocks: EventBlock[] = [];
  @Prop scheduleItems: ScheduleItem[] = [];
  @Prop reminders: ReminderItem[] = [];
  @Prop activeSceneMode: string = '';
  @Prop aiBanner: string = '';
  onInputChange: (value: string) => void = (_: string) => {
  };
  onGenerate: () => void = () => {
  };
  onEmergencyInsert: () => void = () => {
  };
  onOpenSchedule: () => void = () => {
  };
  onLaunchScene: () => void = () => {
  };
  onQuickLaunch: () => void = () => {
  };
  onToggleComplete: () => void = () => {
  };
  onCloseDetail: () => void = () => {
  };
  private detailScroller: Scroller = new Scroller();
  private detailScrollTask: number = -1;

  aboutToAppear(): void {
    this.displaySections = [];
    this.chatMessages = [];
    this.localInputText = this.inputText;
  }

  aboutToDisappear(): void {
    this.clearDetailScrollTask();
  }

  private clearDetailScrollTask(): void {
    if (this.detailScrollTask >= 0) {
      clearTimeout(this.detailScrollTask);
      this.detailScrollTask = -1;
    }
  }

  private scheduleScrollToLatest(delay: number = 260): void {
    this.clearDetailScrollTask();
    this.detailScrollTask = setTimeout(() => {
      this.detailScroller.scrollEdge(Edge.Bottom);
      this.detailScrollTask = setTimeout(() => {
        this.detailScroller.scrollEdge(Edge.Bottom);
        this.detailScrollTask = -1;
      }, 100);
    }, delay);
  }

  private handleSendMessage(): void {
    const trimmedText = this.localInputText.trim();
    if (trimmedText.length === 0) {
      return;
    }
    
    const userMessage: ChatMessage = {
      id: `user_${Date.now()}`,
      isUser: true,
      content: trimmedText,
      timestamp: Date.now(),
      visible: true
    };
    this.chatMessages = [...this.chatMessages, userMessage];
    
    this.lastPromptText = trimmedText;
    this.onInputChange(trimmedText);
    
    this.localInputText = '';
    
    this.onGenerate();
    
    setTimeout(() => {
      const aiMessage: ChatMessage = {
        id: `ai_${Date.now()}`,
        isUser: false,
        content: '您好，我有什么可以帮您的？',
        timestamp: Date.now(),
        visible: true
      };
      this.chatMessages = [...this.chatMessages, aiMessage];
      
      setTimeout(() => {
        this.scheduleScrollToLatest(50);
      }, 100);
      
      this.displaySections = [];
      
      setTimeout(() => {
        this.displaySections = [...this.displaySections, { id: 'plan', type: 'plan', visible: true }];
        setTimeout(() => {
          this.scheduleScrollToLatest(50);
        }, 50);
      }, 600);
      
      setTimeout(() => {
        this.displaySections = [...this.displaySections, { id: 'execution', type: 'execution', visible: true }];
        setTimeout(() => {
          this.scheduleScrollToLatest(50);
        }, 50);
      }, 1200);
      
      setTimeout(() => {
        this.displaySections = [...this.displaySections, { id: 'capability', type: 'capability', visible: true }];
        setTimeout(() => {
          this.scheduleScrollToLatest(50);
        }, 50);
      }, 1800);
    }, 500);
  }

  private getPromptEcho(): string {
    if (this.chatMessages.length > 0) {
      const lastUserMessage = this.chatMessages.filter(m => m.isUser).pop();
      if (lastUserMessage) {
        return lastUserMessage.content;
      }
    }
    if (this.localInputText.trim().length > 0) {
      return this.localInputText.trim();
    }
    return this.lastPromptText.trim();
  }

  private containsPromptKeyword(keywords: string[]): boolean {
    const lowerPrompt: string = this.getPromptEcho().toLowerCase();
    for (let index: number = 0; index < keywords.length; index++) {
      if (lowerPrompt.includes(keywords[index])) {
        return true;
      }
    }
    return false;
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

  private getRelatedSchedules(): ScheduleItem[] {
    const selected: ScheduleItem | undefined = this.getSelectedSchedule();
    if (!selected) {
      return [];
    }
    return this.scheduleItems
      .filter((item: ScheduleItem) => item.eventBlockId === selected.eventBlockId)
      .sort((left: ScheduleItem, right: ScheduleItem) => left.dayKey === right.dayKey ?
        left.startMinute - right.startMinute : left.dayKey.localeCompare(right.dayKey));
  }

  private getRelatedReminders(): ReminderItem[] {
    const relatedSchedules: ScheduleItem[] = this.getRelatedSchedules();
    if (relatedSchedules.length === 0) {
      return [];
    }
    return this.reminders.filter((reminder: ReminderItem) =>
      relatedSchedules.some((item: ScheduleItem) => item.id === reminder.scheduleItemId));
  }

  private getSelectedDateCompletion(): string {
    const items: ScheduleItem[] = getSchedulesForDay(this.scheduleItems, this.selectedDateKey);
    if (items.length === 0) {
      return '0 / 0';
    }
    const completed: number = items.filter((item: ScheduleItem) => item.completed).length;
    return `${completed} / ${items.length}`;
  }

  private getWeekFocusHours(): string {
    return `${(getWeekMinutes(this.scheduleItems, this.selectedDateKey) / 60).toFixed(1)}h`;
  }

  private getRecentCompletionDays(): number {
    let streak: number = 0;
    for (let index: number = 0; index < 7; index++) {
      const dayItems: ScheduleItem[] = getSchedulesForDay(this.scheduleItems, addDays(this.selectedDateKey, -index));
      if (dayItems.length === 0 || dayItems.some((item: ScheduleItem) => !item.completed)) {
        break;
      }
      streak += 1;
    }
    return streak;
  }

  private getAssistantLead(): string {
    if (this.containsPromptKeyword(['学习', '复习', '考试', '题', '考研'])) {
      return '我会先把高认知学习块放进更稳的时间窗口，再补错题回收和缓冲。';
    }
    if (this.containsPromptKeyword(['报告', '会议', '汇报', '工作', '写作'])) {
      return '这类任务不会只留一个提醒，我会把准备、执行、复盘和入口一起串起来。';
    }
    if (this.containsPromptKeyword(['紧急', '插入', '插队', '调整', '改期'])) {
      return '我会按最小扰动策略插队，只移动低优先级内容，保住整天节奏。';
    }
    if (this.getSelectedSchedule()) {
      return `我已经读取到你当前聚焦的是"${this.getSelectedSchedule()!.title}"。`;
    }
    return '我已经接入你的周视图、完成反馈、情景模式和设备协同信息。';
  }

  private getAssistantBody(): string {
    if (this.getPromptEcho().length > 0) {
      return `我会以 ${formatDateTitle(this.selectedDateKey)} 为锚点，结合最近排程、完成率和拖拽习惯，先给你一版能直接落地的方案。`;
    }
    if (this.getSelectedEventBlock()) {
      return `${this.getSelectedEventBlock()!.aiHint} 你可以继续让我补编排、启动情景模式，或直接把任务推进到执行态。`;
    }
    return '直接告诉我目标，我会把排程、提醒、情景和执行入口都压进同一条对话里。';
  }

  private getAssistantTags(): string[] {
    if (this.containsPromptKeyword(['学习', '复习', '考试', '题', '考研'])) {
      return ['深度分块', '错题回收', '学习模式', '手表节奏提醒'];
    }
    if (this.containsPromptKeyword(['报告', '会议', '汇报', '工作', '写作'])) {
      return ['准备-执行-复盘', '会议模式', '模板直达', '高提醒'];
    }
    if (this.containsPromptKeyword(['紧急', '插入', '插队', '调整', '改期'])) {
      return ['最小扰动', '自动重排', '缓冲保留', '原主线不丢'];
    }
    return ['个性化排程', '情景联动', '执行直达', '成就反馈'];
  }

  @Builder
  private buildAssistantAvatar(): void {
    Column() {
      Text('AI')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(PulsePalette.blackText)
    }
    .width(34)
    .height(34)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(PulsePalette.accentSky)
    .borderRadius(17)
  }

  @Builder
  private buildUserAvatar(): void {
    Column() {
      Text('你')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(PulsePalette.textPrimary)
    }
    .width(34)
    .height(34)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(PulsePalette.surfaceRaised)
    .borderRadius(17)
  }

  @Builder
  private buildDetailHeader(): void {
    Row() {
      Button('返回')
        .type(ButtonType.Capsule)
        .height(34)
        .backgroundColor(PulsePalette.surfaceRaised)
        .fontColor(PulsePalette.textPrimary)
        .onClick(() => {
          this.onCloseDetail();
        })

      Blank()

      Text('AI 对话页')
        .fontSize(12)
        .fontColor(PulsePalette.textMuted)

      Blank()

      Text(this.activeSceneMode.length > 0 ? this.activeSceneMode : '待启动场景')
        .fontSize(11)
        .fontColor(this.activeSceneMode.length > 0 ? PulsePalette.blackText : PulsePalette.textPrimary)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(this.activeSceneMode.length > 0 ? PulsePalette.accentLeaf : PulsePalette.surfaceRaised)
        .borderRadius(14)
    }
    .width('100%')
  }

  @Builder
  private buildIntroBubble(): void {
    Row({ space: 10 }) {
      this.buildAssistantAvatar()

      Column({ space: 12 }) {
        Text('PulsePlan AI')
          .fontSize(11)
          .fontColor(PulsePalette.accentSky)

        Text('我会先读你的日程、习惯和反馈，再给出第一版可执行方案。')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        Scroll() {
          Row({ space: 10 }) {
            ForEach(AI_PROMPT_PRESETS, (preset: PromptPreset) => {
              Column({ space: 6 }) {
                Text(preset.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PulsePalette.textPrimary)
                Text(preset.detail)
                  .fontSize(11)
                  .fontColor(PulsePalette.textSecondary)
                  .lineHeight(18)
              }
              .width(176)
              .padding(14)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(PulsePalette.surfaceRaised)
              .border({ width: 1, color: PulsePalette.border })
              .borderRadius(18)
              .onClick(() => {
                this.onInputChange(preset.prompt);
              })
            }, (preset: PromptPreset) => preset.title)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildChatUserBubble(message: ChatMessage): void {
    Row({ space: 10 }) {
      Blank()

      Column({ space: 8 }) {
        Text('你')
          .fontSize(11)
          .fontColor('#0A1622')

        Text(message.content)
          .fontSize(14)
          .fontColor(PulsePalette.blackText)
          .lineHeight(22)
      }
      .width('82%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PulsePalette.accentSky)
      .borderRadius(24)

      this.buildUserAvatar()
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildChatAIBubble(message: ChatMessage): void {
    Row({ space: 10 }) {
      this.buildAssistantAvatar()

      Column({ space: 8 }) {
        Text('PulsePlan AI')
          .fontSize(11)
          .fontColor(PulsePalette.accentSky)

        Text(message.content)
          .fontSize(14)
          .fontColor(PulsePalette.textPrimary)
          .lineHeight(22)
      }
      .width('82%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)

      Blank()
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildUserBubble(): void {
    Row({ space: 10 }) {
      Blank()

      Column({ space: 8 }) {
        Text('你')
          .fontSize(11)
          .fontColor('#0A1622')

        Text(this.getPromptEcho())
          .fontSize(14)
          .fontColor(PulsePalette.blackText)
          .lineHeight(22)
      }
      .width('82%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PulsePalette.accentSky)
      .borderRadius(24)

      this.buildUserAvatar()
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildPlanBubble(): void {
    Row({ space: 10 }) {
      this.buildAssistantAvatar()

      Column({ space: 12 }) {
        Text('我会这样处理这次需求')
          .fontSize(11)
          .fontColor(PulsePalette.accentSky)

        Text(this.getAssistantLead())
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        Text(this.getAssistantBody())
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(20)

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.getAssistantTags(), (item: string) => {
              Text(item)
                .fontSize(11)
                .fontColor(PulsePalette.textPrimary)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(PulsePalette.surfaceRaised)
                .borderRadius(14)
            }, (item: string) => item)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Scroll() {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text('目标日完成')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(this.getSelectedDateCompletion())
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text(formatDateTitle(this.selectedDateKey))
                .fontSize(10)
                .fontColor(PulsePalette.textSecondary)
            }
            .width(132)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)

            Column({ space: 4 }) {
              Text('本周专注时长')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(this.getWeekFocusHours())
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text('整周节奏将参与编排')
                .fontSize(10)
                .fontColor(PulsePalette.textSecondary)
            }
            .width(132)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)

            Column({ space: 4 }) {
              Text('总完成率')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(`${getCompletionRate(this.scheduleItems)}%`)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text('会影响提醒强度与反馈')
                .fontSize(10)
                .fontColor(PulsePalette.textSecondary)
            }
            .width(132)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Column({ space: 10 }) {
          Text(this.aiBanner.length > 0 ? this.aiBanner : '编排结果会继续显示在这里，你可以边看边调整。')
            .fontSize(12)
            .fontColor(this.aiBanner.length > 0 ? PulsePalette.accentWarm : PulsePalette.textSecondary)
            .lineHeight(20)

          if (this.getRelatedSchedules().length > 0) {
            ForEach(this.getRelatedSchedules(), (item: ScheduleItem) => {
              Column({ space: 6 }) {
                Row() {
                  Text(item.title)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(PulsePalette.textPrimary)
                    .layoutWeight(1)
                  Text(`${formatMinuteLabel(item.startMinute)}-${formatMinuteLabel(item.endMinute)}`)
                    .fontSize(11)
                    .fontColor(PulsePalette.textMuted)
                }

                Text(`${item.scene} · ${item.flexibility} · ${item.modeName}`)
                  .fontSize(11)
                  .fontColor(PulsePalette.textMuted)

                Text(item.aiSuggestion)
                  .fontSize(12)
                  .fontColor(PulsePalette.textSecondary)
                  .lineHeight(20)
              }
              .padding(14)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(PulsePalette.surfaceRaised)
              .border({ width: 1, color: PulsePalette.border })
              .borderRadius(18)
            }, (item: ScheduleItem) => `${item.id}`)
          } else {
            Text('你发送需求后，这里会展开 AI 拆出的执行链、缓冲安排和情景建议。')
              .fontSize(12)
              .fontColor(PulsePalette.textMuted)
              .lineHeight(20)
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildExecutionBubble(): void {
    Row({ space: 10 }) {
      this.buildAssistantAvatar()

      Column({ space: 12 }) {
        Text('从计划直接进入行动')
          .fontSize(11)
          .fontColor(PulsePalette.accentSky)

        if (this.getSelectedSchedule() && this.getSelectedEventBlock()) {
          Column({ space: 10 }) {
            Column({ space: 6 }) {
              Text(this.getSelectedSchedule()!.title)
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text(`${formatDateTitle(this.getSelectedSchedule()!.dayKey)} · ${formatMinuteLabel(this.getSelectedSchedule()!.startMinute)}-${formatMinuteLabel(this.getSelectedSchedule()!.endMinute)}`)
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
            }
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)

            Scroll() {
              Row({ space: 8 }) {
                Text(this.getSelectedSchedule()!.modeName)
                  .fontSize(11)
                  .fontColor(this.getSelectedSchedule()!.color)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(PulsePalette.surfaceRaised)
                  .borderRadius(14)

                Text(this.getSelectedSchedule()!.quickLaunch)
                  .fontSize(11)
                  .fontColor(PulsePalette.textPrimary)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(PulsePalette.surfaceRaised)
                  .borderRadius(14)

                Text(this.getSelectedSchedule()!.completed ? '已完成' : '待执行')
                  .fontSize(11)
                  .fontColor(this.getSelectedSchedule()!.completed ? PulsePalette.blackText : PulsePalette.textPrimary)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(this.getSelectedSchedule()!.completed ? PulsePalette.accentLeaf : PulsePalette.surfaceRaised)
                  .borderRadius(14)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)

            Scroll() {
              Row({ space: 10 }) {
                Button('启动场景')
                  .type(ButtonType.Capsule)
                  .height(40)
                  .backgroundColor(PulsePalette.surfaceRaised)
                  .fontColor(PulsePalette.textPrimary)
                  .onClick(() => {
                    this.onLaunchScene();
                  })

                Button('直达执行')
                  .type(ButtonType.Capsule)
                  .height(40)
                  .backgroundColor(PulsePalette.surfaceRaised)
                  .fontColor(PulsePalette.textPrimary)
                  .onClick(() => {
                    this.onQuickLaunch();
                  })

                Button(this.getSelectedSchedule()!.completed ? '取消完成' : '标记完成')
                  .type(ButtonType.Capsule)
                  .height(40)
                  .backgroundColor(PulsePalette.accentSky)
                  .fontColor(PulsePalette.blackText)
                  .onClick(() => {
                    this.onToggleComplete();
                  })
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
        } else {
          Text('当前还没有选中日程。你可以先让 AI 编排，或回到周视图点选一个日程块。')
            .fontSize(12)
            .fontColor(PulsePalette.textMuted)
            .lineHeight(20)
        }

        if (this.getRelatedReminders().length > 0) {
          Column({ space: 8 }) {
            Text('联动提醒卡')
              .fontSize(12)
              .fontColor(PulsePalette.textMuted)

            ForEach(this.getRelatedReminders(), (reminder: ReminderItem) => {
              Row() {
                Column({ space: 4 }) {
                  Text(reminder.title)
                    .fontSize(12)
                    .fontColor(PulsePalette.textPrimary)
                  Text(`${reminder.dayKey} · ${formatMinuteLabel(reminder.minute)}`)
                    .fontSize(11)
                    .fontColor(PulsePalette.textMuted)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text(reminder.intensity)
                  .fontSize(11)
                  .fontColor(reminder.intensity === '高提醒' ? PulsePalette.accentWarm : PulsePalette.textSecondary)
              }
              .padding(12)
              .backgroundColor(PulsePalette.surfaceRaised)
              .border({ width: 1, color: PulsePalette.border })
              .borderRadius(18)
            }, (reminder: ReminderItem) => `${reminder.id}`)
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildCapabilityBubble(): void {
    Row({ space: 10 }) {
      this.buildAssistantAvatar()

      Column({ space: 12 }) {
        Text('我已经读到这些上下文和能力')
          .fontSize(11)
          .fontColor(PulsePalette.accentSky)

        Scroll() {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text('当前锚点')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(formatDateTitle(this.selectedDateKey))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
            }
            .width(138)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)

            Column({ space: 4 }) {
              Text('连续反馈')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(`${this.getRecentCompletionDays()} 天`)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text('最近 7 天向前回看')
                .fontSize(10)
                .fontColor(PulsePalette.textSecondary)
            }
            .width(138)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)

            Column({ space: 4 }) {
              Text('场景状态')
                .fontSize(11)
                .fontColor(PulsePalette.textMuted)
              Text(this.activeSceneMode.length > 0 ? this.activeSceneMode : '待启动')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
              Text('可联动手机与手表')
                .fontSize(10)
                .fontColor(PulsePalette.textSecondary)
            }
            .width(138)
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(PulsePalette.surfaceRaised)
            .border({ width: 1, color: PulsePalette.border })
            .borderRadius(18)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        if (this.getSelectedEventBlock()) {
          Column({ space: 6 }) {
            Text(`当前事件块：${this.getSelectedEventBlock()!.title}`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.textPrimary)
            Text(this.getSelectedEventBlock()!.aiHint)
              .fontSize(12)
              .fontColor(PulsePalette.textSecondary)
              .lineHeight(20)
          }
          .padding(14)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(PulsePalette.surfaceRaised)
          .border({ width: 1, color: PulsePalette.border })
          .borderRadius(18)
        }

        Scroll() {
          Row({ space: 10 }) {
            ForEach(AI_LOGIC_POINTS, (point: LogicPoint) => {
              Column({ space: 6 }) {
                Text(point.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(PulsePalette.textPrimary)
                Text(point.detail)
                  .fontSize(11)
                  .fontColor(PulsePalette.textSecondary)
                  .lineHeight(18)
              }
              .width(180)
              .padding(14)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(PulsePalette.surfaceRaised)
              .border({ width: 1, color: PulsePalette.border })
              .borderRadius(18)
            }, (point: LogicPoint) => point.title)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private buildVoiceIcon(): void {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(16)
        .height(22)
        .borderRadius({ topLeft: 8, topRight: 8, bottomLeft: 8, bottomRight: 8 })
        .border({ width: 2, color: PulsePalette.textPrimary })
      Column()
        .width(2)
        .height(5)
        .borderRadius(1)
        .backgroundColor(PulsePalette.textPrimary)
        .position({ x: 0, y: 14 })
    }
    .width(40)
    .height(40)
  }

  @Builder
  private buildComposer(): void {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.buildVoiceIcon()
      }
      .width(40)
      .height(40)
      .onClick(() => {
        track('voice_input_clicked', '');
      })

      TextInput({ placeholder: '继续告诉我你的目标，例如：帮我排明天、插入紧急任务、绑定情景模式', text: this.localInputText })
        .layoutWeight(1)
        .height(44)
        .fontSize(15)
        .fontColor(PulsePalette.textPrimary)
        .backgroundColor(PulsePalette.surfaceRaised)
        .borderRadius(22)
        .padding({ left: 16, right: 16 })
        .border({ width: 1, color: PulsePalette.border })
        .onChange((value: string) => {
          this.localInputText = value;
          this.onInputChange(value);
        })

      Button('发送')
        .type(ButtonType.Capsule)
        .height(44)
        .width(64)
        .backgroundColor(PulsePalette.accentSky)
        .fontColor(PulsePalette.blackText)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.handleSendMessage();
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(PulsePalette.surface)
    .opacity(1)
    .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
    .border({ width: 1, color: PulsePalette.border })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 12 }) {
        this.buildDetailHeader()

        Scroll(this.detailScroller) {
          Column({ space: 12 }) {
            this.buildIntroBubble()
            
            if (this.chatMessages.length > 0) {
              ForEach(this.chatMessages, (message: ChatMessage) => {
                if (message.isUser) {
                  this.buildChatUserBubble(message)
                } else {
                  this.buildChatAIBubble(message)
                }
              }, (message: ChatMessage) => message.id)
            } else if (this.getPromptEcho().length > 0) {
              this.buildUserBubble()
            }
            
            if (this.getPromptEcho().length > 0 || this.chatMessages.length > 0) {
              ForEach(this.displaySections, (section: DisplaySection) => {
                if (section.type === 'plan') {
                  this.buildPlanBubble()
                } else if (section.type === 'execution') {
                  this.buildExecutionBubble()
                } else if (section.type === 'capability') {
                  this.buildCapabilityBubble()
                }
              }, (section: DisplaySection) => section.id)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 100 })
        }
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 0, right: 0, top: 8, bottom: 0 })
      .backgroundColor(PulsePalette.background)

      Column() {
        this.buildComposer()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
