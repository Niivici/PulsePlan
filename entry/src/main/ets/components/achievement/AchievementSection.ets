import { MetricCard } from '../base/MetricCard';
import { ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';
import { addDays, getCompletionRate, getSchedulesForDay } from '../../common/PulsePlanUtils';

interface Badge {
  id: number;
  name: string;
  icon: string;
  color: string;
  unlocked: boolean;
  description: string;
}

@Component
struct BehaviorBar {
  dayOffset: number = 0;
  dateKey: string = '';
  schedules: ScheduleItem[] = [];
  isToday: boolean = false;
  @State barHeight: number = 20;
  @State barOpacity: number = 0;
  @State barScale: number = 0.8;

  aboutToAppear() {
    const items = getSchedulesForDay(this.schedules, addDays(this.dateKey, this.dayOffset - 6));
    const completedCount = items.filter(item => item.completed).length;
    this.barHeight = Math.max(completedCount * 24, 20);

    setTimeout(() => {
      this.barOpacity = 1;
      this.barScale = 1;
    }, 200 + this.dayOffset * 80);
  }

  build() {
    Column({ space: 8 }) {
      Column()
        .width(36)
        .height(this.barHeight)
        .backgroundColor(this.isToday ? PulsePalette.accentSky : PulsePalette.accentLeaf)
        .borderRadius(18)
        .opacity(this.barOpacity)
        .scale({ x: this.barScale, y: 1 })
        .animation({
          duration: 700,
          curve: Curve.EaseOut
        })

      Text(this.getDayLabel())
        .fontSize(11)
        .fontColor(this.isToday ? PulsePalette.accentSky : PulsePalette.textMuted)
        .fontWeight(this.isToday ? FontWeight.Medium : FontWeight.Normal)
    }
    .justifyContent(FlexAlign.End)
    .height(160)
    .hitTestBehavior(HitTestMode.Default)
  }

  private getDayLabel(): string {
    const targetDate = addDays(this.dateKey, this.dayOffset - 6);
    const date = new Date(targetDate.replace(/-/g, '/'));
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }
}

@Component
struct BadgeCard {
  badge: Badge = { id: 0, name: '', icon: '', color: '', unlocked: false, description: '' };
  @State badgeScale: number = 1;
  @State rotation: number = 0;

  build() {
    Column({ space: 12 }) {
      Column() {
        Text(this.badge.icon)
          .fontSize(30)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .backgroundColor(this.badge.unlocked ? this.badge.color + '30' : PulsePalette.surfaceAlt)
      .border({ width: 2, color: this.badge.unlocked ? this.badge.color : PulsePalette.border })
      .opacity(this.badge.unlocked ? 1 : 0.5)
      .scale({ x: this.badgeScale, y: this.badgeScale })
      .rotate({ angle: this.rotation })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
      .hitTestBehavior(HitTestMode.Default)

      Text(this.badge.name)
        .fontSize(12)
        .fontColor(this.badge.unlocked ? PulsePalette.textPrimary : PulsePalette.textMuted)
        .fontWeight(this.badge.unlocked ? FontWeight.Medium : FontWeight.Normal)
    }
    .width(88)
    .onClick(() => {
      if (this.badge.unlocked) {
        this.badgeScale = 1.15;
        this.rotation = 5;
        setTimeout(() => {
          this.badgeScale = 1;
          this.rotation = 0;
        }, 200);
      }
    })
  }
}

@Component
struct AnimatedAchievementMetricCard {
  title: string = '';
  value: string = '';
  subtitle: string = '';
  accentColor: string = PulsePalette.accentSky;
  delay: number = 0;
  @State animScale: number = 0.9;
  @State animOpacity: number = 0;

  aboutToAppear() {
    setTimeout(() => {
      this.animScale = 1;
      this.animOpacity = 1;
    }, this.delay);
  }

  build() {
    MetricCard({
      title: this.title,
      value: this.value,
      subtitle: this.subtitle,
      accentColor: this.accentColor
    })
    .scale({ x: this.animScale, y: this.animScale })
    .opacity(this.animOpacity)
    .animation({
      duration: 500,
      curve: Curve.EaseOut
    })
    .hitTestBehavior(HitTestMode.Default)
  }
}

@Component
export struct AchievementSection {
  scheduleItems: ScheduleItem[] = [];
  selectedDateKey: string = '';
  @State isLoading: boolean = true;
  @State headerOffsetY: number = -20;
  @State headerOpacity: number = 0;

  private badges: Badge[] = [
    { id: 1, name: '初次启程', icon: '🚀', color: PulsePalette.accentSky, unlocked: true, description: '完成第一个日程' },
    { id: 2, name: '连续三天', icon: '🔥', color: PulsePalette.accentWarm, unlocked: true, description: '连续3天完成目标' },
    { id: 3, name: '周冠军', icon: '⭐', color: PulsePalette.accentGold, unlocked: false, description: '一周内完成所有计划' },
    { id: 4, name: '月度达人', icon: '🏆', color: PulsePalette.accentLeaf, unlocked: false, description: '坚持30天高效执行' },
    { id: 5, name: '完美主义', icon: '💎', color: PulsePalette.accentCoral, unlocked: false, description: '所有计划100%完成' },
    { id: 6, name: '早起鸟', icon: '🌅', color: PulsePalette.accentBlue, unlocked: true, description: '完成晨间任务' }
  ];

  aboutToAppear() {
    setTimeout(() => {
      this.headerOffsetY = 0;
      this.headerOpacity = 1;
    }, 100);

    setTimeout(() => {
      this.isLoading = false;
    }, 600);
  }

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
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 16 }) {
          Row({ space: 10 }) {
            Text('🏅')
              .fontSize(24)
            Text('成就中心')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.accentWarm)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Text('用连续反馈取代单次提醒，让坚持变成习惯')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(PulsePalette.textPrimary)
            .lineHeight(34)

          Text('这里展示连续天数、完成率、最近行为曲线和成就徽章，让进步可视化。')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
            .lineHeight(20)
        }
        .padding(22)
        .width('100%')
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(32)
        .translate({ y: this.headerOffsetY })
        .opacity(this.headerOpacity)
        .animation({
          duration: 600,
          curve: Curve.EaseOut
        })

        if (this.isLoading) {
          Scroll() {
            Row({ space: 12 }) {
              Column()
                .width(154)
                .height(126)
                .backgroundColor(PulsePalette.surface)
                .border({ width: 1, color: PulsePalette.border })
                .borderRadius(24)
                .opacity(0.6)
              Column()
                .width(154)
                .height(126)
                .backgroundColor(PulsePalette.surface)
                .border({ width: 1, color: PulsePalette.border })
                .borderRadius(24)
                .opacity(0.6)
              Column()
                .width(154)
                .height(126)
                .backgroundColor(PulsePalette.surface)
                .border({ width: 1, color: PulsePalette.border })
                .borderRadius(24)
                .opacity(0.6)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        } else {
          Scroll() {
            Row({ space: 12 }) {
              AnimatedAchievementMetricCard({
                title: '连续执行',
                value: `${this.getRecentCompletionDays()} 天`,
                subtitle: '每日坚持，点滴积累',
                accentColor: PulsePalette.accentWarm,
                delay: 100
              })
              AnimatedAchievementMetricCard({
                title: '累计完成',
                value: `${this.getCompletedCount()} 块`,
                subtitle: '每个完成都是里程碑',
                accentColor: PulsePalette.accentLeaf,
                delay: 200
              })
              AnimatedAchievementMetricCard({
                title: '总完成率',
                value: `${getCompletionRate(this.scheduleItems)}%`,
                subtitle: '坚持带来的成果',
                accentColor: PulsePalette.accentSky,
                delay: 300
              })
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }

        Column({ space: 16 }) {
          Row() {
            Text('📊')
              .fontSize(18)
            Text('最近 7 天行为曲线')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.textPrimary)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .translate({ y: this.isLoading ? 10 : 0 })
          .opacity(this.isLoading ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseOut,
            delay: 350
          })

          Row({ space: 14 }) {
            ForEach([0, 1, 2, 3, 4, 5, 6], (index: number) => {
              BehaviorBar({
                dayOffset: index,
                dateKey: this.selectedDateKey,
                schedules: this.scheduleItems,
                isToday: index === 6
              })
            })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 18, right: 18, top: 24, bottom: 20 })
          .width('100%')
          .backgroundColor(PulsePalette.surfaceAlt)
          .borderRadius(24)
        }
        .padding(18)
        .width('100%')
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(28)

        Column({ space: 16 }) {
          Row() {
            Text('🎖️')
              .fontSize(18)
            Text('成就徽章')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(PulsePalette.textPrimary)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .translate({ y: this.isLoading ? 10 : 0 })
          .opacity(this.isLoading ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseOut,
            delay: 500
          })

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
            ForEach(this.badges, (badge: Badge, index: number) => {
              BadgeCard({ badge: badge })
                .translate({ y: this.isLoading ? 15 : 0 })
                .opacity(this.isLoading ? 0 : 1)
                .animation({
                  duration: 500,
                  curve: Curve.EaseOut,
                  delay: 550 + index * 70
                })
            })
          }
          .width('100%')
          .padding(14)
        }
        .padding(18)
        .width('100%')
        .backgroundColor(PulsePalette.surface)
        .border({ width: 1, color: PulsePalette.border })
        .borderRadius(28)

        Row({ space: 14 }) {
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text('✨')
                .fontSize(16)
              Text('正反馈触发')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
            }
            .alignItems(VerticalAlign.Center)
            .width('100%')
            .justifyContent(FlexAlign.Start)
            Text('完成日程块后，立刻更新连胜、事件块进度和成就徽章，让努力获得即时反馈。')
              .fontSize(12)
              .fontColor(PulsePalette.textSecondary)
              .lineHeight(18)
          }
          .padding(20)
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(PulsePalette.surface)
          .border({ width: 1, color: PulsePalette.border })
          .borderRadius(28)
          .translate({ y: this.isLoading ? 20 : 0 })
          .opacity(this.isLoading ? 0 : 1)
          .animation({
            duration: 600,
            curve: Curve.EaseOut,
            delay: 700
          })

          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text('🎯')
                .fontSize(16)
              Text('成长方向')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(PulsePalette.textPrimary)
            }
            .alignItems(VerticalAlign.Center)
            .width('100%')
            .justifyContent(FlexAlign.Start)
            Text('• 强提醒与软提醒组合\n• 徽章强化 vs 曲线强化\n• 记录入口优化')
              .fontSize(12)
              .fontColor(PulsePalette.textSecondary)
              .lineHeight(20)
          }
          .padding(20)
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(PulsePalette.surface)
          .border({ width: 1, color: PulsePalette.border })
          .borderRadius(28)
          .translate({ y: this.isLoading ? 20 : 0 })
          .opacity(this.isLoading ? 0 : 1)
          .animation({
            duration: 600,
            curve: Curve.EaseOut,
            delay: 800
          })
        }
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 100 })
    }
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }
}
