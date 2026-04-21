﻿﻿﻿﻿﻿﻿﻿﻿﻿import {
  BOARD_END_MINUTE,
  BOARD_HEIGHT,
  BOARD_START_MINUTE,
  DAY_COLUMN_GAP,
  DAY_COLUMN_WIDTH,
  HOURS,
  MINUTE_HEIGHT,
  PulsePalette,
  SINGLE_DAY_WIDTH,
  TIME_RAIL_WIDTH,
  WEEK_HEADER_HEIGHT
} from '../../common/PulsePlanTheme';
import { DayMeta, ScheduleItem } from '../../common/PulsePlanModels';
import { clampMinute, formatMinuteLabel, getDateKey, getSchedulesForDay, toBoardOffset } from '../../common/PulsePlanUtils';
import { ScheduleBlockCard } from './ScheduleBlockCard';

@Component
export struct TimelineBoard {
  @Watch('handleTimelineChanged') @Prop days: DayMeta[] = [];
  @Prop scheduleItems: ScheduleItem[] = [];
  @Prop selectedScheduleId: number = 0;
  @Watch('handleTimelineChanged') @Prop singleDay: boolean = false;
  onSelect: (scheduleId: number) => void = (_: number) => {
  };
  onMove: (scheduleId: number, targetDayKey: string, targetStartMinute: number) => void =
    (_: number, __: string, ___: number) => {
    };
  onResize: (scheduleId: number, minuteDelta: number) => void = (_: number, __: number) => {
  };

  private bodyHorizontalScroller: Scroller = new Scroller();
  private bodyVerticalScroller: Scroller = new Scroller();
  @State horizontalOffset: number = 0;
  @State verticalOffset: number = 0;
  @State draggingScheduleId: number = -1;
  private autoScrollTask: number = -1;
  private lastTimelineSignature: string = '';

  aboutToAppear(): void {
    this.lastTimelineSignature = this.getTimelineSignature();
    this.scheduleAutoPosition();
  }

  aboutToDisappear(): void {
    if (this.autoScrollTask >= 0) {
      clearTimeout(this.autoScrollTask);
      this.autoScrollTask = -1;
    }
  }

  private handleTimelineChanged(): void {
    const nextSignature: string = this.getTimelineSignature();
    if (nextSignature === this.lastTimelineSignature) {
      return;
    }
    this.lastTimelineSignature = nextSignature;
    this.scheduleAutoPosition();
  }

  private getTimelineSignature(): string {
    const dayKeys: string = this.days.map((day: DayMeta) => day.dateKey).join('|');
    return `${this.singleDay ? 'day' : 'week'}:${dayKeys}`;
  }

  private itemsForDay(dayKey: string): ScheduleItem[] {
    return getSchedulesForDay(this.scheduleItems, dayKey);
  }

  private isToday(dayKey: string): boolean {
    return dayKey === getDateKey(new Date());
  }

  private getColumnWidth(): number {
    return this.singleDay ? SINGLE_DAY_WIDTH : DAY_COLUMN_WIDTH;
  }

  private getGridWidth(): number {
    if (this.days.length === 0) {
      return this.getColumnWidth();
    }
    return this.days.length * this.getColumnWidth() + (this.days.length - 1) * DAY_COLUMN_GAP;
  }

  private getViewportHeight(): number {
    return 60 * MINUTE_HEIGHT * 12;
  }

  private getMaxVerticalOffset(): number {
    return Math.max(0, BOARD_HEIGHT - this.getViewportHeight());
  }

  private clampHorizontalOffset(offset: number): number {
    return Math.max(0, offset);
  }

  private clampVerticalOffset(offset: number): number {
    return Math.max(0, Math.min(offset, this.getMaxVerticalOffset()));
  }

  private getAnchorDayKey(): string {
    if (this.days.length === 0) {
      return getDateKey(new Date());
    }
    if (this.singleDay) {
      return this.days[0].dateKey;
    }
    const todayKey: string = getDateKey(new Date());
    const todayDay: DayMeta | undefined = this.days.find((day: DayMeta) => day.dateKey === todayKey);
    return todayDay ? todayKey : this.days[0].dateKey;
  }

