import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct MetricCard {
  title: string = '';
  value: string = '';
  subtitle: string = '';
  accentColor: string = PulsePalette.accentSky;
  @State cardScale: number = 1;
  @State shadowRadius: number = 0;

  build() {
    Column({ space: 10 }) {
      Text(this.title)
        .fontSize(12)
        .fontColor(PulsePalette.textMuted)

      Text(this.value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PulsePalette.textPrimary)

      Text(this.subtitle)
        .fontSize(11)
        .fontColor(PulsePalette.textSecondary)
        .maxLines(2)

      Row()
        .margin({ top: 4 })
        .width(44)
        .height(4)
        .borderRadius(2)
        .backgroundColor(this.accentColor)
    }
    .padding(16)
    .width(154)
    .height(126)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(PulsePalette.surface)
    .border({ width: 1, color: PulsePalette.border })
    .borderRadius(24)
    .scale({ x: this.cardScale, y: this.cardScale })
    .shadow({
      radius: this.shadowRadius,
      color: this.accentColor + '20',
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
      this.shadowRadius = isHover ? 12 : 0;
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.cardScale = 0.96;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.cardScale = 1;
      }
    })
  }
}
