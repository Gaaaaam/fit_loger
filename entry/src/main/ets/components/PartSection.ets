import { ExerciseItem, PartItem, SetItem } from '../model/DayModels';
import { ExerciseCard } from './ExerciseCard';

@Component
export struct PartSection {
  @ObjectLink part: PartItem;
  @Prop listStamp: number = 0;
  @Prop collapsedPartKeys: string[] = [];
  @Prop collapsedExerciseIds: number[] = [];
  onTogglePart: (partKey: string) => void = (_partKey: string) => {
  };
  onToggleExercise: (exerciseRowId: number) => void = (_id: number) => {
  };
  onAddExercise: (partKey: string) => void = (_partKey: string) => {
  };
  onDeletePart: (partKey: string) => void = (_partKey: string) => {
  };
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

  private partExpanded(): boolean {
    return this.collapsedPartKeys.indexOf(this.part.partKey) < 0;
  }

  private exerciseExpanded(exerciseRowId: number): boolean {
    return this.collapsedExerciseIds.indexOf(exerciseRowId) < 0;
  }

  private exerciseKey(exercise: ExerciseItem): string {
    const stamp: number = this.listStamp;
    if (stamp < 0) {
      return `x${exercise.id}`;
    }
    return `${exercise.id}`;
  }

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
          this.onDeletePart(this.part.partKey);
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
        Row() {
          Column() {
            Text(this.partExpanded() ? '▼' : '▶')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.accent'))
          }
          .width(28)
          .height(28)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.accent_soft'))
          .borderRadius(14)
          .margin({ right: 8 })
          Text(this.part.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (!this.partExpanded()) {
            Text(`${this.part.exercises.length} 个动作`)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onTogglePart(this.part.partKey);
        })
        Text('删除部位')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .onClick(() => {
            this.confirmDeletePart();
          })
      }
      .width('100%')
      .padding({ bottom: 8 })

      if (this.partExpanded()) {
        ForEach(this.part.exercises, (exercise: ExerciseItem) => {
          ExerciseCard({
            exercise: exercise,
            listStamp: this.listStamp,
            expanded: this.exerciseExpanded(exercise.id),
            onToggle: () => {
              this.onToggleExercise(exercise.id);
            },
            onAddSet: (exerciseRowId: number) => {
              this.onAddSet(exerciseRowId);
            },
            onDeleteExercise: (exerciseRowId: number) => {
              this.onDeleteExercise(exerciseRowId);
            },
            onDeleteSet: (setId: number) => {
              this.onDeleteSet(setId);
            },
            onSetBecameDone: (exerciseId: string, item: SetItem) => {
              this.onSetBecameDone(exerciseId, item);
            },
            onStatusChanged: () => {
              this.onStatusChanged();
            },
            onOpenDetail: (item: ExerciseItem) => {
              this.onOpenDetail(item);
            }
          })
        }, (exercise: ExerciseItem) => this.exerciseKey(exercise))

        Button('添加动作')
          .fontSize(15)
          .backgroundColor($r('app.color.accent'))
          .fontColor($r('app.color.text_on_accent'))
          .height(40)
          .width('100%')
          .onClick(() => {
            this.onAddExercise(this.part.partKey);
          })
      }
    }
    .width('100%')
    .margin({ bottom: 18 })
  }
}
