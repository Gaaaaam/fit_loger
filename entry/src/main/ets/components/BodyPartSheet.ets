import { BODY_PARTS, BodyPartInfo, PartKey } from '../model/types';

@Component
export struct BodyPartSheet {
  onPick: (key: PartKey) => void = (_key: PartKey) => {
  };

  build() {
    Column() {
      Text('选择训练部位')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })
        .width('100%')

      ForEach(BODY_PARTS, (part: BodyPartInfo) => {
        Text(part.name)
          .fontSize(17)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .border({
            width: { bottom: 1 },
            color: $r('app.color.divider')
          })
          .onClick(() => {
            this.onPick(part.key);
          })
      }, (part: BodyPartInfo) => part.key)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
  }
}
