import { EventBlock, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct ProfileSection {
  activeSceneMode: string = '';
  eventBlocks: EventBlock[] = [];
  scheduleItems: ScheduleItem[] = [];
  selectedScheduleId: number = 0;

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

  build() {
    Column({ space: 18 }) {
      Column({ space: 12 }) {
        Text('我的')
          .fontSize(14)
          .fontColor(PulsePalette.accentLeaf)

        Text('在个人中心沉淀偏好、设备协同能力和可交付资料')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Text('这一页偏向真实产品化所需的设置与交付信息，便于继续做账号、画像、云同步和团队移交。')
          .fontSize(13)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(22)
      }
      .padding(18)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(28)

      Row({ space: 12 }) {
        Column({ space: 10 }) {
          Text('默认规划偏好')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('分块密度：中等')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('时间弹性：保留 10-20 分钟缓冲')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('提醒强度：工作高提醒，生活中提醒')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)

        Column({ space: 10 }) {
          Text('设备协同')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('手机：日程编排与执行直达')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('手表：提醒、打卡、睡眠运动回传')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text(this.activeSceneMode.length > 0 ? `当前场景：${this.activeSceneMode}` : '当前场景：未激活')
            .fontSize(12)
            .fontColor(PulsePalette.accentLeaf)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)
      }

      Column({ space: 10 }) {
        Text('当前聚焦对象')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)
        if (this.getSelectedSchedule() && this.getSelectedEventBlock()) {
          Text(`事件块：${this.getSelectedEventBlock()!.title}`)
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text(`日程块：${this.getSelectedSchedule()!.title}`)
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text(`执行入口：${this.getSelectedSchedule()!.quickLaunch}`)
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
        } else {
          Text('当前未选中任何日程块。')
            .fontSize(13)
            .fontColor(PulsePalette.textMuted)
        }
      }
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)

      Column({ space: 10 }) {
        Text('开发移交资料')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)
        Text('UI 设计稿：Pproject/UI设计稿/pulseplan_ui_board.html')
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
        Text('原型说明：Pproject/原型说明/ArkTS_原型说明.md')
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
        Text('ArkTS 代码：entry/src/main/ets')
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
      }
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .width('100%')
  }
}
