import { PulsePalette } from '../../common/PulsePlanTheme';
import { track } from '../../common/PulsePlanUtils';
import { AIDetailSection } from './AIDetailSection';
import { EventBlock, ScheduleItem, ReminderItem } from '../../common/PulsePlanModels';

interface PromptPreset {
  title: string;
  prompt: string;
  detail: string;
}

const AI_LANDING_FEEDS: string[] = [
  '根据最近拖拽习惯，AI 会默认给你保留 10 到 20 分钟缓冲',
  '学习型任务更适合拆成扫描、主攻、复盘三段',
  '完成反馈会同步事件块进度、连续表现和手表提醒强度',
  '会议、写作、学习等情景模式都可以由 AI 直接发起'
];

@Component
export struct AISection {
  @State inputText: string = '';
  @Watch('handleDetailModeChanged') @Prop detailMode: boolean = false;
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
  onEnterDetail: (prompt: string) => void = (_: string) => {
  };
  onCloseDetail: () => void = () => {
  };
  @State detailVisible: boolean = false;
  @State landingContentOpacity: number = 1;
  @State landingContentOffsetY: number = 0;
  @State landingCardOpacity: number = 1;
  @State landingCardScale: number = 1;
  @State landingCardOffsetY: number = 0;
  @State landingTopExpansion: number = 0;
  @State landingBottomExpansion: number = 0;
  @State detailOpacity: number = 0;
  @State detailOffsetX: number = 0;
  @State detailOffsetY: number = 60;
  @State detailScale: number = 0.95;
  private readonly landingCardHeight: number = 176;

  selectedDateKey: string = '';
  selectedScheduleId: number = 0;
  eventBlocks: EventBlock[] = [];
  scheduleItems: ScheduleItem[] = [];
  reminders: ReminderItem[] = [];
  activeSceneMode: string = '';
  aiBanner: string = '';
  lastPromptText: string = '';

  aboutToAppear(): void {
    this.applyDisplayState(this.detailMode);
  }

  private handleDetailModeChanged(): void {
    if (this.detailMode) {
      this.playEnterTransition();
    } else {
      this.playExitTransition();
    }
  }

  private applyDisplayState(showDetail: boolean): void {
    if (showDetail) {
      this.detailVisible = true;
      this.landingContentOpacity = 0;
      this.landingContentOffsetY = -44;
      this.landingCardOpacity = 0;
      this.landingCardScale = 1.08;
      this.landingCardOffsetY = -64;
      this.landingTopExpansion = 260;
      this.landingBottomExpansion = 380;
      this.detailOpacity = 1;
      this.detailOffsetX = 0;
      this.detailOffsetY = 0;
      this.detailScale = 1;
      return;
    }
    this.landingContentOpacity = 1;
    this.landingContentOffsetY = 0;
    this.landingCardOpacity = 1;
    this.landingCardScale = 1;
    this.landingCardOffsetY = 0;
    this.landingTopExpansion = 0;
    this.landingBottomExpansion = 0;
    this.detailOpacity = 0;
    this.detailOffsetX = 46;
    this.detailOffsetY = 24;
    this.detailScale = 0.98;
    setTimeout(() => {
      this.detailVisible = false;
    }, 320);
  }

