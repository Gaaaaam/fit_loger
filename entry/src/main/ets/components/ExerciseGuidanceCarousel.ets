import { safeArtworkFrameIndex } from '../common/ExerciseArtworkLogic';

@Component
export struct ExerciseGuidanceCarousel {
  @Prop @Watch('onFramesChanged') frames: Resource[] = [];
  @Prop captions: string[] = [];
  @State currentIndex: number = 0;

  private onFramesChanged(): void {
    this.currentIndex = 0;
  }

  private setCurrentIndex(index: number): void {
    // A pending Swiper callback can still refer to the previous action's frames.
    this.currentIndex = safeArtworkFrameIndex(index, this.frames.length);
  }

  build() {
    Column({ space: 8 }) {
      if (this.frames.length > 0) {
        Swiper() {
          ForEach(this.frames, (frame: Resource, index: number) => {
            Image(frame)
              .width('100%')
              .height(280)
              .objectFit(ImageFit.Contain)
              .accessibilityText(this.captions[index] || '动作示意')
          }, (frame: Resource, index: number) => `${index}:${JSON.stringify(frame)}`)
        }
        .width('100%')
        .height(280)
        .displayCount(1)
        .index(this.currentIndex)
        .loop(false)
        .indicator(this.frames.length > 1)
        .onChange((index: number) => {
          this.setCurrentIndex(index);
        })

        Text('第 ' + (this.currentIndex + 1) + ' / ' + this.frames.length + ' 步')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Text(this.captions[this.currentIndex] || '动作示意')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
      }
    }
    .width('100%')
  }
}
