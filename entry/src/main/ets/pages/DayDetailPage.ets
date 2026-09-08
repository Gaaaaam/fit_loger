import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { BodyPartSheet } from '../components/BodyPartSheet';
import { CreateExerciseSheet } from '../components/CreateExerciseSheet';
import { ExerciseCard } from '../components/ExerciseCard';
import { ExerciseInfoView } from '../components/ExerciseInfoView';
import { ExerciseSheet } from '../components/ExerciseSheet';
import { PartSection } from '../components/PartSection';
import { displayChineseDate, todayString } from '../common/DateUtil';
import { parseReps, parseWeight, ParseResult, insertIndexBySortOrder } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { DayModel, ExerciseItem, PartItem, PrResult, RecentDayInfo, SetItem } from '../model/DayModels';
import { WorkoutViewMode } from '../model/muscleTypes';
import { PartKey, partName, toPartKey } from '../model/types';

interface RouterDateParams {
  date: string;
}

@Entry
@Component
struct DayDetailPage {
  @State dateStr: string = '';
  @State titleText: string = '';
  @State day: DayModel = new DayModel();
  @State viewMode: WorkoutViewMode = 'part';
  @State showSheet: boolean = false;
  @State sheetMode: string = 'part';
  @State pickerPartKey: PartKey = 'chest';
  @State infoId: string = '';
  @State infoName: string = '';
  @State infoPart: PartKey = 'chest';
  @State recentDays: RecentDayInfo[] = [];
  @State undoVisible: boolean = false;
  @State undoLabel: string = '';
  @State plannedTick: number = 0;
  private undoItem: SetItem = new SetItem();
  private undoExerciseRowId: number = 0;
  private undoTimer: number = -1;
  private listScroller: Scroller = new Scroller();
  private pickerOpened: boolean = false;

  aboutToAppear(): void {
    const raw: Object | undefined = router.getParams();
    if (raw !== undefined) {
      const params: RouterDateParams = raw as RouterDateParams;
      if (params.date !== undefined && params.date.length > 0) {
        this.dateStr = params.date;
      }
    }
    if (this.dateStr.length === 0) {
      this.dateStr = todayString();
    }
    this.titleText = displayChineseDate(this.dateStr);
    this.loadViewMode();
    this.reload();
  }

  onPageShow(): void {
    if (this.pickerOpened) {
      this.pickerOpened = false;
      this.reload();
    }
  }

  private async loadViewMode(): Promise<void> {
    this.viewMode = await AppSettings.loadWorkoutViewMode();
  }

  private hasPlanned(): boolean {
    const tick: number = this.plannedTick;
    if (tick < 0) {
      return false;
    }
    const list: ExerciseItem[] = this.orderedExercises();
    for (let i = 0; i < list.length; i++) {
      const sets: SetItem[] = list[i].sets;
      for (let k = 0; k < sets.length; k++) {
        if (sets[k].status === 'planned') {
          return true;
        }
      }
    }
    return false;
  }

  private orderedExercises(): ExerciseItem[] {
    if (this.day.exercises.length > 0) {
      return this.day.exercises;
    }
    const list: ExerciseItem[] = [];
    for (let i = 0; i < this.day.parts.length; i++) {
      for (let j = 0; j < this.day.parts[i].exercises.length; j++) {
        list.push(this.day.parts[i].exercises[j]);
      }
    }
    return list;
  }

  private hasRecords(): boolean {
    return this.orderedExercises().length > 0;
  }