  private playEnterTransition(): void {
    this.detailVisible = true;
    this.detailOpacity = 0;
    this.detailOffsetX = 0;
    this.detailOffsetY = 80;
    this.detailScale = 0.92;
    animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
      this.landingContentOpacity = 0;
      this.landingContentOffsetY = -60;
      this.landingCardOpacity = 0;
      this.landingCardScale = 1.12;
      this.landingCardOffsetY = -80;
      this.landingTopExpansion = 260;
      this.landingBottomExpansion = 380;
    });
    setTimeout(() => {
      animateTo({ duration: 420, curve: Curve.EaseOut }, () => {
        this.detailOpacity = 1;
        this.detailOffsetX = 0;
        this.detailOffsetY = 0;
        this.detailScale = 1;
      });
    }, 100);
  }

  private playExitTransition(): void {
    this.detailVisible = true;
    animateTo({ duration: 380, curve: Curve.EaseInOut }, () => {
      this.detailOpacity = 0;
      this.detailOffsetX = 0;
      this.detailOffsetY = 60;
      this.detailScale = 0.95;
      this.landingContentOpacity = 1;
      this.landingContentOffsetY = 0;
      this.landingCardOpacity = 1;
      this.landingCardScale = 1;
      this.landingCardOffsetY = 0;
      this.landingTopExpansion = 0;
      this.landingBottomExpansion = 0;
    });
    setTimeout(() => {
      this.detailVisible = false;
      this.detailOffsetX = 0;
      this.detailOffsetY = 80;
      this.detailScale = 0.92;
    }, 400);
  }

  @Builder
  private buildLandingLauncherCard(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.landingTopExpansion > 0) {
        Column()
          .width('94%')
          .height(this.landingTopExpansion)
          .backgroundColor(PulsePalette.surface)
          .border({ width: 1, color: PulsePalette.borderStrong })
          .borderRadius({ topLeft: 32, topRight: 32, bottomLeft: 18, bottomRight: 18 })
          .opacity(0.94)
          .translate({ x: 0, y: -(this.landingCardHeight / 2 + this.landingTopExpansion / 2 - 16) })
      }

      if (this.landingBottomExpansion > 0) {
        Column()
          .width('94%')
          .height(this.landingBottomExpansion)
          .backgroundColor(PulsePalette.surface)
          .border({ width: 1, color: PulsePalette.borderStrong })
          .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 32, bottomRight: 32 })
          .opacity(0.94)
          .translate({ x: 0, y: this.landingCardHeight / 2 + this.landingBottomExpansion / 2 - 16 })
      }

      Column({ space: 12 }) {
        Text('有问题尽管问 PulsePlan AI')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        Row({ space: 8 }) {
          Text('对话')
            .fontSize(11)
            .fontColor(PulsePalette.textPrimary)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.surfaceRaised)
            .borderRadius(14)

          Text('快速编排')
            .fontSize(11)
            .fontColor(PulsePalette.textPrimary)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.surfaceRaised)
            .borderRadius(14)

          Text('同步手表')
            .fontSize(11)
            .fontColor(PulsePalette.textPrimary)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.surfaceRaised)
            .borderRadius(14)
        }

        Row({ space: 12 }) {
          Text(this.inputText.trim().length > 0 ? this.inputText : '点击这里进入二级对话页，输入框会固定在底部，并自动定位到最新对话')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
            .lineHeight(20)
            .layoutWeight(1)

          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(38)
              .height(38)
              .backgroundColor(PulsePalette.surfaceRaised)
              .borderRadius(19)
            Text('›')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.textPrimary)
          }
          .width(38)
          .height(38)
        }
      }
      .width('100%')
      .height(this.landingCardHeight)
      .padding(18)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.borderStrong })
      .borderRadius(28)
      .shadow({ radius: 20, color: '#00000028', offsetX: 0, offsetY: 12 })
      .scale({ x: this.landingCardScale, y: this.landingCardScale })
      .translate({ x: 0, y: this.landingCardOffsetY })
      .opacity(this.landingCardOpacity)
      .onClick(() => {
        this.onEnterDetail(this.inputText.trim());
      })
    }
    .width('100%')
  }

  @Builder
  private buildLandingPage(): void {
    Column({ space: 12 }) {
      Row() {
        Text('PulsePlan AI')
          .fontSize(12)
          .fontColor(PulsePalette.textMuted)
        Blank()
        Text('一级页面')
          .fontSize(11)
          .fontColor(PulsePalette.textMuted)
      }
      .width('100%')
      .opacity(this.landingContentOpacity)

      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(140)
          .height(140)
          .backgroundColor(PulsePalette.glowSky)
          .opacity(0.18)
          .borderRadius(70)

        Column({ space: 8 }) {
          Text('PulsePlan')
            .fontSize(14)
            .fontColor(PulsePalette.accentWarm)

          Text('AI')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(PulsePalette.textPrimary)

          Text('conversation planner')
            .fontSize(10)
            .fontColor(PulsePalette.textMuted)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .opacity(this.landingContentOpacity)

      this.buildLandingLauncherCard()

      Column({ space: 8 }) {
        Row() {
          Text('AI 提示卡')
            .fontSize(12)
            .fontColor(PulsePalette.textMuted)
          Blank()
          Text('更多')
            .fontSize(11)
            .fontColor(PulsePalette.textMuted)
        }

        ForEach(AI_LANDING_FEEDS, (item: string, index: number) => {
          Row({ space: 8 }) {
            Text(`${index + 1}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(index === 0 ? PulsePalette.accentSky : index === 1 ? PulsePalette.accentWarm : PulsePalette.textMuted)
            Text(item)
              .fontSize(11)
              .fontColor(PulsePalette.textPrimary)
              .layoutWeight(1)
              .lineHeight(16)
          }
          .alignItems(VerticalAlign.Top)
        }, (item: string) => item)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(22)
      .opacity(this.landingContentOpacity)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 4, right: 4, top: 12, bottom: 12 })
    .translate({ x: 0, y: this.landingContentOffsetY })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.buildLandingPage()
      if (this.detailVisible || this.detailMode) {
        Column() {
          AIDetailSection({
            inputText: this.inputText,
            lastPromptText: this.lastPromptText,
            selectedDateKey: this.selectedDateKey,
            selectedScheduleId: this.selectedScheduleId,
            eventBlocks: this.eventBlocks,
            scheduleItems: this.scheduleItems,
            reminders: this.reminders,
            activeSceneMode: this.activeSceneMode,
            aiBanner: this.aiBanner,
            onInputChange: this.onInputChange,
            onGenerate: this.onGenerate,
            onEmergencyInsert: this.onEmergencyInsert,
            onOpenSchedule: this.onOpenSchedule,
            onLaunchScene: this.onLaunchScene,
            onQuickLaunch: this.onQuickLaunch,
            onToggleComplete: this.onToggleComplete,
            onCloseDetail: this.onCloseDetail
          })
        }
        .width('100%')
        .height('100%')
        .opacity(this.detailOpacity)
        .translate({ x: this.detailOffsetX, y: this.detailOffsetY })
        .scale({ x: this.detailScale, y: this.detailScale })
      }
    }
    .width('100%')
    .height(this.detailMode || this.detailVisible ? '100%' : 760)
  }
}
