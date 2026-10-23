import { hilog } from '@kit.PerformanceAnalysisKit';
import { CardioDraft, CardioInputField, cardioDetailFields, cardioDraftOf, cardioFieldText,
  changeCardioField, parseCardioDraft } from '../common/CardioInputLogic';
import { averageCardioSpeedKmh, formatCardioDuration, rowerSplitSecPer500m } from '../common/CardioLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { SetItem } from '../model/DayModels';

@Component
export struct CardioSetRow {
  @ObjectLink setItem: SetItem;
  @Prop exerciseId: string = '';
  @Prop emphasized: boolean = false;
  @State draft: CardioDraft = new CardioDraft();
  @State detailsExpanded: boolean = false;
  @State completing: boolean = false;
  onDeleted: (setId: number) => void = (_id: number) => {};
  onBecameDone: (item: SetItem) => void = (_item: SetItem) => {};
  onStatusChanged: () => void = () => {};
  private saveTimer: number = -1;
  private deleting: boolean = false;
  private editRevision: number = 0;
  private saveRevision: number = 0;

  aboutToAppear(): void {
    this.draft = cardioDraftOf(this.setItem.cardio, this.exerciseId);
  }

  aboutToDisappear(): void {
    this.cancelTimer();
    if (!this.deleting) {
      this.persist();
    }
  }

  private cancelTimer(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
  }

  private scheduleSave(): void {
    this.editRevision++;
    this.cancelTimer();
    this.saveTimer = setTimeout(() => {
      this.saveTimer = -1;
      this.persist();
    }, 280);
  }

  private changeField(key: string, text: string): void {
    changeCardioField(this.draft, key, text);
    const parsed = parseCardioDraft(this.draft, this.exerciseId, this.setItem.status === 'done');
    this.setItem.inputError = parsed.error;
    if (parsed.ok) {
      this.setItem.cardio = parsed.metrics;
    }
    this.scheduleSave();
  }

  private async persist(): Promise<boolean> {
    const parsed = parseCardioDraft(this.draft, this.exerciseId, this.setItem.status === 'done');
    if (!parsed.ok) {
      this.setItem.inputError = parsed.error;
      return false;
    }
    this.setItem.cardio = parsed.metrics;
    this.setItem.recordType = 'cardio';
    this.setItem.exerciseId = this.exerciseId;
    this.setItem.technique = '';
    this.setItem.rir = -1;
    this.setItem.rirLegacy = 0;
    const editRevision: number = this.editRevision;
    const saveRevision: number = ++this.saveRevision;
    try {
      const error: string = await WorkoutRepository.writeSet(this.setItem);
      this.applySaveError(error, editRevision, saveRevision);
      return error.length === 0;
    } catch (_error) {
      this.applySaveError('保存失败，请重试', editRevision, saveRevision);
      hilog.error(0xF170, 'CardioSetRow', 'writeSet failed');
      return false;
    }
  }

  private applySaveError(error: string, editRevision: number, saveRevision: number): void {
    const current = parseCardioDraft(this.draft, this.exerciseId, this.setItem.status === 'done');
    if (!current.ok) {
      this.setItem.inputError = current.error;
    } else if (this.editRevision === editRevision && this.saveRevision === saveRevision) {
      this.setItem.inputError = error;
    }
  }

  private async toggleDone(): Promise<void> {
    if (this.completing) {
      return;
    }
    const nowDone: boolean = this.setItem.status !== 'done';
    const parsed = parseCardioDraft(this.draft, this.exerciseId, nowDone);
    if (!parsed.ok) {
      this.setItem.inputError = parsed.error;
      return;
    }
    this.cancelTimer();
    const previousStatus = this.setItem.status;
    const previousTime: number = this.setItem.completedAt;
    this.completing = true;
    this.setItem.status = nowDone ? 'done' : 'planned';
    this.setItem.completedAt = nowDone ? Date.now() : 0;
    const saved: boolean = await this.persist();
    this.completing = false;
    if (!saved) {
      this.setItem.status = previousStatus;
      this.setItem.completedAt = previousTime;
      return;
    }
    this.onStatusChanged();
    if (nowDone) {
      this.onBecameDone(this.setItem);
    }
  }

  private derivedText(): string {
    const parsed = parseCardioDraft(this.draft, this.exerciseId, false);
    if (!parsed.ok) {
      return '';
    }
    if (this.exerciseId === 'cardio_rower') {
      const split: number | null = rowerSplitSecPer500m(parsed.metrics);
      return split === null ? '' : `平均配速 ${formatCardioDuration(split)} /500 m`;
    }
    if (this.exerciseId === 'cardio_treadmill') {
      const speed: number | null = averageCardioSpeedKmh(parsed.metrics);
      return speed === null ? '' : `计算平均速度 ${Number(speed.toFixed(2))} km/h`;
    }
    return '';
  }

