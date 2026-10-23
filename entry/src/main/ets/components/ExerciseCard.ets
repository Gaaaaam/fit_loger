import { hilog } from '@kit.PerformanceAnalysisKit';
import { formatExerciseVolume, TrendSetRow } from '../common/TrendLogic';
import { parseReps, parseWeight, HintSet, nextTargetText, trimNote, vsLastCardText } from '../common/WorkoutLogic';
import { formatCardioSummary } from '../common/CardioLogic';
import { CardioMetrics } from '../model/CardioModels';
import { CardioSetRow } from './CardioSetRow';
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
  @State showActions: boolean = false;

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
    if (this.exercise.recordType === 'cardio') {
      return '';
    }
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
    if (this.exercise.recordType === 'cardio') {
      return '';
    }
    return nextTargetText(this.exercise.lastSets, this.exercise.movementPattern, this.exercise.weightStep,
      this.exercise.isBodyweight);
  }

  private volumeText(): string {
    if (this.exercise.recordType === 'cardio') {
      const total: CardioMetrics = new CardioMetrics();
      let count: number = 0;
      for (let i = 0; i < this.exercise.sets.length; i++) {
        const item: SetItem = this.exercise.sets[i];
        if (item.status !== 'done' || item.isWarmup === 1 || item.cardio.durationSec === null || item.cardio.durationSec <= 0) {
          continue;
        }
        count++;
        total.durationSec = (total.durationSec === null ? 0 : total.durationSec) + item.cardio.durationSec;
        if (item.cardio.distanceM !== null) {
          total.distanceM = (total.distanceM === null ? 0 : total.distanceM) + item.cardio.distanceM;
        }
        if (item.cardio.steps !== null) {
          total.steps = (total.steps === null ? 0 : total.steps) + item.cardio.steps;
        }
        if (item.cardio.floors !== null) {
          total.floors = (total.floors === null ? 0 : total.floors) + item.cardio.floors;
        }
      }
      return count === 0 ? '' : `已完成 ${count} 段 · ${formatCardioSummary(total, this.exercise.exerciseId)}`;
    }
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

  private isFirstPlanned(setItem: SetItem): boolean {
    const stamp: number = this.listStamp;
    if (stamp < 0) {
      return false;
    }
    for (let i = 0; i < this.exercise.sets.length; i++) {
      if (this.exercise.sets[i].status === 'planned') {
        return this.exercise.sets[i].id === setItem.id;
      }
    }
    return false;
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

  @Builder
  ActionSheet() {
    Column() {
      Text(this.exercise.name)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Column() {
        Text('详情')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(52)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20 })
      .backgroundColor($r('app.color.chip_bg'))
      .borderRadius(12)
      .onClick(() => {
        this.showActions = false;
        this.onOpenDetail(this.exercise);
      })
      Column() {
        Text('删除动作')
          .fontSize(16)
          .fontColor($r('app.color.danger'))
      }
      .width('100%')
      .height(52)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10 })
      .borderRadius(12)
      .backgroundColor($r('app.color.chip_bg'))
      .onClick(() => {
        this.showActions = false;
        this.confirmDelete();
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 36, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
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
            Text(`${this.exercise.sets.length} ${this.exercise.recordType === 'cardio' ? '段' : '组'}`)
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
        Text('···')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
          .width(36)
          .height(28)
          .textAlign(TextAlign.Center)
          .accessibilityText('更多')
          .onClick(() => {
            this.showActions = true;
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
          Text(this.exercise.recordType === 'cardio' ? '还没有训练段，点下方添加' : '还没有组，点下方添加')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 10, bottom: 6 })
            .width('100%')
        } else {
          ForEach(this.exercise.sets, (setItem: SetItem) => {
            if (this.exercise.recordType === 'cardio') {
              CardioSetRow({
                setItem: setItem,
                exerciseId: this.exercise.exerciseId,
                emphasized: this.isFirstPlanned(setItem),
                onDeleted: (setId: number) => { this.onDeleteSet(setId); },
                onBecameDone: (item: SetItem) => { this.onSetBecameDone(this.exercise.exerciseId, item); },
                onStatusChanged: () => { this.onStatusChanged(); }
              })
            } else {
            SetRow({
              setItem: setItem,
              emphasized: this.isFirstPlanned(setItem),
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
            }
          }, (setItem: SetItem) => this.setKey(setItem))
        }

        Button(this.exercise.recordType === 'cardio' ? '添加一段' : '添加组')
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
    .bindSheet($$this.showActions, this.ActionSheet, {
      height: 320,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.card_bg')
    })
  }
}
