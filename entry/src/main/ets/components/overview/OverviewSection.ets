import { MetricCard } from '../base/MetricCard';
import { EventBlockCard } from './EventBlockCard';
import { EventBlock, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct OverviewSection {
  bannerText: string = '';
  todayCompletion: string = '';
  weekFocusHours: string = '';
  completionRate: string = '';
  activeSceneMode: string = '';
  selectedDateTitle: string = '';
  eventBlocks: EventBlock[] = [];
  scheduleItems: ScheduleItem[] = [];
  selectedEventBlockId: number = 0;
  onSelectEventBlock: (eventBlockId: number) => void = (_: number) => {
  };

  private getCompletionText(eventBlockId: number): string {
    const related: ScheduleItem[] =
      this.scheduleItems.filter((item: ScheduleItem) => item.eventBlockId === eventBlockId);
    if (related.length === 0) {
      return '0%';
    }
    const finished: number = related.filter((item: ScheduleItem) => item.completed).length;
    return `${Math.round((finished / related.length) * 100)}%`;
  }

  build() {
    Column({ space: 18 }) {
      Column({ space: 14 }) {
        Text('概览')
          .fontSize(14)
          .fontColor(PulsePalette.accentSky)

        Text('把计划、执行、记录和反馈放进同一个鸿蒙原生入口')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Text('围绕“低成本创建 + 个性化编排 + 情景模式 + 成就反馈”搭建单页原型，方便直接继续做 ArkTS 工程化开发。')
          .fontSize(13)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(22)

        Row({ space: 8 }) {
          Text('课程表式周视图')
            .fontSize(11)
            .fontColor(PulsePalette.blackText)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.accentSky)
            .borderRadius(14)

          Text('AI 记忆偏好')
            .fontSize(11)
            .fontColor(PulsePalette.blackText)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.accentWarm)
            .borderRadius(14)

          Text('手机 + 手表协同')
            .fontSize(11)
            .fontColor(PulsePalette.blackText)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(PulsePalette.accentLeaf)
            .borderRadius(14)
        }
      }
      .padding(18)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(28)

      Scroll() {
        Row({ space: 12 }) {
          MetricCard({
            title: '今日完成',
            value: this.todayCompletion,
            subtitle: `基于 ${this.selectedDateTitle} 的执行反馈`,
            accentColor: PulsePalette.accentSky
          })
          MetricCard({
            title: '本周专注时长',
            value: this.weekFocusHours,
            subtitle: '拖拽后的排程会立即重算节奏',
            accentColor: PulsePalette.accentLeaf
          })
          MetricCard({
            title: '总完成率',
            value: this.completionRate,
            subtitle: '成就区会继续追踪连续表现',
            accentColor: PulsePalette.accentWarm
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      Row({ space: 12 }) {
        Column({ space: 10 }) {
          Text('本周主线')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)

          Text(this.bannerText)
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
            .lineHeight(22)

          Text(this.activeSceneMode.length > 0 ? `当前已启动：${this.activeSceneMode}` : '当前未启动情景模式，等待日程块触发。')
            .fontSize(12)
            .fontColor(this.activeSceneMode.length > 0 ? PulsePalette.warning : PulsePalette.textMuted)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)

        Column({ space: 10 }) {
          Text('MVP 亮点')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)

          Text('1. 自然语言创建事件块')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('2. 周视图拖拽排期，像调课程表一样微调')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('3. 日程启动后直达执行与场景模式')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('4. 成就反馈和连续记录一起形成粘性')
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

      Column({ space: 12 }) {
        Row() {
          Text('事件块库')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Blank()
          Text('点击卡片可联动日程与 AI 视图')
            .fontSize(11)
            .fontColor(PulsePalette.textMuted)
        }

        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.eventBlocks, (eventBlock: EventBlock) => {
              EventBlockCard({
                eventBlock: eventBlock,
                progressText: this.getCompletionText(eventBlock.id),
                selected: this.selectedEventBlockId === eventBlock.id,
                onPress: () => {
                  this.onSelectEventBlock(eventBlock.id);
                }
              })
            }, (eventBlock: EventBlock) => `${eventBlock.id}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }

      Row({ space: 12 }) {
        Column({ space: 8 }) {
          Text('情景模式能力')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('会议、写作、学习、记录等模式可绑定事件块，未来接入鸿蒙系统级免打扰、工具联动和环境调度。')
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
          Text('多端协同')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('手机负责计划与执行，手表负责提醒、打卡、睡眠运动回传，后续可再接电脑端迁移执行态。')
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
      }
    }
    .width('100%')
  }
}
