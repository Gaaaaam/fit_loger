import { isCustomExercise, joinZh, numberedLine } from '../common/ExerciseLogic';
import { artworkOf, ExerciseArtwork, partFallback } from '../model/exerciseArtwork';
import { ExerciseDef, findExercise } from '../model/exerciseCatalog';
import { difficultyLabel, ExerciseDetail, findExerciseDetail } from '../model/exerciseDetails';
import { equipmentName, PartKey } from '../model/types';

@Component
export struct ExerciseInfoView {
  @Prop exerciseId: string = '';
  @Prop displayName: string = '';
  @Prop partKey: PartKey = 'chest';
  @Prop showAdd: boolean = false;
  onAdd: () => void = () => {
  };

  private catalogDef(): ExerciseDef | null {
    return findExercise(this.exerciseId);
  }

  private detail(): ExerciseDetail | null {
    return findExerciseDetail(this.exerciseId);
  }

  private titleName(): string {
    if (this.displayName.length > 0) {
      return this.displayName;
    }
    const def: ExerciseDef | null = this.catalogDef();
    if (def !== null) {
      return def.name;
    }
    return this.exerciseId;
  }

  private resolvedPart(): PartKey {
    const def: ExerciseDef | null = this.catalogDef();
    if (def !== null) {
      return def.partKey;
    }
    return this.partKey;
  }

  private equipmentLabel(): string {
    if (isCustomExercise(this.exerciseId)) {
      return '自定义';
    }
    const def: ExerciseDef | null = this.catalogDef();
    if (def !== null) {
      return equipmentName(def.equipment);
    }
    return '其他';
  }

  private startImage(): Resource {
    const art: ExerciseArtwork | null = artworkOf(this.exerciseId);
    if (art !== null) {
      return art.start;
    }
    return partFallback(this.resolvedPart());
  }

  private endImage(): Resource {
    const art: ExerciseArtwork | null = artworkOf(this.exerciseId);
    if (art !== null) {
      return art.end;
    }
    return partFallback(this.resolvedPart());
  }

  private detailSteps(): string[] {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.steps;
    }
    return [];
  }

  private detailCues(): string[] {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.cues;
    }
    return [];
  }

  private detailEnglish(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.englishName;
    }
    return '';
  }

  private detailAliases(): string[] {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.aliases;
    }
    return [];
  }

  private detailDifficulty(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.difficulty;
    }
    return 'beginner';
  }

  private detailPrimary(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.primaryMusclesZh;
    }
    return '';
  }

  private detailSecondary(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.secondaryMusclesZh;
    }
    return '';
  }

  private detailStartPosition(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.startPosition;
    }
    return '';
  }

  private detailCounting(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.counting;
    }
    return '';
  }

  private detailSourceName(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.sourceName;
    }
    return '';
  }

  private detailSourceId(): string {
    const item: ExerciseDetail | null = this.detail();
    if (item !== null) {
      return item.sourceId;
    }
    return '';
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text(this.titleName())
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        if (isCustomExercise(this.exerciseId)) {
          Text('自定义动作')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        } else if (this.detail() !== null) {
          Text(this.detailEnglish())
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          if (this.detailAliases().length > 0) {
            Text('别名：' + joinZh(this.detailAliases()))
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          }
        }

        Row({ space: 8 }) {
          Text(this.equipmentLabel())
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.chip_bg'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(10)
          if (this.detail() !== null) {
            Text(difficultyLabel(this.detailDifficulty()))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .backgroundColor($r('app.color.chip_bg'))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(10)
          }
        }
        .width('100%')

        Row({ space: 8 }) {
          Column({ space: 4 }) {
            Text('起始')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Image(this.startImage())
              .width('100%')
              .height(110)
              .objectFit(ImageFit.Contain)
          }
          .layoutWeight(1)
          Column({ space: 4 }) {
            Text('结束')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Image(this.endImage())
              .width('100%')
              .height(110)
              .objectFit(ImageFit.Contain)
          }
          .layoutWeight(1)
        }
        .width('100%')

        if (this.detail() !== null) {
          Text('主肌群  ' + this.detailPrimary())
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text('辅助  ' + this.detailSecondary())
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Text('起始姿势')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 6 })
            .width('100%')
          Text(this.detailStartPosition())
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text('动作步骤')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 6 })
            .width('100%')
          ForEach(this.detailSteps(), (step: string, index: number) => {
            Text(numberedLine(index, step))
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
          }, (step: string, index: number) => numberedLine(index, step))
          Text('注意点')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 6 })
            .width('100%')
          ForEach(this.detailCues(), (cue: string, index: number) => {
            Text('· ' + cue)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
          }, (cue: string, index: number) => numberedLine(index, cue))
          Text('计次口径')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 6 })
            .width('100%')
          Text(this.detailCounting())
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          if (this.detailSourceId().length > 0) {
            Text('来源 ' + this.detailSourceName() + ' / ' + this.detailSourceId())
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
              .width('100%')
          } else {
            Text('来源 应用内原创说明')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
              .width('100%')
          }
        } else {
          Image(partFallback(this.resolvedPart()))
            .width('100%')
            .height(120)
            .objectFit(ImageFit.Contain)
          Text('这是自定义动作，使用对应部位示意图。可直接按重量和次数记录。')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }

        if (this.showAdd) {
          Button('添加动作')
            .backgroundColor($r('app.color.accent'))
            .fontColor($r('app.color.text_on_accent'))
            .width('100%')
            .height(44)
            .margin({ top: 12, bottom: 16 })
            .onClick(() => {
              this.onAdd();
            })
        }
      }
      .width('100%')
      .padding({ bottom: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }
}
