import { hilog } from '@kit.PerformanceAnalysisKit';
import { formatExerciseVolume, TrendSetRow } from '../common/TrendLogic';
import { parseReps, parseWeight, HintSet, nextTargetText, trimNote, vsLastCardText } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { ExerciseItem, SetItem } from '../model/DayModels';
import { SetRow } from './SetRow';

@Component
export struct ExerciseCard {
  @ObjectLink exercise: ExerciseItem;
  @Prop listStamp: number = 0;
  @Prop expanded: boolean = true;
  onToggle: () => void = () => {
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
  private noteTimer: number = -1;

  aboutToDisappear(): void {
    if (this.noteTimer !== -1) {
      clearTimeout(this.noteTimer);
      this.noteTimer = -1;
    }
    this.flushNote();
  }

  private scheduleNote(): void {
    if (this.noteTimer !== -1) {
      clearTimeout(this.noteTimer);
    }
    this.noteTimer = setTimeout(() => {
      this.noteTimer = -1;
      this.flushNote();
    }, 280);
  }

  private flushNote(): void {
    if (this.exercise.id <= 0) {
      return;
    }
    const note: string = trimNote(this.exercise.note);
    WorkoutRepository.saveExerciseNote(this.exercise.id, note).catch(() => {
      hilog.error(0xF170, 'ExerciseCard', 'save note failed');
    });
  }

  private setKey(setItem: SetItem): string {
    const stamp: number = this.listStamp;
    if (stamp < 0) {
      return `x${setItem.id}`;
    }
    return `${setItem.id}`;
  }

  private progressText(): string {
    const current: HintSet[] = [];
    for (let i = 0; i < this.exercise.sets.length; i++) {
      const item: SetItem = this.exercise.sets[i];
      if (item.status !== 'done' || item.isWarmup === 1) {
        continue;
      }
      const w = parseWeight(item.weightText);
      const r = parseReps(item.repsText);
      const hint: HintSet = new HintSet();
      hint.weight = w.ok ? w.value : null;
      hint.reps = r.ok ? r.value : null;
      current.push(hint);
    }
    return vsLastCardText(current, this.exercise.lastSets);
  }

  private nextText(): string {
    return nextTargetText(this.exercise.lastSets, this.exercise.movementPattern, this.exercise.weightStep,
      this.exercise.isBodyweight);
  }

  private volumeText(): string {
    const rows: TrendSetRow[] = [];
    for (let i = 0; i < this.exercise.sets.length; i++) {
      const item: SetItem = this.exercise.sets[i];
      const row: TrendSetRow = new TrendSetRow();
      row.partKey = this.exercise.partKey;
      row.movementPattern = this.exercise.movementPattern;
      row.isBodyweight = this.exercise.isBodyweight;
      row.isUnilateral = this.exercise.isUnilateral;
      row.bodyWeightKg = this.exercise.bodyWeightKg;
      row.isWarmup = item.isWarmup;
      row.technique = item.technique;
      row.status = item.status;
      const parsedWeight = parseWeight(item.weightText);
      const parsedReps = parseReps(item.repsText);
      row.weight = parsedWeight.ok ? parsedWeight.value : null;
      row.reps = parsedReps.ok ? parsedReps.value : null;
      rows.push(row);
    }
    return formatExerciseVolume(rows);
  }

  private weightPlaceholder(): string {
    if (this.exercise.isBodyweight === 1) {
      return '额外负重 kg';
    }
    if (this.exercise.isUnilateral === 1) {
      return '每侧 kg';
    }
    return '重量 kg';
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
        Row() {
          Column() {
            Text(this.expanded ? '▼' : '▶')
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
          Text(this.exercise.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (!this.expanded) {
            Text(`${this.exercise.sets.length} 组`)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
          }
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.onToggle();
        })
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

      if (this.expanded) {
        TextInput({ text: this.exercise.note, placeholder: '这个动作的备注（可选）' })
          .height(36)
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .maxLength(80)
          .onChange((value: string) => {
            this.exercise.note = value;
            this.scheduleNote();
          })

        if (this.volumeText().length > 0) {
          Text(this.volumeText())
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ top: 8 })
        }

        if (this.exercise.isUnilateral === 1) {
          Text('次数按每侧。左右做完算一组，容量按两侧合计。')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 6 })
        }

        if (this.exercise.lastHint.length > 0) {
          Text(this.exercise.lastHint)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 4 })
        }

        if (this.progressText().length > 0) {
          Text(this.progressText())
            .fontSize(13)
            .fontColor(this.progressText().indexOf('+') >= 0 ? $r('app.color.accent') : $r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 2 })
        }

        if (this.nextText().length > 0) {
          Text(this.nextText())
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ top: 2 })
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
              weightStep: this.exercise.weightStep,
              weightPlaceholder: this.weightPlaceholder(),
              repsPlaceholder: this.exercise.isUnilateral === 1 ? '每侧次数' : '次数',
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
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .margin({ bottom: 10 })
  }
}
