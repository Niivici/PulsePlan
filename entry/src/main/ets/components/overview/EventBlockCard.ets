import { PulsePalette } from '../../common/PulsePlanTheme';
import { EventBlock } from '../../common/PulsePlanModels';

@Component
export struct EventBlockCard {
  @Prop eventBlock: EventBlock = {
    id: 0,
    title: '',
    scene: '',
    preference: '',
    habitHint: '',
    aiHint: '',
    color: PulsePalette.accentBlue,
    quickLaunch: ''
  };
  progressText: string = '';
  selected: boolean = false;
  onPress: () => void = () => {
  };
  @State cardScale: number = 1;
  @State shadowRadius: number = 0;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.eventBlock.scene)
          .fontSize(11)
          .fontColor(this.selected ? PulsePalette.blackText : this.eventBlock.color)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .backgroundColor(this.selected ? this.eventBlock.color : PulsePalette.surfaceAlt)
          .borderRadius(12)

        Blank()

        Text(this.progressText)
          .fontSize(11)
          .fontColor(PulsePalette.textSecondary)
      }
      .width('100%')

      Text(this.eventBlock.title)
        .fontSize(19)
        .fontWeight(FontWeight.Medium)
        .fontColor(PulsePalette.textPrimary)
        .maxLines(2)

      Text(this.eventBlock.preference)
        .fontSize(12)
        .fontColor(PulsePalette.textSecondary)
        .maxLines(1)

      Text(this.eventBlock.aiHint)
        .fontSize(12)
        .fontColor(PulsePalette.textMuted)
        .maxLines(2)

      Row() {
        Text(this.eventBlock.quickLaunch)
          .fontSize(11)
          .fontColor(PulsePalette.textPrimary)
        Blank()
        Text('点击查看')
          .fontSize(10)
          .fontColor(PulsePalette.textMuted)
      }
      .width('100%')
    }
    .padding(16)
    .width(256)
    .height(172)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.selected ? '#17334A' : PulsePalette.surface)
    .border({ width: this.selected ? 1.5 : 1, color: this.selected ? this.eventBlock.color : PulsePalette.border })
    .borderRadius(26)
    .scale({ x: this.cardScale, y: this.cardScale })
    .shadow({
      radius: this.shadowRadius,
      color: this.eventBlock.color + '30',
      offsetX: 0,
      offsetY: 0
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
    .hitTestBehavior(HitTestMode.Default)
    .onHover((isHover: boolean) => {
      this.cardScale = isHover ? 1.02 : 1;
      this.shadowRadius = isHover ? 16 : 0;
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.cardScale = 0.96;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.cardScale = 1;
      }
    })
    .onClick(() => {
      this.onPress();
    })
  }
}