  private findExercise(exerciseRowId: number): ExerciseItem | null {
    const list: ExerciseItem[] = this.orderedExercises();
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === exerciseRowId) {
        return list[i];
      }
    }
    return null;
  }

  private ensurePart(partKey: PartKey): PartItem {
    for (let i = 0; i < this.day.parts.length; i++) {
      if (this.day.parts[i].partKey === partKey) {
        return this.day.parts[i];
      }
    }
    const part: PartItem = new PartItem();
    part.partKey = partKey;
    part.name = partName(partKey);
    part.id = this.day.parts.length + 1;
    this.day.parts.push(part);
    this.notifyParts();
    return part;
  }

  // @Observed V1 只监听属性赋值，不监听嵌套数组的 push/splice。
  // 改完数组后必须换成新引用，ForEach / 空态才能立刻刷新，且 ForEach key 不变故不会拆掉正在输入的组。
  private notifyParts(): void {
    this.day.parts = this.day.parts.slice();
  }

  private notifyExercises(part: PartItem): void {
    part.exercises = part.exercises.slice();
  }

  private notifySets(ex: ExerciseItem): void {
    ex.sets = ex.sets.slice();
  }

  private notifyDayExercises(): void {
    this.day.exercises = this.day.exercises.slice();
  }

  private async reload(): Promise<void> {
    try {
      this.day = await WorkoutRepository.loadDay(this.dateStr);
      this.plannedTick++;
    } catch (err) {
      hilog.error(0xF170, 'DayDetailPage', 'reload failed');
      if (this.day.date.length === 0) {
        this.day.date = this.dateStr;
      }
    }
  }

  private async handlePickPart(key: PartKey): Promise<void> {
    this.pickerPartKey = key;
    this.sheetMode = 'exercise';
  }

  private async handlePickExercise(exerciseId: string): Promise<void> {
    this.showSheet = false;
    const rowId: number = await WorkoutRepository.addExercise(this.dateStr, exerciseId);
    const loaded: ExerciseItem | null = await WorkoutRepository.loadExerciseRow(rowId, this.dateStr);
    if (loaded === null) {
      return;
    }
    if (this.day.dayId <= 0) {
      const fresh: DayModel = await WorkoutRepository.loadDay(this.dateStr);
      this.day.dayId = fresh.dayId;
    }
    const part: PartItem = this.ensurePart(loaded.partKey);
    part.exercises.push(loaded);
    this.day.exercises.push(loaded);
    this.notifyExercises(part);
    this.notifyDayExercises();
    this.notifyParts();
    this.plannedTick++;

  }

  private async openExercisePicker(partKey: string): Promise<void> {
    const ok: boolean = await this.flushAllInputs();
    if (!ok) {
      return;
    }
    this.pickerPartKey = toPartKey(partKey);
    this.sheetMode = 'exercise';
    this.showSheet = true;
  }

  private openExerciseInfo(exercise: ExerciseItem): void {
    this.infoId = exercise.exerciseId;
    this.infoName = exercise.name;
    this.infoPart = exercise.partKey;
    this.sheetMode = 'info';
    this.showSheet = true;
  }

  private async handleAddSet(exerciseRowId: number): Promise<void> {
    this.getUIContext().getFocusController().clearFocus();
    const setItem: SetItem = await WorkoutRepository.addSet(exerciseRowId);
    const ex: ExerciseItem | null = this.findExercise(exerciseRowId);
    if (ex !== null) {
      ex.sets.push(setItem);
      this.notifySets(ex);
      this.plannedTick++;
    }
  }

  private handleDeleteSet(setId: number): void {
    const list: ExerciseItem[] = this.orderedExercises();
    for (let i = 0; i < list.length; i++) {
      const ex: ExerciseItem = list[i];
      for (let k = 0; k < ex.sets.length; k++) {
        if (ex.sets[k].id === setId) {
          this.undoItem = ex.sets[k];
          this.undoExerciseRowId = ex.id;
          ex.sets.splice(k, 1);
          this.notifySets(ex);
          WorkoutRepository.deleteSet(setId).catch(() => {
            hilog.error(0xF170, 'DayDetailPage', 'deleteSet failed');
          });
          this.showUndoBar('已删除一组');
          this.plannedTick++;
          return;
        }
      }
    }
  }

  private showUndoBar(label: string): void {
    this.undoLabel = label;
    this.undoVisible = true;
    if (this.undoTimer !== -1) {
      clearTimeout(this.undoTimer);
    }
    this.undoTimer = setTimeout(() => {
      this.undoVisible = false;
      this.undoTimer = -1;
    }, 5000);
  }

  private async undoDeleteSet(): Promise<void> {
    if (this.undoExerciseRowId <= 0 || this.undoItem.id <= 0) {
      return;
    }
    const newId: number = await WorkoutRepository.insertSetCopy(this.undoExerciseRowId, this.undoItem);
    this.undoItem.id = newId;
    const ex: ExerciseItem | null = this.findExercise(this.undoExerciseRowId);
    if (ex !== null) {
      const orders: number[] = [];
      for (let i = 0; i < ex.sets.length; i++) {
        orders.push(ex.sets[i].sortOrder);
      }
      const at: number = insertIndexBySortOrder(orders, this.undoItem.sortOrder);
      ex.sets.splice(at, 0, this.undoItem);
      this.notifySets(ex);
      this.plannedTick++;
    }
    this.undoVisible = false;
    this.undoExerciseRowId = 0;
  }

  private async handleDeleteExercise(exerciseRowId: number): Promise<void> {
    await WorkoutRepository.deleteExercise(exerciseRowId);
    for (let i = 0; i < this.day.parts.length; i++) {
      const part: PartItem = this.day.parts[i];
      for (let j = 0; j < part.exercises.length; j++) {
        if (part.exercises[j].id === exerciseRowId) {
          part.exercises.splice(j, 1);
          this.notifyExercises(part);
          this.removeDayExercise(exerciseRowId);
          if (part.exercises.length === 0) {
            this.day.parts.splice(i, 1);
          }
          this.notifyParts();
          this.plannedTick++;
          return;
        }
      }
    }
  }

  private async handleDeletePart(partKey: string): Promise<void> {
    await WorkoutRepository.deleteExercisesOfPart(this.dateStr, toPartKey(partKey));
    for (let i = 0; i < this.day.parts.length; i++) {
      if (this.day.parts[i].partKey === partKey) {
        const removed: PartItem = this.day.parts[i];
        for (let j = 0; j < removed.exercises.length; j++) {
          this.removeDayExercise(removed.exercises[j].id);
        }
        this.day.parts.splice(i, 1);
        this.notifyParts();
        this.plannedTick++;
        return;
      }
    }
  }

  private async handleClearPlanned(): Promise<void> {
    await WorkoutRepository.clearPlannedSets(this.dateStr);
    for (let i = 0; i < this.day.parts.length; i++) {
      const part: PartItem = this.day.parts[i];
      for (let j = 0; j < part.exercises.length; j++) {
        const ex: ExerciseItem = part.exercises[j];
        const kept: SetItem[] = [];
        for (let k = 0; k < ex.sets.length; k++) {
          if (ex.sets[k].status !== 'planned') {
            kept.push(ex.sets[k]);
          }
        }
        if (kept.length !== ex.sets.length) {
          ex.sets = kept;
        }
      }
    }
    this.notifyParts();
    this.notifyDayExercises();
    this.plannedTick++;
  }

  private removeDayExercise(exerciseRowId: number): void {
    for (let i = 0; i < this.day.exercises.length; i++) {
      if (this.day.exercises[i].id === exerciseRowId) {
        this.day.exercises.splice(i, 1);
        this.notifyDayExercises();
        return;
      }
    }
  }

  private async flushAllInputs(): Promise<boolean> {
    this.getUIContext().getFocusController().clearFocus();
    const list: ExerciseItem[] = this.orderedExercises();
    for (let i = 0; i < list.length; i++) {
      const sets: SetItem[] = list[i].sets;
      for (let k = 0; k < sets.length; k++) {
        const item: SetItem = sets[k];
        const w: ParseResult = parseWeight(item.weightText);
        const r: ParseResult = parseReps(item.repsText);
        if (!w.ok) {
          item.inputError = w.error;
          promptAction.showToast({ message: '请先修正输入', duration: 2000 });
          return false;
        }
        if (!r.ok) {
          item.inputError = r.error;
          promptAction.showToast({ message: '请先修正输入', duration: 2000 });
          return false;
        }
        try {
          const err: string = await WorkoutRepository.writeSet(item);
          if (err.length > 0) {
            item.inputError = err;
            promptAction.showToast({ message: '保存失败，请先修正输入', duration: 2000 });
            return false;
          }
          item.inputError = '';
        } catch (e) {
          item.inputError = '保存失败，请重试';
          promptAction.showToast({ message: '保存失败，请先修正输入', duration: 2000 });
          return false;
        }
      }
    }
    return true;
  }

  private async setViewMode(mode: WorkoutViewMode): Promise<void> {
    if (this.viewMode === mode) {
      return;
    }
    const ok: boolean = await this.flushAllInputs();
    if (!ok) {
      return;
    }
    const previous: WorkoutViewMode = this.viewMode;
    this.viewMode = mode;
    try {
      await AppSettings.saveWorkoutViewMode(mode);
    } catch (err) {
      this.viewMode = previous;
      hilog.error(0xF170, 'DayDetailPage', 'save view mode failed');
    }
  }

  private async openMusclePicker(): Promise<void> {
    if (this.pickerOpened) {
      return;
    }
    this.pickerOpened = true;
    const ok: boolean = await this.flushAllInputs();
    if (!ok) {
      this.pickerOpened = false;
      return;
    }
    router.pushUrl({
      url: 'pages/MusclePickerPage',
      params: { date: this.dateStr }
    }).catch(() => {
      this.pickerOpened = false;
    });
  }

  private async openAddEntry(): Promise<void> {
    if (this.viewMode === 'exercise') {
      await this.openMusclePicker();
      return;
    }
    const ok: boolean = await this.flushAllInputs();
    if (!ok) {
      return;
    }
    this.sheetMode = 'part';
    this.showSheet = true;
  }

  private async openCopySheet(): Promise<void> {
    const ok: boolean = await this.flushAllInputs();
    if (!ok) {
      return;
    }
    this.recentDays = await WorkoutRepository.listRecentDays(8);
    this.sheetMode = 'copy';
    this.showSheet = true;
  }

  private async handleCopy(fromDate: string): Promise<void> {
    this.showSheet = false;
    const copied: boolean = await WorkoutRepository.copyDay(fromDate, this.dateStr);
    if (!copied) {
      promptAction.showToast({ message: '当天已有动作，未复制', duration: 2000 });
      return;
    }
    await this.reload();
  }

  private async handleCreated(exerciseId: string): Promise<void> {
    await this.handlePickExercise(exerciseId);
  }

  private async handleBecameDone(exerciseId: string, item: SetItem): Promise<void> {
    const w = parseWeight(item.weightText);
    const r = parseReps(item.repsText);
    if (!w.ok) {
      return;
    }
    const pr: PrResult = await WorkoutRepository.checkPr(exerciseId, w.value, r.value, item.id);
    if (pr.weightPr) {
      promptAction.showToast({ message: '新的最重重量', duration: 2000 });
    } else if (pr.repsPr) {
      promptAction.showToast({ message: '该重量下新的次数纪录', duration: 2000 });
    }
  }

  private confirmDeleteDay(): void {
    AlertDialog.show({
      title: '删除当天',
      message: '将删除这一天的全部训练记录。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: () => {
          this.handleDeleteDay();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  private async handleDeleteDay(): Promise<void> {
    await WorkoutRepository.deleteDay(this.dateStr);
    router.back();
  }

  @Builder
  SheetBuilder() {
    Column() {
      if (this.sheetMode === 'exercise') {
        ExerciseSheet({
          partKey: this.pickerPartKey,
          onPick: (exerciseId: string) => {
            this.handlePickExercise(exerciseId);
          },
          onCreate: () => {
            this.sheetMode = 'create';
          }
        })
      } else if (this.sheetMode === 'create') {
        CreateExerciseSheet({
          defaultPart: this.pickerPartKey,
          onCreated: (exerciseId: string) => {
            this.handleCreated(exerciseId);
          }
        })
      } else if (this.sheetMode === 'info') {
        Column() {
          Text('动作说明')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 12 })
          ExerciseInfoView({
            exerciseId: this.infoId,
            displayName: this.infoName,
            partKey: this.infoPart,
            showAdd: false
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      } else if (this.sheetMode === 'copy') {
        Column() {
          Text('复制哪一次训练')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
            .margin({ bottom: 12 })
          if (this.recentDays.length === 0) {
            Text('还没有可以复制的训练')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            ForEach(this.recentDays, (item: RecentDayInfo) => {
              Text(`${item.date}  ${item.summary}`)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding({ top: 14, bottom: 14 })
                .onClick(() => {
                  this.handleCopy(item.date);
                })
            }, (item: RecentDayInfo) => item.date)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8 })
      } else {
        BodyPartSheet({
          onPick: (key: PartKey) => {
            this.handlePickPart(key);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      Row() {
        Text('< 日历')
          .fontSize(16)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            router.back();
          })
        Blank()
        if (this.hasRecords()) {
          Text('删除当天')
            .fontSize(16)
            .fontColor($r('app.color.danger'))
            .onClick(() => {
              this.confirmDeleteDay();
            })
        }
      }
      .width('100%')
      .padding({ bottom: 8 })

      Text(this.titleText)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 10 })

      Row({ space: 8 }) {
        Text('部位')
          .fontSize(14)
          .fontWeight(this.viewMode === 'part' ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.viewMode === 'part' ? $r('app.color.accent') : $r('app.color.text_secondary'))
          .backgroundColor(this.viewMode === 'part' ? $r('app.color.accent_soft') : Color.Transparent)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => {
            this.setViewMode('part');
          })
        Text('动作')
          .fontSize(14)
          .fontWeight(this.viewMode === 'exercise' ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.viewMode === 'exercise' ? $r('app.color.accent') : $r('app.color.text_secondary'))
          .backgroundColor(this.viewMode === 'exercise' ? $r('app.color.accent_soft') : Color.Transparent)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => {
            this.setViewMode('exercise');
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (!this.hasRecords()) {
        Column() {
          Text('这一天还没有训练记录')
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 16 })
          Button('添加动作')
            .backgroundColor($r('app.color.accent'))
            .fontColor($r('app.color.text_on_accent'))
            .margin({ bottom: 12 })
            .onClick(() => {
              this.openAddEntry();
            })
          Button('复制上次训练')
            .fontSize(15)
            .fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.accent_soft'))
            .onClick(() => {
              this.openCopySheet();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          Text(this.hasPlanned() ? '还有未完成的组' : '所有组已完成')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
          Text('清理未完成组')
            .fontSize(13)
            .fontColor($r('app.color.accent'))
            .visibility(this.hasPlanned() ? Visibility.Visible : Visibility.Hidden)
            .onClick(() => {
              this.handleClearPlanned();
            })
        }
        .width('100%')
        .height(36)

        Scroll(this.listScroller) {
          Column() {
            if (this.viewMode === 'exercise') {
              ForEach(this.day.exercises, (exercise: ExerciseItem) => {
                ExerciseCard({
                  exercise: exercise,
                  listStamp: this.plannedTick,
                  onAddSet: (exerciseRowId: number) => {
                    this.handleAddSet(exerciseRowId);
                  },
                  onDeleteExercise: (exerciseRowId: number) => {
                    this.handleDeleteExercise(exerciseRowId);
                  },
                  onDeleteSet: (setId: number) => {
                    this.handleDeleteSet(setId);
                  },
                  onSetBecameDone: (exerciseId: string, item: SetItem) => {
                    this.handleBecameDone(exerciseId, item);
                  },
                  onStatusChanged: () => {
                    this.plannedTick++;
                  },
                  onOpenDetail: (item: ExerciseItem) => {
                    this.openExerciseInfo(item);
                  }
                })
              }, (exercise: ExerciseItem) => `${exercise.id}`)
            } else {
              ForEach(this.day.parts, (part: PartItem) => {
                PartSection({
                  part: part,
                  listStamp: this.plannedTick,
                  onAddExercise: (partKey: string) => {
                    this.openExercisePicker(partKey);
                  },
                  onDeletePart: (partKey: string) => {
                    this.handleDeletePart(partKey);
                  },
                  onAddSet: (exerciseRowId: number) => {
                    this.handleAddSet(exerciseRowId);
                  },
                  onDeleteExercise: (exerciseRowId: number) => {
                    this.handleDeleteExercise(exerciseRowId);
                  },
                  onDeleteSet: (setId: number) => {
                    this.handleDeleteSet(setId);
                  },
                  onSetBecameDone: (exerciseId: string, item: SetItem) => {
                    this.handleBecameDone(exerciseId, item);
                  },
                  onStatusChanged: () => {
                    this.plannedTick++;
                  },
                  onOpenDetail: (item: ExerciseItem) => {
                    this.openExerciseInfo(item);
                  }
                })
              }, (part: PartItem) => part.partKey)
            }

            Button(this.viewMode === 'exercise' ? '添加动作' : '添加部位')
              .fontSize(15)
              .fontColor($r('app.color.accent'))
              .backgroundColor($r('app.color.accent_soft'))
              .width('100%')
              .height(44)
              .margin({ bottom: 24 })
              .onClick(() => {
                this.openAddEntry();
              })
          }.width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      if (this.undoVisible) {
        Row() {
          Text(this.undoLabel)
            .fontSize(14)
            .fontColor($r('app.color.text_on_accent'))
            .layoutWeight(1)
          Text('撤销')
            .fontSize(14)
            .fontColor($r('app.color.text_on_accent'))
            .onClick(() => {
              this.undoDeleteSet();
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.accent'))
        .borderRadius(8)
        .margin({ bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 12 })
    .backgroundColor($r('app.color.page_bg'))
    .bindSheet($$this.showSheet, this.SheetBuilder, {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true
    })
  }
}