  private getAnchorMinute(dayKey: string): number {
    const dayItems: ScheduleItem[] = this.itemsForDay(dayKey);
    if (dayItems.length === 0) {
      return BOARD_START_MINUTE;
    }
    return clampMinute(dayItems[0].startMinute - 60, BOARD_START_MINUTE, BOARD_END_MINUTE);
  }

  private scheduleAutoPosition(): void {
    if (this.autoScrollTask >= 0) {
      clearTimeout(this.autoScrollTask);
    }
    this.autoScrollTask = setTimeout(() => {
      this.applyAutoPosition();
      this.autoScrollTask = -1;
    }, 60);
  }

  private applyAutoPosition(): void {
    if (this.days.length === 0) {
      return;
    }
    const anchorDayKey: string = this.getAnchorDayKey();
    const anchorIndex: number = Math.max(0, this.days.findIndex((day: DayMeta) => day.dateKey === anchorDayKey));
    const targetY: number = this.clampVerticalOffset(toBoardOffset(this.getAnchorMinute(anchorDayKey)));
    const targetX: number = this.singleDay ? 0 : this.clampHorizontalOffset((anchorIndex - 1) * (this.getColumnWidth() + DAY_COLUMN_GAP));

    this.horizontalOffset = targetX;
    this.verticalOffset = targetY;
    this.bodyHorizontalScroller.scrollTo({ xOffset: targetX, yOffset: 0 });
    this.bodyVerticalScroller.scrollTo({ xOffset: 0, yOffset: targetY });
  }

  private handleBlockDragStart(scheduleId: number): void {
    this.draggingScheduleId = scheduleId;
  }

  private handleBlockDragEnd(): void {
    this.draggingScheduleId = -1;
  }

  private getDayForSchedule(scheduleId: number): string | undefined {
    const item: ScheduleItem | undefined = this.scheduleItems.find((s: ScheduleItem) => s.id === scheduleId);
    return item ? item.dayKey : undefined;
  }

  private handleBodyHorizontalScroll(_: number): void {
    const currentOffset = this.bodyHorizontalScroller.currentOffset();
    this.horizontalOffset = this.clampHorizontalOffset(currentOffset.xOffset);
  }

  private handleBodyVerticalScroll(_: number): void {
    const currentOffset = this.bodyVerticalScroller.currentOffset();
    this.verticalOffset = this.clampVerticalOffset(currentOffset.yOffset);
  }

  @Builder
  private buildHeaderCell(day: DayMeta): void {
    Column({ space: 1 }) {
      Text(day.label)
        .fontSize(this.singleDay ? 13 : 10)
        .fontWeight(this.isToday(day.dateKey) ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.isToday(day.dateKey) ? PulsePalette.accentSky : '#D8E5EE')
      Text(day.subLabel)
        .fontSize(this.singleDay ? 10 : 8)
        .fontColor(this.isToday(day.dateKey) ? '#AEE9FF' : '#667887')
    }
    .width(this.getColumnWidth())
    .height(WEEK_HEADER_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.isToday(day.dateKey) ? '#122331' : '#0B141D')
    .border({ width: 1, color: this.isToday(day.dateKey) ? '#234F69' : '#111F2A' })
    .borderRadius(10)
  }

  @Builder
  private buildTimeCell(hour: number): void {
    Column() {
      Text(formatMinuteLabel(hour * 60))
        .fontSize(this.singleDay ? 11 : 8)
        .fontWeight(FontWeight.Medium)
        .fontColor('#7C8D9B')
      if (this.singleDay) {
        Text('00')
          .fontSize(8)
          .fontColor('#4A5C6A')
      }
    }
    .width(TIME_RAIL_WIDTH)
    .height(60 * MINUTE_HEIGHT)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .padding({ top: 4 })
  }

