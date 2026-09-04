import { BODY_PARTS, BodyPartInfo, PartKey } from '../model/types';

@Component
export struct BodyPartSheet {
  @Prop usedKeys: string[] = [];
  @State parts: BodyPartInfo[] = [];
  onPick: (key: PartKey) => void = (_key: PartKey) => {
  };

  aboutToAppear(): void {
    this.syncParts();
  }

  private syncParts(): void {
    const result: BodyPartInfo[] = [];
    for (let i = 0; i < BODY_PARTS.length; i++) {
      if (this.usedKeys.indexOf(BODY_PARTS[i].key) < 0) {
        result.push(BODY_PARTS[i]);
      }
    }
    this.parts = result;
  }

  build() {
    Column() {
      Text('选择训练部位')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })
        .width('100%')

      if (this.parts.length === 0) {
        Text('这一天已经添加了全部部位')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      } else {
        ForEach(this.parts, (part: BodyPartInfo) => {
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
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
  }
}
