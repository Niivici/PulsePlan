﻿﻿﻿import { NavItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct FloatingNavBar {
  @Prop items: NavItem[] = [];
  @Prop currentIndex: number = 0;
  onChange: (index: number) => void = (_: number) => {
  };

  private readonly itemSize: number = 44;
  private readonly itemGap: number = 14;
  private readonly horizontalPadding: number = 14;
  private readonly verticalPadding: number = 10;

  private isActive(index: number): boolean {
    return this.currentIndex === index;
  }

  private getStride(): number {
    return this.itemSize + this.itemGap;
  }

  private getActiveBubbleX(): number {
    return this.horizontalPadding + this.currentIndex * this.getStride();
  }

  @Builder
  private buildOverviewIcon(active: boolean): void {
    Column({ space: 3 }) {
      Row({ space: 3 }) {
        this.buildIconTile(active, 8, 8)
        this.buildIconTile(active, 10, 8)
      }
      Row({ space: 3 }) {
        this.buildIconTile(active, 10, 8)
        this.buildIconTile(active, 8, 8)
      }
    }
  }

  @Builder
  private buildScheduleIcon(active: boolean): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(18)
        .height(16)
        .border({ width: 1.6, color: active ? PulsePalette.textPrimary : '#E8F0F7' })
        .borderRadius(4)
        .position({ x: 0, y: 2 })

      Row({ space: 4 }) {
        Column().width(2.5).height(4.5).borderRadius(1.2).backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
        Column().width(2.5).height(4.5).borderRadius(1.2).backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
      }
      .position({ x: 6, y: 0 })

      Row()
        .width(18)
        .height(3.2)
        .backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
        .position({ x: 0, y: 7 })
        .opacity(0.9)

      Row({ space: 2.5 }) {
        Column().width(3.5).height(3.5).borderRadius(1.8).backgroundColor(active ? PulsePalette.accentSky : '#8BA4B8')
        Column().width(3.5).height(3.5).borderRadius(1.8).backgroundColor(active ? PulsePalette.accentSky : '#8BA4B8')
        Column().width(3.5).height(3.5).borderRadius(1.8).backgroundColor(active ? PulsePalette.accentSky : '#8BA4B8')
      }
      .position({ x: 2.2, y: 12 })
    }
    .width(18)
    .height(18)
  }

  @Builder
  private buildAiIcon(active: boolean): void {
    Stack({ alignContent: Alignment.Center }) {
      Text('✦')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(active ? PulsePalette.textPrimary : '#FFFFFF')
      Circle()
        .width(3.5)
        .height(3.5)
        .fill(active ? PulsePalette.accentSky : '#9DE5FF')
        .position({ x: 12, y: 2 })
      Circle()
        .width(3)
        .height(3)
        .fill(active ? PulsePalette.accentSky : '#9DE5FF')
        .position({ x: 3, y: 13 })
    }
    .width(18)
    .height(18)
  }

  @Builder
  private buildAchievementIcon(active: boolean): void {
    Row({ space: 2.5 }) {
      Column().width(3.5).height(7).borderRadius(2.5).backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
      Column().width(3.5).height(11).borderRadius(2.5).backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
      Column().width(3.5).height(15).borderRadius(2.5).backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
    }
    .height(18)
    .alignItems(VerticalAlign.Bottom)
  }

  @Builder
  private buildProfileIcon(active: boolean): void {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(7)
        .height(7)
        .fill(active ? PulsePalette.textPrimary : '#E8F0F7')
        .position({ x: 5.5, y: 1.5 })

      Column()
        .width(16)
        .height(9)
        .border({ width: 1.6, color: active ? PulsePalette.textPrimary : '#E8F0F7' })
        .borderRadius({ topLeft: 7, topRight: 7, bottomLeft: 8, bottomRight: 8 })
        .position({ x: 1, y: 9 })
    }
    .width(18)
    .height(18)
  }

  @Builder
  private buildIconTile(active: boolean, width: number, height: number): void {
    Column()
      .width(width)
      .height(height)
      .borderRadius(2.5)
      .backgroundColor(active ? PulsePalette.textPrimary : '#E8F0F7')
  }

  @Builder
  private buildIcon(item: NavItem, active: boolean): void {
    if (item.key === 'overview') {
      this.buildOverviewIcon(active)
    } else if (item.key === 'schedule') {
      this.buildScheduleIcon(active)
    } else if (item.key === 'ai') {
      this.buildAiIcon(active)
    } else if (item.key === 'achievement') {
      this.buildAchievementIcon(active)
    } else {
      this.buildProfileIcon(active)
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(this.itemSize)
        .height(this.itemSize)
        .position({ x: this.getActiveBubbleX(), y: this.verticalPadding })
        .backgroundColor(PulsePalette.surfaceRaised)
        .border({ width: 1, color: PulsePalette.borderStrong })
        .borderRadius(22)
        .animation({ duration: 320, curve: Curve.Linear })

      Row({ space: this.itemGap }) {
        ForEach(this.items, (item: NavItem, index: number) => {
          Stack({ alignContent: Alignment.Center }) {
            if (!this.isActive(index)) {
              Column()
                .width(36)
                .height(36)
                .backgroundColor(PulsePalette.surfaceAlt)
                .opacity(0.7)
                .borderRadius(18)
            }

            this.buildIcon(item, this.isActive(index))
          }
          .width(this.itemSize)
          .height(this.itemSize)
          .scale({ x: this.isActive(index) ? 1.05 : 1, y: this.isActive(index) ? 1.05 : 1 })
          .animation({ duration: 240, curve: Curve.EaseInOut })
          .onClick(() => {
            this.onChange(index);
          })
        }, (item: NavItem) => item.key)
      }
      .padding({ left: this.horizontalPadding, right: this.horizontalPadding, top: this.verticalPadding, bottom: this.verticalPadding })
    }
    .padding(5)
    .backgroundColor(PulsePalette.surface)
    .opacity(0.6)
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
    .border({ width: 1, color: PulsePalette.border })
    .borderRadius(32)
    .shadow({ radius: 20, color: '#00000022', offsetX: 0, offsetY: 8 })
  }
}
