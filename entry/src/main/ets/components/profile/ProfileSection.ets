import { EventBlock, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

interface MenuItem {
  id: string;
  icon: string;
  label: string;
  action?: () => void;
}

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

  @Builder
  private buildThemeToggleIcon(): void {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(36)
        .height(36)
        .borderRadius(18)
        .linearGradient({
          angle: 135,
          colors: [['#9BE2FF', 0], ['#4CA7FF', 0.5], ['#50D39D', 1]]
        })
        .opacity(0.8)

      Text('✦')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .width(40)
    .height(40)
    .onClick(() => {
    })
  }

  @Builder
  private buildScanIcon(): void {
    Column()
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(PulsePalette.surfaceRaised)
      .border({ width: 1, color: PulsePalette.border })
      .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildUserProfileCard(): void {
    Row({ space: 16 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column()
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor(PulsePalette.surfaceAlt)
          .border({ width: 2, color: PulsePalette.borderStrong })

        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(PulsePalette.surface)
          .border({ width: 2, color: PulsePalette.borderStrong })
      }
      .width(68)
      .height(68)

      Column({ space: 6 }) {
        Text('青锋杨')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Text('普通用户')
          .fontSize(14)
          .fontColor(PulsePalette.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(PulsePalette.surface)
    .border({ width: 1, color: PulsePalette.border })
    .borderRadius(20)
  }

  @Builder
  private buildMenuIcon(iconType: string): void {
    if (iconType === 'heart') {
      Row() {
        Path()
          .width(22)
          .height(20)
          .commands('M11 3.5C11 3.5 4 9 4 14C4 17 6 19 9 19C10.5 19 11 18 11 18C11 18 11.5 19 13 19C16 19 18 17 18 14C18 9 11 3.5 11 3.5Z')
          .fill('none')
          .stroke(PulsePalette.textSecondary)
          .strokeWidth(1.8)
          .strokeLineJoin(LineJoinStyle.Round)
      }
      .width(24)
      .height(24)
    } else if (iconType === 'box') {
      Row() {
        Column()
          .width(20)
          .height(18)
          .border({ width: 1.8, color: PulsePalette.textSecondary, radius: 4 })
        Column()
          .width(8)
          .height(6)
          .borderRadius(2)
          .backgroundColor(PulsePalette.textSecondary)
          .position({ x: 6, y: -3 })
      }
      .width(24)
      .height(24)
    } else if (iconType === 'info') {
      Column() {
        Text('!')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textSecondary)
      }
      .width(22)
      .height(22)
      .border({ width: 1.8, color: PulsePalette.textSecondary, radius: 11 })
      .justifyContent(FlexAlign.Center)
    } else if (iconType === 'monitor') {
      Column({ space: 2 }) {
        Column()
          .width(22)
          .height(15)
          .border({ width: 1.8, color: PulsePalette.textSecondary, radius: 3 })
        Row()
          .width(10)
          .height(2)
          .borderRadius(1)
          .backgroundColor(PulsePalette.textSecondary)
      }
      .width(24)
      .height(24)
      .alignItems(HorizontalAlign.Center)
    } else if (iconType === 'grid') {
      Column({ space: 3 }) {
        Row({ space: 3 }) {
          Column().width(7).height(7).borderRadius(2).backgroundColor(PulsePalette.textSecondary)
          Column().width(7).height(7).borderRadius(2).backgroundColor(PulsePalette.textSecondary)
        }
        Row({ space: 3 }) {
          Column().width(7).height(7).borderRadius(2).backgroundColor(PulsePalette.textSecondary)
          Column().width(7).height(7).borderRadius(2).backgroundColor(PulsePalette.textSecondary)
        }
      }
      .width(24)
      .height(24)
    } else if (iconType === 'help') {
      Column() {
        Text('?')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textSecondary)
      }
      .width(22)
      .height(22)
      .border({ width: 1.8, color: PulsePalette.textSecondary, radius: 11 })
      .justifyContent(FlexAlign.Center)
    } else if (iconType === 'settings') {
      Column() {
        Circle()
          .width(12)
          .height(12)
          .fill('none')
          .stroke(PulsePalette.textSecondary)
          .strokeWidth(1.8)
        Circle()
          .width(4)
          .height(4)
          .fill(PulsePalette.textSecondary)
      }
      .width(24)
      .height(24)
      .justifyContent(FlexAlign.Center)
    } else if (iconType === 'logout') {
      Row() {
        Column()
          .width(14)
          .height(18)
          .border({ width: 1.8, color: PulsePalette.textSecondary, radius: 3 })
        Path()
          .width(8)
          .height(12)
          .commands('M0 6 L6 0 M0 6 L6 12')
          .fill('none')
          .stroke(PulsePalette.textSecondary)
          .strokeWidth(1.8)
      }
      .width(24)
      .height(24)
    }
  }

  @Builder
  private buildMenuItem(item: MenuItem, showDivider: boolean): void {
    Column() {
      Row({ space: 14 }) {
        this.buildMenuIcon(item.icon)

        Text(item.label)
          .fontSize(16)
          .fontColor(PulsePalette.textPrimary)
          .layoutWeight(1)

        Text('>')
          .fontSize(16)
          .fontColor(PulsePalette.textMuted)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .onClick(() => {
        if (item.action) {
          item.action();
        }
      })

      if (showDivider) {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(PulsePalette.border)
          .margin({ left: 58 })
      }
    }
  }

  @Builder
  private buildMenuGroup(items: MenuItem[]): void {
    Column() {
      ForEach(items, (item: MenuItem, index: number) => {
        this.buildMenuItem(item, index < items.length - 1)
      }, (item: MenuItem) => item.id)
    }
    .width('100%')
    .backgroundColor(PulsePalette.surface)
    .border({ width: 1, color: PulsePalette.border })
    .borderRadius(16)
  }

  @Builder
  private buildPreferenceSection(): void {
    Column({ space: 12 }) {
      Text('默认规划偏好')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PulsePalette.textPrimary)

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('分块密度：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text('中等')
            .fontSize(13)
            .fontColor(PulsePalette.textPrimary)
        }

        Row({ space: 8 }) {
          Text('时间弹性：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text('保留 10-20 分钟缓冲')
            .fontSize(13)
            .fontColor(PulsePalette.textPrimary)
        }

        Row({ space: 8 }) {
          Text('提醒强度：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text('工作高提醒，生活中提醒')
            .fontSize(13)
            .fontColor(PulsePalette.textPrimary)
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(20)
  }

  @Builder
  private buildDeviceSection(): void {
    Column({ space: 12 }) {
      Text('设备协同')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PulsePalette.textPrimary)

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('手机：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text('日程编排与执行直达')
            .fontSize(13)
            .fontColor(PulsePalette.textPrimary)
        }

        Row({ space: 8 }) {
          Text('手表：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text('提醒、打卡、睡眠运动回传')
            .fontSize(13)
            .fontColor(PulsePalette.textPrimary)
        }

        Row({ space: 8 }) {
          Text('当前场景：')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
          Text(this.activeSceneMode.length > 0 ? this.activeSceneMode : '未激活')
            .fontSize(13)
            .fontColor(this.activeSceneMode.length > 0 ? PulsePalette.accentLeaf : PulsePalette.textMuted)
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(20)
  }

  @Builder
  private buildFocusSection(): void {
    Column({ space: 12 }) {
      Text('当前聚焦对象')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(PulsePalette.textPrimary)

      if (this.getSelectedSchedule() && this.getSelectedEventBlock()) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('事件块：')
              .fontSize(13)
              .fontColor(PulsePalette.textSecondary)
            Text(this.getSelectedEventBlock()!.title)
              .fontSize(13)
              .fontColor(PulsePalette.textPrimary)
          }

          Row({ space: 8 }) {
            Text('日程块：')
              .fontSize(13)
              .fontColor(PulsePalette.textSecondary)
            Text(this.getSelectedSchedule()!.title)
              .fontSize(13)
              .fontColor(PulsePalette.textPrimary)
          }

          Row({ space: 8 }) {
            Text('执行入口：')
              .fontSize(13)
              .fontColor(PulsePalette.textSecondary)
            Text(this.getSelectedSchedule()!.quickLaunch)
              .fontSize(13)
              .fontColor(PulsePalette.textPrimary)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      } else {
        Text('当前未选中任何日程块。')
          .fontSize(13)
          .fontColor(PulsePalette.textMuted)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(20)
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('我的')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(PulsePalette.textPrimary)

        Blank()

        Row({ space: 12 }) {
          this.buildThemeToggleIcon()

          this.buildScanIcon()
        }
      }
      .width('100%')

      this.buildUserProfileCard()

      this.buildMenuGroup([
        { id: 'subscription', icon: 'heart', label: '订阅会员服务' },
        { id: 'family_bucket', icon: 'box', label: '奇妙全家桶' }
      ])

      this.buildMenuGroup([
        { id: 'about', icon: 'info', label: '关于我们' },
        { id: 'website', icon: 'monitor', label: '应用官网' },
        { id: 'more_works', icon: 'grid', label: '更多作品' }
      ])

      this.buildMenuGroup([
        { id: 'help', icon: 'help', label: '使用帮助' },
        { id: 'settings', icon: 'settings', label: '设置' }
      ])

      this.buildMenuGroup([
        { id: 'logout', icon: 'logout', label: '退出登录' }
      ])
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
