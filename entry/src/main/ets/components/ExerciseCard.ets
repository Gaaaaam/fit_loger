import { ExerciseItem, SetItem } from '../model/DayModels';
import { SetRow } from './SetRow';

@Component
export struct ExerciseCard {
  @ObjectLink exercise: ExerciseItem;
  @Prop listStamp: number = 0;
  onAddSet: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteExercise: (exerciseRowId: number) => void = (_id: number) => {
  };
  onDeleteSet: (setId: number) => void = (_id: number) => {
  };
  onSetBecameDone: (exerciseId: string, item: SetItem) => void = (_exerciseId: string, _item: SetItem) => {
  };
  onStatusChanged: () => void = () => {
  };
  onOpenDetail: (exercise: ExerciseItem) => void = (_exercise: ExerciseItem) => {
  };

  private setKey(setItem: SetItem): string {
    const stamp: number = this.listStamp;
    if (stamp < 0) {
      return `x${setItem.id}`;
    }
    return `${setItem.id}`;
  }

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
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('详情')
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .padding({ left: 8, top: 4, bottom: 4, right: 8 })
          .onClick(() => {
            this.onOpenDetail(this.exercise);
          })
        Text('删除')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .onClick(() => {
            this.confirmDelete();
          })
      }
      .width('100%')

      if (this.exercise.lastHint.length > 0) {
        Text(this.exercise.lastHint)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 4 })
      }

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
            weightPlaceholder: this.exercise.isBodyweight === 1 ? '额外负重 kg' : '重量 kg',
            onDeleted: (setId: number) => {
              this.onDeleteSet(setId);
            },
            onBecameDone: (item: SetItem) => {
              this.onSetBecameDone(this.exercise.exerciseId, item);
            },
            onStatusChanged: () => {
              this.onStatusChanged();
            }
          })
        }, (setItem: SetItem) => this.setKey(setItem))
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
