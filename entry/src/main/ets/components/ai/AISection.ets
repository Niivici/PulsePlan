import { EventBlock, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct AISection {
  inputText: string = '';
  selectedDateKey: string = '';
  selectedScheduleId: number = 0;
  eventBlocks: EventBlock[] = [];
  scheduleItems: ScheduleItem[] = [];
  onInputChange: (value: string) => void = (_: string) => {
  };
  onGenerate: () => void = () => {
  };
  onEmergencyInsert: () => void = () => {
  };

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
        Text('AI 助手')
          .fontSize(14)
          .fontColor(PulsePalette.accentSky)

        Text('让 AI 记住你的规划习惯，而不是每次都从零排一次')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Text('这一页集中展示自然语言创建、被动偏好学习、应急插队和执行建议，方便演示“弱 AI 强交互”的核心卖点。')
          .fontSize(13)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(22)
      }
      .padding(18)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(28)

      Column({ space: 12 }) {
        Text('自然语言创建')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        TextInput({ placeholder: '例如：下周三晚间安排 90 分钟深度复习数学', text: this.inputText })
          .height(54)
          .fontSize(14)
          .backgroundColor(PulsePalette.surfaceAlt)
          .borderRadius(18)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => {
            this.onInputChange(value);
          })

        Row({ space: 10 }) {
          Button('AI 一键编排')
            .type(ButtonType.Capsule)
            .height(42)
            .backgroundColor(PulsePalette.accentSky)
            .fontColor(PulsePalette.blackText)
            .onClick(() => {
              this.onGenerate();
            })

          Button('应急插入')
            .type(ButtonType.Capsule)
            .height(42)
            .backgroundColor(PulsePalette.surfaceRaised)
            .fontColor(PulsePalette.textPrimary)
            .onClick(() => {
              this.onEmergencyInsert();
            })
        }
      }
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)

      Row({ space: 12 }) {
        Column({ space: 10 }) {
          Text('记忆画像')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('被动信号：拖拽偏好、完成率、手表睡眠与运动数据、学习时段选择。')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('主动信号：首次评测问卷、手动修正排程、情景模板订制。')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('当前目标日期：' + this.selectedDateKey)
            .fontSize(12)
            .fontColor(PulsePalette.accentWarm)
        }
        .padding(16)
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(24)

        Column({ space: 10 }) {
          Text('编排准则')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(PulsePalette.textPrimary)
          Text('1. 先判断任务场景，再决定是否分块。')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('2. 默认保留 10-20 分钟缓冲，降低计划挫败感。')
            .fontSize(12)
            .fontColor(PulsePalette.textSecondary)
          Text('3. 优先复用用户常用的时间窗口与情景模板。')
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

      Column({ space: 10 }) {
        Text('当前选中日程的 AI 协助')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)

        if (this.getSelectedSchedule() && this.getSelectedEventBlock()) {
          Column({ space: 10 }) {
            Text(this.getSelectedSchedule()!.title)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.textPrimary)
            Text(this.getSelectedEventBlock()!.aiHint)
              .fontSize(13)
              .fontColor(PulsePalette.textSecondary)
              .lineHeight(22)
            Text(this.getSelectedSchedule()!.aiSuggestion)
              .fontSize(13)
              .fontColor(PulsePalette.accentSky)
            Row({ space: 8 }) {
              Text(this.getSelectedSchedule()!.modeName)
                .fontSize(11)
                .fontColor(this.getSelectedSchedule()!.color)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(PulsePalette.surfaceAlt)
                .borderRadius(14)
              Text(this.getSelectedSchedule()!.quickLaunch)
                .fontSize(11)
                .fontColor(PulsePalette.textSecondary)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor(PulsePalette.surfaceAlt)
                .borderRadius(14)
            }
          }
        } else {
          Text('去日程区点选一个日程块，这里会展示对应的 AI 建议和执行模板。')
            .fontSize(13)
            .fontColor(PulsePalette.textMuted)
        }
      }
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)

      Column({ space: 10 }) {
        Text('计划到行动的打通')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)
        Text('日程启动后，AI 不只提醒，而是直接联动文档、会议、学习平台或记录页，并同步手表打卡。')
          .fontSize(12)
          .fontColor(PulsePalette.textSecondary)
          .lineHeight(20)
        Text('原型中已用“直达执行 / 启动场景”按钮模拟该链路。')
          .fontSize(12)
          .fontColor(PulsePalette.accentWarm)
      }
      .padding(16)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
    }
    .width('100%')
  }
}
