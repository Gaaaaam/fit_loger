import { ExerciseDef, exercisesOf } from '../model/exerciseCatalog';
import { PartKey } from '../model/types';

@Component
export struct ExerciseSheet {
  @Prop partKey: PartKey = 'chest';
  @State items: ExerciseDef[] = [];
  onPick: (exerciseId: string) => void = (_exerciseId: string) => {
  };

  aboutToAppear(): void {
    this.items = exercisesOf(this.partKey);
  }

  build() {
    Column() {
      Text('选择训练动作')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })
        .width('100%')

      List() {
        ForEach(this.items, (item: ExerciseDef) => {
          ListItem() {
            Text(item.name)
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .padding({ top: 14, bottom: 14 })
              .onClick(() => {
                this.onPick(item.id);
              })
          }
        }, (item: ExerciseDef) => item.id)
      }
      .divider({
        strokeWidth: 1,
        color: $r('app.color.divider'),
        startMargin: 0,
        endMargin: 0
      })
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 16 })
  }
}
