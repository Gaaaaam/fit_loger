import { GUIDE_STEPS, GuideStepCopy, guideStepCopy } from '../common/TrendGuide';

@Component
export struct TrendGuideCard {
  @Prop step: string = 'intro';
  @Prop hasAnyWorkSet: boolean = false;
  onNext: () => void = () => {
  };
  onSkip: () => void = () => {
  };
  private stepKeys: string[] = GUIDE_STEPS;

  private copy(): GuideStepCopy {
    return guideStepCopy(this.step, this.hasAnyWorkSet);
  }

  @Builder
  progressDot(item: string) {
    Column()
      .width(this.step === item ? 16 : 8)
      .height(8)
      .borderRadius(4)
      .backgroundColor(this.step === item ? $r('app.color.accent') : $r('app.color.chip_bg'))
      .margin({ right: 6 })
  }

  build() {
    Column() {
      Row() {
        ForEach(this.stepKeys, (item: string) => {
          this.progressDot(item)
        }, (item: string) => item)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(this.copy().title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Text(this.copy().body)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 8, bottom: 16 })

      Row() {
        if (this.copy().secondaryLabel.length > 0) {
          Text(this.copy().secondaryLabel)
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 4, right: 12, top: 12, bottom: 12 })
            .onClick(() => {
              this.onSkip();
            })
        }
        Blank()
        Text(this.copy().primaryLabel)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_on_accent'))
          .textAlign(TextAlign.Center)
          .height(44)
          .padding({ left: 18, right: 18 })
          .borderRadius(12)
          .backgroundColor($r('app.color.accent'))
          .onClick(() => {
            this.onNext();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 18 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
