import { ExerciseItem, SetItem } from '../model/DayModels';
import { SetRow } from './SetRow';

@Component
export struct ExerciseCard {
  @ObjectLink exercise: ExerciseItem;
  onAddSet: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteExercise: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteSet: (setId: number) => void = (_id: number) => {
  };

  private confirmDelete(): void {
    AlertDialog.show({
      title: '删除动作',
      message: `将删除「${this.exercise.name}」及其全部组。`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: () => {
          this.onDeleteExercise(this.exercise.id);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text(this.exercise.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('删除')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .onClick(() => {
            this.confirmDelete();
          })
      }
      .width('100%')

      if (this.exercise.sets.length === 0) {
        Text('还没有组，点下方添加')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10, bottom: 6 })
          .width('100%')
      } else {
        ForEach(this.exercise.sets, (setItem: SetItem) => {
          SetRow({
            setItem: setItem,
            onDeleted: (setId: number) => {
              this.onDeleteSet(setId);
            }
          })
        }, (setItem: SetItem) => `${setItem.id}`)
      }

      Button('添加组')
        .fontSize(14)
        .fontColor($r('app.color.accent'))
        .backgroundColor($r('app.color.accent_soft'))
        .height(36)
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => {
          this.onAddSet(this.exercise.id);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .margin({ bottom: 10 })
  }
}
