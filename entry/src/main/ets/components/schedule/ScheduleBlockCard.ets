﻿﻿﻿﻿﻿﻿﻿import {
  BOARD_END_MINUTE,
  BOARD_START_MINUTE,
  DAY_COLUMN_GAP,
  DAY_COLUMN_WIDTH,
  MINUTE_HEIGHT,
  PulsePalette
} from '../../common/PulsePlanTheme';
import { ScheduleItem } from '../../common/PulsePlanModels';
import { addDays, clampMinute, formatMinuteLabel, snapMinute, toBoardOffset } from '../../common/PulsePlanUtils';

@Component
export struct ScheduleBlockCard {
  @Watch('handleItemChanged') @Prop item: ScheduleItem = {
    id: 0,
    eventBlockId: 0,
    title: '',
    scene: '',
    dayKey: '',
    startMinute: 0,
    endMinute: 30,
    color: PulsePalette.accentBlue,
    modeName: '',
    quickLaunch: '',
    aiSuggestion: '',
    flexibility: '',
    completed: false
  };
  @Prop selected: boolean = false;
  @Prop columnWidth: number = DAY_COLUMN_WIDTH;
  @Prop columnGap: number = DAY_COLUMN_GAP;
  onSelect: (scheduleId: number) => void = (_: number) => {
  };
  onMove: (scheduleId: number, targetDayKey: string, targetStartMinute: number) => void =
    (_: number, __: string, ___: number) => {
    };
  onResize: (scheduleId: number, minuteDelta: number) => void = (_: number, __: number) => {
  };
  onBlockDragStart: (scheduleId: number) => void = (_: number) => {
  };
  onBlockDragEnd: () => void = () => {
  };
  @State dragging: boolean = false;
  @State previewStartMinute: number = 0;
  @State previewDayDelta: number = 0;
  private dragBaseStartMinute: number = 0;

  aboutToAppear(): void {
    this.previewStartMinute = this.item.startMinute;
  }

  private handleItemChanged(): void {
    this.dragging = false;
    this.previewStartMinute = this.item.startMinute;
    this.previewDayDelta = 0;
    this.dragBaseStartMinute = this.item.startMinute;
  }

  private getColumnStride(): number {
    return this.columnWidth + this.columnGap;
  }

  private getDuration(): number {
    return this.item.endMinute - this.item.startMinute;
  }

  private getCardHeight(): number {
    return Math.max(this.getDuration() * MINUTE_HEIGHT, 20);
  }

  private getRenderX(): number {
    return 1 + (this.dragging ? this.previewDayDelta * this.getColumnStride() : 0);
  }

  private getRenderY(): number {
    return toBoardOffset(this.dragging ? this.previewStartMinute : this.item.startMinute);
  }

  private updatePreviewByGesture(event: GestureEvent): void {
    const nextDayDelta: number = Math.max(-6, Math.min(6, Math.round(event.offsetX / this.getColumnStride())));
    const nextStartMinute: number = clampMinute(
      this.dragBaseStartMinute + snapMinute(event.offsetY / MINUTE_HEIGHT),
      BOARD_START_MINUTE,
      BOARD_END_MINUTE - this.getDuration()
    );
    this.previewDayDelta = nextDayDelta;
    this.previewStartMinute = nextStartMinute;
  }

  private resetPreview(): void {
    this.dragging = false;
    this.previewStartMinute = this.item.startMinute;
    this.previewDayDelta = 0;
    this.dragBaseStartMinute = this.item.startMinute;
  }

  build() {
    Column({ space: this.columnWidth > 100 ? 6 : 4 }) {
      Row() {
        if (this.columnWidth > 100) {
          Column() {
            Row()
              .width(4)
              .height(this.columnWidth > 100 ? 14 : 10)
              .borderRadius(2)
              .backgroundColor('#FFFFFF40')
          }
          .width(8)
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: this.columnWidth > 100 ? 4 : 2 }) {
          Text(this.item.title)
            .fontSize(this.columnWidth > 100 ? 13 : 10)
            .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(this.columnWidth > 100 ? TextAlign.Start : TextAlign.Center)
            .maxLines(this.columnWidth > 100 ? 2 : 3)
            .width('100%')

          if (this.columnWidth > 100 || this.getCardHeight() > 60) {
            Text(`${formatMinuteLabel(this.item.startMinute)} - ${formatMinuteLabel(this.item.endMinute)}`)
              .fontSize(this.columnWidth > 100 ? 10 : 7)
              .fontColor('#F7FBFFE0')
              .textAlign(this.columnWidth > 100 ? TextAlign.Start : TextAlign.Center)
              .width('100%')
          }

          if (this.columnWidth > 100) {
            Blank()

            Row() {
              Text(this.item.scene)
                .fontSize(10)
                .fontColor('#FFFFFFE0')
                .maxLines(1)
              Blank()
              if (this.item.completed) {
                Row() {
                  Text('✓')
                    .fontSize(9)
                    .fontColor('#FFFFFF')
                  Text('完成')
                    .fontSize(9)
                    .fontColor('#FFFFFFE0')
                }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#FFFFFF20')
                .borderRadius(8)
              }
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(this.columnWidth > 100 ? HorizontalAlign.Start : HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .padding({ 
      left: this.columnWidth > 100 ? 10 : 5, 
      right: this.columnWidth > 100 ? 10 : 5, 
      top: this.columnWidth > 100 ? 10 : 6, 
      bottom: this.columnWidth > 100 ? 10 : 6 
    })
    .width(this.columnWidth - 2)
    .height(this.getCardHeight())
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.item.color)
    .border({ 
      width: this.selected ? 2.5 : 1.5, 
      color: this.selected ? '#FFFFFF' : '#FFFFFF30' 
    })
    .borderRadius(this.columnWidth > 100 ? 16 : 10)
    .shadow({
      radius: this.dragging ? 24 : (this.selected ? 16 : 8),
      color: this.dragging ? '#00000060' : (this.selected ? '#00000042' : '#00000025'),
      offsetX: 0,
      offsetY: this.dragging ? 12 : (this.selected ? 8 : 4)
    })
    .opacity(this.selected ? 0.98 : 1)
    .scale({ 
      x: this.dragging ? 1.03 : 1, 
      y: this.dragging ? 1.03 : 1 
    })
    .position({
      x: this.getRenderX(),
      y: this.getRenderY()
    })
    .zIndex(this.dragging ? 9999 : (this.selected ? 10 : 3))
    .onClick(() => {
      this.onSelect(this.item.id);
    })
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 1 })
        .onActionStart(() => {
          this.onSelect(this.item.id);
          this.dragging = true;
          this.onBlockDragStart(this.item.id);
          this.dragBaseStartMinute = this.item.startMinute;
          this.previewStartMinute = this.item.startMinute;
          this.previewDayDelta = 0;
        })
        .onActionUpdate((event: GestureEvent) => {
          this.updatePreviewByGesture(event);
        })
        .onActionEnd(() => {
          const targetDayKey: string = addDays(this.item.dayKey, this.previewDayDelta);
          const targetStartMinute: number = this.previewStartMinute;
          if (targetDayKey !== this.item.dayKey || targetStartMinute !== this.item.startMinute) {
            this.onMove(this.item.id, targetDayKey, targetStartMinute);
            return;
          }
          this.onBlockDragEnd();
          this.resetPreview();
        })
        .onActionCancel(() => {
          this.onBlockDragEnd();
          this.resetPreview();
        })
    )
    .animation({ duration: 150, curve: Curve.Friction })
  }
}