  @Builder
  private buildDayColumn(day: DayMeta): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 0 }) {
        ForEach(HOURS, (_: number) => {
          Column({ space: 0 }) {
            Row()
              .height(1)
              .width('100%')
              .backgroundColor(this.isToday(day.dateKey) ? '#21455C' : (this.singleDay ? '#1A2A36' : '#13222C'))
            Row()
              .height(60 * MINUTE_HEIGHT - 1)
          }
        })
      }
      .width(this.getColumnWidth())
      .height(BOARD_HEIGHT)

      if (this.singleDay) {
        ForEach(HOURS, (hour: number) => {
          if (hour % 2 === 0) {
            Row()
              .width(this.getColumnWidth())
              .height(60 * MINUTE_HEIGHT)
              .backgroundColor('#0C1720')
              .position({ x: 0, y: toBoardOffset(hour * 60) })
              .opacity(0.4)
          }
        }, (hour: number) => `${hour}`)
      }

      if (this.isToday(day.dateKey)) {
        Column()
          .width(this.getColumnWidth())
          .height(BOARD_HEIGHT)
          .backgroundColor('#112636')
          .opacity(0.7)
      }

      ForEach(this.itemsForDay(day.dateKey), (item: ScheduleItem) => {
        ScheduleBlockCard({
          item: item,
          selected: item.id === this.selectedScheduleId,
          columnWidth: this.getColumnWidth(),
          columnGap: DAY_COLUMN_GAP,
          onSelect: this.onSelect,
          onMove: this.onMove,
          onResize: this.onResize,
          onBlockDragStart: this.handleBlockDragStart.bind(this),
          onBlockDragEnd: this.handleBlockDragEnd.bind(this)
        })
      }, (item: ScheduleItem) => `${item.id}-${item.dayKey}-${item.startMinute}-${item.endMinute}`)
    }
    .width(this.getColumnWidth())
    .height(BOARD_HEIGHT)
    .backgroundColor(this.isToday(day.dateKey) ? '#0D1B25' : (this.singleDay ? '#0A141C' : '#081119'))
    .border({ width: 1, color: this.isToday(day.dateKey) ? '#1E4259' : (this.singleDay ? '#14232F' : '#0F1A23') })
    .borderRadius(this.singleDay ? 14 : 10)
    .clip(false)
    .zIndex(this.getDayForSchedule(this.draggingScheduleId) === day.dateKey ? 9999 : 1)
  }

  build() {
    Column({ space: 6 }) {
      Row({ space: DAY_COLUMN_GAP }) {
        Column()
          .width(TIME_RAIL_WIDTH)
          .height(WEEK_HEADER_HEIGHT)
          .backgroundColor('#081119')
          .border({ width: 1, color: '#101D27' })
          .borderRadius(10)

        Stack({ alignContent: Alignment.TopStart }) {
          Row({ space: DAY_COLUMN_GAP }) {
            ForEach(this.days, (day: DayMeta) => {
              this.buildHeaderCell(day)
            }, (day: DayMeta) => day.dateKey)
          }
          .width(this.getGridWidth())
          .height(WEEK_HEADER_HEIGHT)
          .translate({ x: -this.horizontalOffset, y: 0 })
        }
        .layoutWeight(1)
        .height(WEEK_HEADER_HEIGHT)
        .clip(true)
      }

      Row({ space: DAY_COLUMN_GAP }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Column({ space: 0 }) {
            ForEach(HOURS, (hour: number) => {
              this.buildTimeCell(hour)
            }, (hour: number) => `${hour}`)
          }
          .width(TIME_RAIL_WIDTH)
          .height(BOARD_HEIGHT)
          .translate({ x: 0, y: -this.verticalOffset })
        }
        .width(TIME_RAIL_WIDTH)
        .height(this.getViewportHeight())
        .clip(true)

        Scroll(this.bodyHorizontalScroller) {
          Scroll(this.bodyVerticalScroller) {
            Row({ space: DAY_COLUMN_GAP }) {
              ForEach(this.days, (day: DayMeta) => {
                this.buildDayColumn(day)
              }, (day: DayMeta) => day.dateKey)
            }
            .width(this.getGridWidth())
            .height(BOARD_HEIGHT)
          }
          .width(this.getGridWidth())
          .height(this.getViewportHeight())
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
          .onScroll((_: number, yOffset: number) => {
            this.handleBodyVerticalScroll(yOffset);
          })
        }
        .layoutWeight(1)
        .height(this.getViewportHeight())
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .onScroll((xOffset: number, _: number) => {
          this.handleBodyHorizontalScroll(xOffset);
        })
      }
    }
    .padding({ left: 4, right: 4, top: 6, bottom: 8 })
    .backgroundColor('#081119')
    .border({ width: 1, color: '#101D27' })
    .borderRadius(20)
  }
}
