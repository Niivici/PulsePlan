import { MonthCalendar } from './MonthCalendar';
import { TimelineBoard } from './TimelineBoard';
import {
  EventBlock,
  ReminderItem,
  ScheduleItem
} from '../../common/PulsePlanModels';
import {
  PulsePalette,
  VIEW_DAY,
  VIEW_LABELS,
  VIEW_MONTH,
  VIEW_WEEK
} from '../../common/PulsePlanTheme';
import {
  buildWeekDays,
  formatDateTitle,
  formatMinuteLabel,
  formatMonthTitle,
  formatWeekRangeTitle
} from '../../common/PulsePlanUtils';

@Component
export struct ScheduleSection {
  @Watch('handleViewIndexChanged') @Prop currentViewIndex: number = VIEW_WEEK;
  @Prop selectedDateKey: string = '';
  @Prop scheduleItems: ScheduleItem[] = [];
  @Prop eventBlocks: EventBlock[] = [];
  @Prop reminders: ReminderItem[] = [];
  @Prop inputText: string = '';
  @Prop selectedScheduleId: number = 0;
  @Prop activeSceneMode: string = '';
  @State contentOpacity: number = 1;
  @State contentOffsetY: number = 0;
  @State activeScaleIndex: number = VIEW_WEEK;
  onInputChange: (value: string) => void = (_: string) => {
  };
  onCreatePlan: () => void = () => {
  };
  onEmergencyInsert: () => void = () => {
  };
  onChangeView: (index: number) => void = (_: number) => {
  };
  onShiftTimeline: (offset: number) => void = (_: number) => {
  };
  onSelectSchedule: (scheduleId: number) => void = (_: number) => {
  };
  onMoveSchedule: (scheduleId: number, targetDayKey: string, targetStartMinute: number) => void =
    (_: number, __: string, ___: number) => {
    };
  onResizeSchedule: (scheduleId: number, minuteDelta: number) => void = (_: number, __: number) => {
  };
  onSelectDay: (dateKey: string) => void = (_: string) => {
  };
  onToggleComplete: () => void = () => {
  };
  onLaunchScene: () => void = () => {
  };
  onQuickLaunch: () => void = () => {
  };
  onSelectEventBlock: (eventBlockId: number) => void = (_: number) => {
  };

  aboutToAppear(): void {
    this.activeScaleIndex = this.currentViewIndex;
  }

