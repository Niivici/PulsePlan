import {
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
    Column({ space: 4 }) {
      Text(this.item.title)
        .fontSize(10)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Medium)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .width('100%')

      Text(`${formatMinuteLabel(this.item.startMinute)}-${formatMinuteLabel(this.item.endMinute)}`)
        .fontSize(7)
        .fontColor('#F7FBFFCC')
        .textAlign(TextAlign.Center)
        .width('100%')

      Blank()

      Row() {
        Text(this.item.scene)
          .fontSize(7)
          .fontColor('#FFFFFFE6')
          .maxLines(1)
        Blank()
        if (this.item.completed) {
          Text('完成')
            .fontSize(7)
            .fontColor('#FFFFFFE6')
        }
      }
      .width('100%')
    }
    .padding({ left: 5, right: 5, top: 6, bottom: 6 })
    .width(this.columnWidth - 2)
    .height(this.getCardHeight())
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.item.color)
    .border({ width: this.selected ? 2 : 1, color: this.selected ? '#FFFFFF' : '#FFFFFF30' })
    .borderRadius(10)
    .shadow({
      radius: this.selected ? 16 : 6,
      color: this.selected ? '#00000042' : '#00000020',
      offsetX: 0,
      offsetY: this.selected ? 6 : 3
    })
    .opacity(this.selected ? 0.96 : 1)
    .position({
      x: this.getRenderX(),
      y: this.getRenderY()
    })
    .zIndex(this.selected ? 10 : 3)
    .onClick(() => {
      this.onSelect(this.item.id);
    })
    .gesture(
      PanGesture({ direction: PanDirection.All, distance: 1 })
        .onActionStart(() => {
          this.onSelect(this.item.id);
          this.dragging = true;
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
          this.resetPreview();
        })
        .onActionCancel(() => {
          this.resetPreview();
        })
    )
    .animation({ duration: 120, curve: Curve.EaseOut })
  }
}
