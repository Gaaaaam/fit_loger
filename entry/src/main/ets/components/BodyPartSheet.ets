import { BODY_PARTS, BodyPartInfo, PartKey } from '../model/types';

@Component
export struct BodyPartSheet {
  onPick: (key: PartKey) => void = (_key: PartKey) => {
  };

  build() {
    Column({ space: 12 }) {
      Text('选择训练部位 / 类型')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Grid() {
        ForEach(BODY_PARTS, (part: BodyPartInfo) => {
          GridItem() {
            Column({ space: 6 }) {
              Image(part.image)
                .width('100%')
                .height(100)
                .objectFit(ImageFit.Contain)
              Text(part.name)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text(part.description)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
                .maxLines(2)
            }
            .width('100%')
            .height(180)
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .border({ width: 1, color: $r('app.color.divider') })
            .accessibilityText(`${part.name}，${part.description}`)
            .onClick(() => {
              this.onPick(part.key);
            })
          }
        }, (part: BodyPartInfo) => part.key)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 24 })
  }
}
