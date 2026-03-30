import { MetricCard } from '../base/MetricCard';
import { ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';
import { addDays, getCompletionRate, getSchedulesForDay } from '../../common/PulsePlanUtils';

@Component
export struct AchievementSection {
  scheduleItems: ScheduleItem[] = [];
  selectedDateKey: string = '';

  private getCompletedCount(): number {
    return this.scheduleItems.filter((item: ScheduleItem) => item.completed).length;
  }

  private getRecentCompletionDays(): number {
    let streak: number = 0;
    for (let index: number = 0; index < 7; index++) {
      const dateKey: string = addDays(this.selectedDateKey, -index);
      const items: ScheduleItem[] = getSchedulesForDay(this.scheduleItems, dateKey);
      if (items.length === 0 || items.some((item: ScheduleItem) => !item.completed)) {
        break;
      }
      streak += 1;
    }
    return streak;
  }

  build() {
    Column({ space: 18 }) {
      Column({ space: 12 }) {
        Text('成就')
          .fontSize(14)
          .fontColor(PulsePalette.accentWarm)

        Text('用连续反馈取代单次提醒，帮用户坚持把计划变成习惯')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Text('这里重点展示连续天数、完成率、最近一周的行为曲线和成就触发，让投资人和开发团队能直观看到增长设计。')
          .fontSize(13)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(22)
      }
      .padding(18)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(28)

      Scroll() {
        Row({ space: 12 }) {
          MetricCard({
            title: '连续执行',
            value: `${this.getRecentCompletionDays()} 天`,
            subtitle: '按所选日期向前追踪连续完成表现',
            accentColor: PulsePalette.accentWarm
          })
          MetricCard({
            title: '累计完成',
            value: `${this.getCompletedCount()} 块`,
            subtitle: '完成后同步事件块与成就链',
            accentColor: PulsePalette.accentLeaf
          })
          MetricCard({
            title: '总完成率',
            value: `${getCompletionRate(this.scheduleItems)}%`,
            subtitle: '完成率会影响提醒策略和情景推荐',
            accentColor: PulsePalette.accentSky
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      Column({ space: 12 }) {
        Text('最近 7 天行为曲线')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        Row({ space: 10 }) {
          ForEach([0, 1, 2, 3, 4, 5, 6], (index: number) => {
            Column({ space: 8 }) {
              Column()
                .width(30)
                .height(Math.max(getSchedulesForDay(this.scheduleItems, addDays(this.selectedDateKey, index - 6)).length * 24, 18))
                .backgroundColor(index === 6 ? PulsePalette.accentSky : PulsePalette.accentLeaf)
                .borderRadius(15)

              Text(`${index - 6}`)
                .fontSize(10)
                .fontColor(PulsePalette.textMuted)
            }
            .justifyContent(FlexAlign.End)
            .height(150)
          })
        }
        .padding(16)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)
      }

      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text('正反馈触发')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('完成日程块后，立刻更新连胜、事件块进度、情景模式徽章和生活记录，避免完成后没有反馈。')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
            .lineHeight(20)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)

        Column({ space: 8 }) {
          Text('后续 A/B 方向')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('1. 强提醒与软提醒组合')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('2. 徽章强化 vs. 曲线强化')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('3. 生活记录入口前置 vs. 后置')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)
      }
    }
    .width('100%')
  }
}
