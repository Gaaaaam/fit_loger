import { keepReps, keepWeight } from '../common/InputUtil';
import { formatWeight, parseReps, parseWeight, ParseResult, statusAfterEdit, stepWeight, toggleSetStatus } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { SetItem } from '../model/DayModels';
import { isDefaultTag, rirLabel, tagChipLabel } from '../model/types';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct SetRow {
  @ObjectLink setItem: SetItem;
  @Prop weightPlaceholder: string = '重量 kg';
  @Prop repsPlaceholder: string = '次数';
  @Prop weightStep: number = 0;
  @Prop emphasized: boolean = false;
  onDeleted: (setId: number) => void = (_setId: number) => {
  };
  onBecameDone: (item: SetItem) => void = (_item: SetItem) => {
  };
  onStatusChanged: () => void = () => {
  };
  private saveTimer: number = -1;
  private skipFlushOnClose: boolean = false;
  @State showTagPicker: boolean = false;
  @State detailTick: number = 0;

  aboutToDisappear(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
    this.flushSave();
  }

  private scheduleSave(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
    }
    this.saveTimer = setTimeout(() => {
      this.saveTimer = -1;
      this.flushSave();
    }, 280);
  }

  private markEdited(): void {
    const change = statusAfterEdit(this.setItem.status, Date.now());
    this.setItem.status = change.status === 'done' ? 'done' : 'planned';
    this.scheduleSave();
  }

  private flushSave(notifyDone: boolean = false): void {
    const w: ParseResult = parseWeight(this.setItem.weightText);
    const r: ParseResult = parseReps(this.setItem.repsText);
    if (!w.ok) {
      this.setItem.inputError = w.error;
      return;
    }
    if (!r.ok) {
      this.setItem.inputError = r.error;
      return;
    }
    this.setItem.inputError = '';
    WorkoutRepository.writeSet(this.setItem).then((err: string) => {
      if (err.length > 0) {
        this.setItem.inputError = err;
        return;
      }
      if (notifyDone && this.setItem.status === 'done') {
        this.onBecameDone(this.setItem);
      }
    }).catch(() => {
      this.setItem.inputError = '保存失败，请重试';
      hilog.error(0xF170, 'SetRow', 'writeSet failed');
    });
  }

  private toggleDone(): void {
    const weight: ParseResult = parseWeight(this.setItem.weightText);
    const reps: ParseResult = parseReps(this.setItem.repsText);
    if (!weight.ok || !reps.ok) {
      this.setItem.inputError = !weight.ok ? weight.error : reps.error;
      return;
    }
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
    const change = toggleSetStatus(this.setItem.status, Date.now());
    const nowDone: boolean = change.status === 'done';
    this.setItem.status = nowDone ? 'done' : 'planned';
    this.setItem.completedAt = change.completedAt === null ? 0 : change.completedAt;
    this.flushSave(nowDone);
    this.onStatusChanged();
  }

  private pickTag(): void {
    this.showTagPicker = true;
  }

  private nudgeWeight(direction: number): void {
    if (!(this.weightStep > 0)) {
      return;
    }
    const parsed: ParseResult = parseWeight(this.setItem.weightText);
    if (!parsed.ok) {
      return;
    }
    this.setItem.weightText = formatWeight(stepWeight(parsed.value, this.weightStep, direction));
    this.markEdited();
  }

  private flushPending(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
    this.flushSave();
  }

  private deleteThisSet(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
      this.saveTimer = -1;
    }
    this.skipFlushOnClose = true;
    this.showTagPicker = false;
    this.onDeleted(this.setItem.id);
  }

  private hasTagChip(): boolean {
    return !isDefaultTag(this.setItem.isWarmup, this.setItem.technique);
  }

  private hasLegacyRir(): boolean {
    return this.setItem.rirLegacy === 1 && this.setItem.rir >= 0;
  }

  private applyTag(warmup: number, technique: string): void {
    this.setItem.isWarmup = warmup;
    this.setItem.technique = technique;
    this.detailTick++;
    this.flushSave();
  }

  private pickRir(value: number): void {
    const tick: number = this.detailTick;
    if (this.setItem.rirLegacy === 0 && this.setItem.rir === value) {
      this.setItem.rir = -1;
    } else {
      this.setItem.rir = value;
    }
    this.setItem.rirLegacy = 0;
    this.detailTick = tick + 1;
    this.flushSave();
  }

  private rirSelected(value: number): boolean {
    const tick: number = this.detailTick;
    if (tick < 0) {
      return false;
    }
    return this.setItem.rirLegacy === 0 && this.setItem.rir === value;
  }

  private optionLine(): string {
    const tick: number = this.detailTick;
    if (tick < 0) {
      return '';
    }
    const parts: string[] = [];
    if (this.hasTagChip()) {
      parts.push(tagChipLabel(this.setItem.isWarmup, this.setItem.technique));
    }
    if (this.setItem.rirLegacy === 0 && this.setItem.rir >= 0) {
      parts.push(rirLabel(this.setItem.rir, 0));
    }
    return parts.join(' · ');
  }

  @Builder
  weightStepButton(label: string, direction: number) {
    Text(label)
      .fontSize(20)
      .fontColor($r('app.color.text_secondary'))
      .width(36)
      .height(40)
      .textAlign(TextAlign.Center)
      .accessibilityText(direction < 0 ? '减少一步重量' : '增加一步重量')
      .onClick(() => {
        this.nudgeWeight(direction);
      })
  }

  @Builder
  tagButton(label: string, warmup: number, technique: string) {
    Button(label)
      .layoutWeight(1)
      .height(48)
      .fontSize(16)
      .fontColor(this.setItem.isWarmup === warmup && this.setItem.technique === technique ?
        $r('app.color.text_on_accent') : $r('app.color.text_primary'))
      .backgroundColor(this.setItem.isWarmup === warmup && this.setItem.technique === technique ?
        $r('app.color.accent') : $r('app.color.chip_bg'))
      .onClick(() => {
        this.applyTag(warmup, technique);
      })
  }

  @Builder
  TagPicker() {
    Scroll() {
      Column({ space: 12 }) {
        Text('这一组')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 8 })
        Text('标记')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ top: 8 })
        Row({ space: 12 }) {
          this.tagButton('正式', 0, '');
          this.tagButton('热身', 1, '');
        }.width('100%')
        Row({ space: 12 }) {
          this.tagButton('递减', 0, 'drop');
          this.tagButton('递增', 0, 'ramp');
        }.width('100%')
        Row({ space: 12 }) {
          this.tagButton('休息暂停', 0, 'rest_pause');
          this.tagButton('AMRAP', 0, 'amrap');
        }.width('100%')
        Text('热身不计入训练量。递减、递增、休息暂停不用于估计最大重量，AMRAP 可以。选择标记不会完成这一组。')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Text('还能做几下')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ top: 16 })
        if (this.hasLegacyRir()) {
          Text(rirLabel(this.setItem.rir, 1))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
        Row({ space: 12 }) {
          this.rirChip(0)
          this.rirChip(1)
        }.width('100%')
        Row({ space: 12 }) {
          this.rirChip(2)
          this.rirChip(3)
        }.width('100%')
        TextInput({ text: this.setItem.note, placeholder: '这组备注（可选）' })
          .height(40)
          .width('100%')
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .maxLength(80)
          .onChange((value: string) => {
            this.setItem.note = value;
            this.scheduleSave();
          })
        Button('删除这一组', { type: ButtonType.Normal })
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor($r('app.color.danger'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 4 })
          .onClick(() => {
            this.deleteThisSet();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 40, bottom: 28 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }

  @Builder
  rirChip(value: number) {
    Button(rirLabel(value, 0))
      .layoutWeight(1)
      .height(48)
      .fontSize(16)
      .fontColor(this.rirSelected(value) ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
      .backgroundColor(this.rirSelected(value) ? $r('app.color.accent') : $r('app.color.chip_bg'))
      .onClick(() => {
        this.pickRir(value);
      })
  }

  @Builder
  doneMark() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.setItem.status === 'done' ? '✓' : '')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_on_accent'))
        .width(22)
        .height(22)
        .textAlign(TextAlign.Center)
        .borderRadius(11)
        .backgroundColor(this.setItem.status === 'done' ? $r('app.color.accent') : Color.Transparent)
        .border({
          width: this.setItem.status === 'done' ? 0 : 1.5,
          color: $r('app.color.text_secondary')
        })
    }
    .width(44)
    .height(44)
    .accessibilityText(this.setItem.status === 'done' ? '取消完成' : '标记完成')
    .onClick(() => {
      this.toggleDone();
    })
  }

  build() {
    Column() {
      Row() {
        this.doneMark()
        if (this.weightStep > 0) {
          Row() {
            this.weightStepButton('−', -1)
            TextInput({ text: this.setItem.weightText, placeholder: this.weightPlaceholder })
              .layoutWeight(1)
              .height(40)
              .padding({ left: 0, right: 0 })
              .backgroundColor($r('app.color.chip_bg'))
              .textAlign(TextAlign.Center)
              .borderRadius(0)
              .type(InputType.Normal)
              .onChange((value: string) => {
                this.setItem.weightText = keepWeight(value);
                this.markEdited();
              })
            this.weightStepButton('+', 1)
          }
          .layoutWeight(3)
          .height(40)
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(10)
          .clip(true)
          .alignItems(VerticalAlign.Center)
        } else {
          TextInput({ text: this.setItem.weightText, placeholder: this.weightPlaceholder })
            .layoutWeight(3)
            .height(40)
            .backgroundColor($r('app.color.chip_bg'))
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .type(InputType.Normal)
            .onChange((value: string) => {
              this.setItem.weightText = keepWeight(value);
              this.markEdited();
            })
        }
        TextInput({ text: this.setItem.repsText, placeholder: this.repsPlaceholder })
          .layoutWeight(2)
          .height(40)
          .margin({ left: 8 })
          .backgroundColor($r('app.color.chip_bg'))
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.setItem.repsText = keepReps(value);
            this.markEdited();
          })
        Text('···')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
          .width(32)
          .height(40)
          .textAlign(TextAlign.Center)
          .margin({ left: 2 })
          .accessibilityText('更多')
          .onClick(() => {
            this.pickTag();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.setItem.inputError.length > 0 || this.optionLine().length > 0 || this.hasLegacyRir()) {
        Row() {
          Blank().width(44)
          if (this.setItem.inputError.length > 0) {
            Text(this.setItem.inputError)
              .fontSize(12)
              .fontColor($r('app.color.danger'))
              .layoutWeight(1)
              .maxLines(2)
          } else if (this.optionLine().length > 0) {
            Text(this.optionLine())
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          } else {
            Text(rirLabel(this.setItem.rir, 1))
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
              .maxLines(2)
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding({ top: 2, bottom: 2 })
    .margin({ top: 2, bottom: 2 })
    .borderRadius(8)
    .backgroundColor(this.emphasized ? $r('app.color.accent_soft') : Color.Transparent)
    .bindSheet($$this.showTagPicker, this.TagPicker, {
      height: 640,
      dragBar: true,
      showClose: true,
      onDisappear: () => {
        if (this.skipFlushOnClose) {
          this.skipFlushOnClose = false;
          return;
        }
        this.flushPending();
      }
    })
  }
}