  private handleViewIndexChanged(): void {
    this.activeScaleIndex = this.currentViewIndex;
    this.contentOpacity = 0.78;
    this.contentOffsetY = 14;
    animateTo({ duration: 220, curve: Curve.Friction }, () => {
      this.contentOpacity = 1;
      this.contentOffsetY = 0;
    });
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

  private getTimelineTitle(): string {
    if (this.currentViewIndex === VIEW_MONTH) {
      return formatMonthTitle(this.selectedDateKey);
    }
    if (this.currentViewIndex === VIEW_WEEK) {
      return formatWeekRangeTitle(this.selectedDateKey);
    }
    return formatDateTitle(this.selectedDateKey);
  }

  private getTimelineHint(): string {
    if (this.currentViewIndex === VIEW_WEEK) {
      return '周一至周日';
    }
    if (this.currentViewIndex === VIEW_MONTH) {
      return '整月排布';
    }
    return '当天安排';
  }

  private handleViewSwitch(index: number): void {
    if (index === this.currentViewIndex) {
      animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
        this.activeScaleIndex = -1;
      });
      animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
        this.activeScaleIndex = index;
      });
      return;
    }
    this.activeScaleIndex = index;
    this.onChangeView(index);
  }

  @Builder
  private buildTimelineShiftButton(isPrevious: boolean): void {
    Button() {
      Text(isPrevious ? '‹' : '›')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#DCE7F1')
    }
    .width(30)
    .height(30)
    .backgroundColor('#0E1821')
    .border({ width: 1, color: '#1A2A37' })
    .borderRadius(15)
    .onClick(() => {
      this.onShiftTimeline(isPrevious ? -1 : 1);
    })
  }

  @Builder
  private buildViewSwitcher(): void {
    Row({ space: 4 }) {
      ForEach(VIEW_LABELS, (label: string, index: number) => {
        Row() {
          Text(label)
            .fontSize(11)
            .fontWeight(this.currentViewIndex === index ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.currentViewIndex === index ? PulsePalette.blackText : '#7B8D9B')
        }
        .height(30)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.Center)
        .scale({ x: this.activeScaleIndex === index ? 1 : 0.96, y: this.activeScaleIndex === index ? 1 : 0.96 })
        .backgroundColor(this.currentViewIndex === index ? PulsePalette.accentSky : '#0E1821')
        .border({ width: 1, color: this.currentViewIndex === index ? '#C8F4FF' : '#162633' })
        .shadow({ radius: this.currentViewIndex === index ? 14 : 0, color: this.currentViewIndex === index ? '#2A7BA7' : '#00000000', offsetX: 0, offsetY: 6 })
        .borderRadius(15)
        .animation({ duration: 180, curve: Curve.EaseOut })
        .onClick(() => {
          this.handleViewSwitch(index);
        })
      })
    }
    .padding(3)
    .backgroundColor('#071019')
    .border({ width: 1, color: '#12212C' })
    .borderRadius(18)
  }

  @Builder
  private buildToolbar(): void {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        this.buildTimelineShiftButton(true)

        Column({ space: 1 }) {
          Text(this.getTimelineTitle())
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
            .textAlign(TextAlign.Center)
          Text(this.getTimelineHint())
            .fontSize(8)
            .fontColor(PulsePalette.textMuted)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        this.buildTimelineShiftButton(false)
      }
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .backgroundColor('#09121A')
      .border({ width: 1, color: '#12212C' })
      .borderRadius(18)

      Row() {
        Blank()
        this.buildViewSwitcher()
        Blank()
      }
      .width('100%')
    }
  }

  @Builder
  private buildCurrentView(): void {
    if (this.currentViewIndex === VIEW_DAY) {
      TimelineBoard({
        days: [{ dateKey: this.selectedDateKey, label: '今日', subLabel: formatDateTitle(this.selectedDateKey) }],
        scheduleItems: this.scheduleItems,
        selectedScheduleId: this.selectedScheduleId,
        singleDay: true,
        onSelect: this.onSelectSchedule,
        onMove: this.onMoveSchedule,
        onResize: this.onResizeSchedule
      })
    } else if (this.currentViewIndex === VIEW_WEEK) {
      TimelineBoard({
        days: buildWeekDays(this.selectedDateKey),
        scheduleItems: this.scheduleItems,
        selectedScheduleId: this.selectedScheduleId,
        singleDay: false,
        onSelect: this.onSelectSchedule,
        onMove: this.onMoveSchedule,
        onResize: this.onResizeSchedule
      })
    } else {
      MonthCalendar({
        selectedDateKey: this.selectedDateKey,
        scheduleItems: this.scheduleItems,
        onSelectDay: this.onSelectDay
      })
    }
  }

  @Builder
  private buildSelectedFooter(): void {
    if (this.getSelectedSchedule() && this.getSelectedEventBlock()) {
      Row() {
        Column({ space: 6 }) {
          Text(this.getSelectedSchedule()!.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
            .maxLines(1)

          Text(`${formatMinuteLabel(this.getSelectedSchedule()!.startMinute)} - ${formatMinuteLabel(this.getSelectedSchedule()!.endMinute)} · ${this.getSelectedSchedule()!.dayKey}`)
            .fontSize(11)
            .fontColor(PulsePalette.textMuted)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Row({ space: 8 }) {
          Button(this.getSelectedSchedule()!.completed ? '取消完成' : '完成')
            .type(ButtonType.Capsule)
            .height(34)
            .fontSize(12)
            .backgroundColor(PulsePalette.accentSky)
            .fontColor(PulsePalette.blackText)
            .onClick(() => {
              this.onToggleComplete();
            })

          Button('启动')
            .type(ButtonType.Capsule)
            .height(34)
            .fontSize(12)
            .backgroundColor('#111B25')
            .fontColor('#DCE7F1')
            .onClick(() => {
              this.onLaunchScene();
            })
        }
      }
      .padding(14)
      .backgroundColor('#0F1821')
      .border({ width: 1, color: '#182734' })
      .borderRadius(22)
    }
  }

  build() {
    Column({ space: 10 }) {
      this.buildToolbar()
      Column() {
        this.buildCurrentView()
      }
      .opacity(this.contentOpacity)
      .translate({ x: 0, y: this.contentOffsetY })
      .animation({ duration: 220, curve: Curve.Friction })
      this.buildSelectedFooter()
    }
    .width('100%')
  }
}
