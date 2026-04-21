import { MetricCard } from '../base/MetricCard';
import { EventBlockCard } from './EventBlockCard';
import { EventBlock, ScheduleItem } from '../../common/PulsePlanModels';
import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
struct AnimatedMetricCard {
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
struct AnimatedFeatureCard {
  title: string = '';
  description: string = '';
  icon: string = '';
  delay: number = 0;
  @State offsetY: number = 20;
  @State animOpacity: number = 0;
  @State animScale: number = 0.95;

  aboutToAppear() {
    setTimeout(() => {
      this.offsetY = 0;
      this.animOpacity = 1;
      this.animScale = 1;
    }, this.delay);
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(this.icon)
          .fontSize(16)
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(PulsePalette.textPrimary)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Text(this.description)
        .fontSize(12)
        .fontColor(PulsePalette.textSecondary)
        .lineHeight(20)
    }
    .padding(18)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(PulsePalette.surface)
    .border({ width: 1, color: PulsePalette.border })
    .borderRadius(24)
    .translate({ y: this.offsetY })
    .opacity(this.animOpacity)
    .scale({ x: this.animScale, y: this.animScale })
    .animation({
      duration: 600,
      curve: Curve.EaseOut
    })
    .hitTestBehavior(HitTestMode.Default)
  }
}

@Component
struct AnimatedTag {
  text: string = '';
  color: string = PulsePalette.accentSky;
  delay: number = 0;
  @State animScale: number = 0.8;
  @State animOpacity: number = 0;

  aboutToAppear() {
    setTimeout(() => {
      this.animScale = 1;
      this.animOpacity = 1;
    }, this.delay);
  }

  build() {
    Text(this.text)
      .fontSize(11)
      .fontColor(PulsePalette.blackText)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.color)
      .borderRadius(16)
      .scale({ x: this.animScale, y: this.animScale })
      .opacity(this.animOpacity)
      .animation({
        duration: 400,
        curve: Curve.EaseOut
      })
      .hitTestBehavior(HitTestMode.Default)
  }
}

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

  @State headerOffsetY: number = -20;
  @State headerOpacity: number = 0;
  @State isLoading: boolean = true;

  aboutToAppear() {
    setTimeout(() => {
      this.headerOffsetY = 0;
      this.headerOpacity = 1;
    }, 100);

    setTimeout(() => {
      this.isLoading = false;
    }, 800);
  }

  private getCompletionText(eventBlockId: number): string {
    const related: ScheduleItem[] =
      this.scheduleItems.filter((item: ScheduleItem) => item.eventBlockId === eventBlockId);
    if (related.length === 0) {
      return '0%';
    }
    const finished: number = related.filter((item: ScheduleItem) => item.completed).length;
    return `${Math.round((finished / related.length) * 100)}%`;
  }

  @Builder
  buildSkeletonCard(width: number, height: number) {
    Column()
      .width(width)
      .height(height)
      .backgroundColor(PulsePalette.surface)
      .border({ width: 1, color: PulsePalette.border })
      .borderRadius(24)
      .opacity(0.6)
  }

  build() {
    Column({ space: 20 }) {
      Column({ space: 16 }) {
        Column({ space: 12 }) {
          Text('概览')
            .fontSize(14)
            .fontColor(PulsePalette.accentSky)
            .fontWeight(FontWeight.Medium)

          Text('把计划、执行、记录和反馈放进同一个鸿蒙原生入口')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(PulsePalette.textPrimary)
            .lineHeight(38)

          Text('围绕"低成本创建 + 个性化编排 + 情景模式 + 成就反馈"搭建单页原型，方便直接继续做 ArkTS 工程化开发。')
            .fontSize(13)
            .fontColor(PulsePalette.textSecondary)
            .lineHeight(22)
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          AnimatedTag({
            text: '课程表式周视图',
            color: PulsePalette.accentSky,
            delay: 200
          })
          AnimatedTag({
            text: 'AI 记忆偏好',
            color: PulsePalette.accentWarm,
            delay: 300
          })
          AnimatedTag({
            text: '手机 + 手表协同',
            color: PulsePalette.accentLeaf,
            delay: 400
          })
        }
      }
      .padding(22)
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
            this.buildSkeletonCard(154, 126)
            this.buildSkeletonCard(154, 126)
            this.buildSkeletonCard(154, 126)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      } else {
        Scroll() {
          Row({ space: 12 }) {
            AnimatedMetricCard({
              title: '今日完成',
              value: this.todayCompletion,
              subtitle: `基于 ${this.selectedDateTitle} 的执行反馈`,
              accentColor: PulsePalette.accentSky,
              delay: 100
            })
            AnimatedMetricCard({
              title: '本周专注时长',
              value: this.weekFocusHours,
              subtitle: '拖拽后的排程会立即重算节奏',
              accentColor: PulsePalette.accentLeaf,
              delay: 200
            })
            AnimatedMetricCard({
              title: '总完成率',
              value: this.completionRate,
              subtitle: '成就区会继续追踪连续表现',
              accentColor: PulsePalette.accentWarm,
              delay: 300
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }

      Row({ space: 14 }) {
        AnimatedFeatureCard({
          title: '本周主线',
          description: this.bannerText + (this.activeSceneMode.length > 0 ? `\n当前已启动：${this.activeSceneMode}` : '\n当前未启动情景模式，等待日程块触发。'),
          icon: '📌',
          delay: 350
        })
        AnimatedFeatureCard({
          title: 'MVP 亮点',
          description: '1. 自然语言创建事件块\n2. 周视图拖拽排期，像调课程表一样微调\n3. 日程启动后直达执行与场景模式\n4. 成就反馈和连续记录一起形成粘性',
          icon: '✨',
          delay: 450
        })
      }

      Column({ space: 14 }) {
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
        .translate({ y: this.isLoading ? 10 : 0 })
        .opacity(this.isLoading ? 0 : 1)
        .animation({
          duration: 500,
          curve: Curve.EaseOut,
          delay: 500
        })

        Scroll() {
          Row({ space: 14 }) {
            ForEach(this.eventBlocks, (eventBlock: EventBlock, index: number) => {
              EventBlockCard({
                eventBlock: eventBlock,
                progressText: this.getCompletionText(eventBlock.id),
                selected: this.selectedEventBlockId === eventBlock.id,
                onPress: () => {
                  this.onSelectEventBlock(eventBlock.id);
                }
              })
              .translate({ y: this.isLoading ? 20 : 0 })
              .opacity(this.isLoading ? 0 : 1)
              .animation({
                duration: 500,
                curve: Curve.EaseOut,
                delay: 550 + index * 80
              })
            }, (eventBlock: EventBlock) => `${eventBlock.id}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .margin({ top: 4 })
      }

      Row({ space: 14 }) {
        AnimatedFeatureCard({
          title: '情景模式能力',
          description: '会议、写作、学习、记录等模式可绑定事件块，未来接入鸿蒙系统级免打扰、工具联动和环境调度。',
          icon: '🎯',
          delay: 700
        })
        AnimatedFeatureCard({
          title: '多端协同',
          description: '手机负责计划与执行，手表负责提醒、打卡、睡眠运动回传，后续可再接电脑端迁移执行态。',
          icon: '📱',
          delay: 800
        })
      }
    }
    .width('100%')
  }
}
