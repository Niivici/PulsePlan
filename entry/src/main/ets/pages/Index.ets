﻿﻿﻿import { PulsePlanHome } from '../prototype/PulsePlanHome';

@Entry
@Component
struct Index {
  build() {
    Column() {
      PulsePlanHome()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }
}
