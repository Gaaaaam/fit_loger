import { ExerciseItem, PartItem } from '../model/DayModels';
import { ExerciseCard } from './ExerciseCard';

@Component
export struct PartSection {
  @ObjectLink part: PartItem;
  onAddExercise: (partId: number) => void = (_partId: number) => {
  };
  onDeletePart: (partId: number) => void = (_partId: number) => {
  };
  onAddSet: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteExercise: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteSet: (setId: number) => void = (_id: number) => {
  };

  private confirmDeletePart(): void {
    AlertDialog.show({
      title: '删除部位',
      message: `将删除「${this.part.name}」下的全部动作和组。`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: () => {
          this.onDeletePart(this.part.id);
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
        Text(this.part.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('删除部位')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .onClick(() => {
            this.confirmDeletePart();
          })
      }
      .width('100%')
      .padding({ bottom: 8 })

      ForEach(this.part.exercises, (exercise: ExerciseItem) => {
        ExerciseCard({
          exercise: exercise,
          onAddSet: (exerciseRowId: number) => {
            this.onAddSet(exerciseRowId);
          },
          onDeleteExercise: (exerciseRowId: number) => {
            this.onDeleteExercise(exerciseRowId);
          },
          onDeleteSet: (setId: number) => {
            this.onDeleteSet(setId);
          }
        })
      }, (exercise: ExerciseItem) => `${exercise.id}`)

      Button('添加动作')
        .fontSize(15)
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .height(40)
        .width('100%')
        .onClick(() => {
          this.onAddExercise(this.part.id);
        })
    }
    .width('100%')
    .margin({ bottom: 18 })
  }
}
