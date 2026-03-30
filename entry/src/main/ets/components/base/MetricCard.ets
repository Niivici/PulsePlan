import { PulsePalette } from '../../common/PulsePlanTheme';

@Component
export struct MetricCard {
  title: string = '';
  value: string = '';
  subtitle: string = '';
  accentColor: string = PulsePalette.accentSky;

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
  }
}
