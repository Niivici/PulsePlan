import { PulsePalette, WEEKDAY_TEXT } from '../../common/PulsePlanTheme';
import { MonthCellMeta, ScheduleItem } from '../../common/PulsePlanModels';
import { buildMonthCells, getSchedulesForDay } from '../../common/PulsePlanUtils';

@Component
export struct MonthCalendar {
  @Prop selectedDateKey: string = '';
  @Prop scheduleItems: ScheduleItem[] = [];
  onSelectDay: (dateKey: string) => void = (_: string) => {
  };

  private itemsForDay(dateKey: string): ScheduleItem[] {
    return getSchedulesForDay(this.scheduleItems, dateKey).slice(0, 2);
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        ForEach(WEEKDAY_TEXT, (label: string) => {
          Text(label)
            .fontSize(12)
            .fontColor(PulsePalette.textMuted)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')

      ForEach([0, 1, 2, 3, 4, 5], (rowIndex: number) => {
        Row({ space: 8 }) {
          ForEach(buildMonthCells(this.selectedDateKey).slice(rowIndex * 7, rowIndex * 7 + 7), (cell: MonthCellMeta) => {
            Column({ space: 6 }) {
              Text(`${cell.dayNumber}`)
                .fontSize(13)
                .fontWeight(cell.dateKey === this.selectedDateKey ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(cell.dateKey === this.selectedDateKey ? PulsePalette.blackText :
                  cell.inCurrentMonth ? PulsePalette.textPrimary : PulsePalette.textMuted)

              ForEach(this.itemsForDay(cell.dateKey), (item: ScheduleItem) => {
                Text(item.title)
                  .fontSize(8)
                  .fontColor(PulsePalette.textPrimary)
                  .maxLines(1)
                  .width('100%')
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .backgroundColor(item.color)
                  .borderRadius(8)
              }, (item: ScheduleItem) => `${item.id}`)
            }
            .padding(8)
            .layoutWeight(1)
            .height(92)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(cell.dateKey === this.selectedDateKey ? PulsePalette.accentSky : PulsePalette.surface)
            .border({ width: 1, color: cell.dateKey === this.selectedDateKey ? PulsePalette.accentSky : PulsePalette.border })
            .borderRadius(18)
            .opacity(cell.inCurrentMonth ? 1 : 0.68)
            .onClick(() => {
              this.onSelectDay(cell.dateKey);
            })
          }, (cell: MonthCellMeta) => cell.dateKey)
        }
      })
    }
  }
}