  @Builder
  basicField(key: string, label: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(11).fontColor($r('app.color.text_secondary')).width('100%')
      TextInput({ text: cardioFieldText(this.draft, key), placeholder: '—' })
        .height(40).width('100%').padding({ left: 8, right: 8 })
        .backgroundColor($r('app.color.chip_bg')).borderRadius(8)
        .type(InputType.Normal).accessibilityText(label)
        .onChange((value: string) => { this.changeField(key, value); })
    }.layoutWeight(1)
  }

  @Builder
  detailField(field: CardioInputField) {
    Row({ space: 10 }) {
      Text(field.label).fontSize(13).fontColor($r('app.color.text_secondary')).layoutWeight(1)
      TextInput({ text: cardioFieldText(this.draft, field.key), placeholder: '选填' })
        .width('45%').height(38).padding({ left: 10, right: 10 })
        .backgroundColor($r('app.color.chip_bg')).borderRadius(8)
        .type(InputType.Normal).accessibilityText(field.label)
        .onChange((value: string) => { this.changeField(field.key, value); })
    }.width('100%')
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Button(this.setItem.status === 'done' ? '✓' : '○', { type: ButtonType.Circle })
          .width(40).height(40).fontSize(20).margin({ top: 16 })
          .backgroundColor(this.setItem.status === 'done' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .fontColor(this.setItem.status === 'done' ? $r('app.color.text_on_accent') : $r('app.color.text_secondary'))
          .accessibilityText(this.setItem.status === 'done' ? '取消完成这一段' : '完成这一段')
          .enabled(!this.completing).onClick(() => { this.toggleDone(); })
        this.basicField('minutes', '时长 · 分')
        this.basicField('seconds', '秒')
        if (this.exerciseId !== 'cardio_stair_climber') {
          this.basicField('distance', this.exerciseId === 'cardio_rower' ? '距离 m' : '距离 km')
        }
      }.width('100%').alignItems(VerticalAlign.Center)

      Row() {
        Text(this.detailsExpanded ? '收起详细指标 ▲' : '详细指标（选填）▼')
          .fontSize(12).fontColor($r('app.color.accent')).layoutWeight(1)
          .padding({ top: 8, bottom: 8 }).onClick(() => { this.detailsExpanded = !this.detailsExpanded; })
        if (this.setItem.isWarmup === 1) {
          Text('热身').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ right: 10 })
        }
      }.width('100%')

      if (this.detailsExpanded) {
        ForEach(cardioDetailFields(this.exerciseId), (field: CardioInputField) => {
          this.detailField(field)
        }, (field: CardioInputField) => field.key)
        Text('按器械面板填写；档位只作本次器械的记录，热量不自动估算。')
          .fontSize(11).fontColor($r('app.color.text_secondary')).width('100%')
        Row() {
          Text('热身段').fontSize(13).fontColor($r('app.color.text_primary')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.setItem.isWarmup === 1 })
            .selectedColor($r('app.color.accent')).onChange((value: boolean) => {
              this.setItem.isWarmup = value ? 1 : 0;
              this.scheduleSave();
            })
        }.width('100%')
        TextInput({ text: this.setItem.note, placeholder: '这一段的备注（可选）' })
          .height(40).width('100%').maxLength(80).backgroundColor($r('app.color.chip_bg')).borderRadius(8)
          .onChange((value: string) => { this.setItem.note = value; this.scheduleSave(); })
        Button('删除这一段', { type: ButtonType.Normal })
          .width('100%').height(36).fontSize(13).fontColor($r('app.color.danger'))
          .backgroundColor($r('app.color.chip_bg')).borderRadius(8).enabled(!this.completing)
          .onClick(() => { this.cancelTimer(); this.deleting = true; this.onDeleted(this.setItem.id); })
      }
      if (this.derivedText().length > 0) {
        Text(this.derivedText()).fontSize(12).fontColor($r('app.color.text_secondary')).width('100%')
      }
      if (this.setItem.inputError.length > 0) {
        Text(this.setItem.inputError).fontSize(12).fontColor($r('app.color.danger')).width('100%')
      }
    }
    .width('100%').padding(10).borderRadius(10).margin({ top: 8 })
    .backgroundColor(this.emphasized ? $r('app.color.accent_soft') : Color.Transparent)
  }
}
