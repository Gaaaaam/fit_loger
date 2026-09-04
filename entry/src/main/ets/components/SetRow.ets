import { keepReps, keepWeight } from '../common/InputUtil';
import { parseReps, parseWeight, ParseResult, statusAfterEdit, toggleSetStatus } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { SetItem } from '../model/DayModels';
import { isDefaultTag, rirLabel, tagChipLabel } from '../model/types';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct SetRow {
  @ObjectLink setItem: SetItem;
  @Prop weightPlaceholder: string = '重量 kg';
  onDeleted: (setId: number) => void = (_setId: number) => {
  };
  onBecameDone: (item: SetItem) => void = (_item: SetItem) => {
  };
  onStatusChanged: () => void = () => {
  };
  private saveTimer: number = -1;
  private becameDonePending: boolean = false;

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
    const wasPlanned: boolean = this.setItem.status === 'planned';
    const change = statusAfterEdit(this.setItem.status, Date.now());
    this.setItem.status = change.status === 'done' ? 'done' : 'planned';
    if (change.completedAt !== null) {
      this.setItem.completedAt = change.completedAt;
    }
    if (wasPlanned) {
      this.becameDonePending = true;
    }
    this.scheduleSave();
    this.onStatusChanged();
  }

  private flushSave(): void {
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
      if (this.becameDonePending) {
        this.becameDonePending = false;
        this.onBecameDone(this.setItem);
      }
    }).catch(() => {
      hilog.error(0xF170, 'SetRow', 'writeSet failed');
    });
  }

  private toggleDone(): void {
    const change = toggleSetStatus(this.setItem.status, Date.now());
    const nowDone: boolean = change.status === 'done';
    this.setItem.status = nowDone ? 'done' : 'planned';
    this.setItem.completedAt = change.completedAt === null ? 0 : change.completedAt;
    this.flushSave();
    this.onStatusChanged();
    if (nowDone) {
      this.onBecameDone(this.setItem);
    }
  }

  private pickTag(): void {
    ActionSheet.show({
      title: '这一组的标记',
      message: '正式组默认不用选。热身不计入容量，递减和递增是技法。',
      sheets: [
        {
          title: '正式',
          action: () => {
            this.setItem.isWarmup = 0;
            this.setItem.technique = '';
            this.flushSave();
          }
        },
        {
          title: '热身',
          action: () => {
            this.setItem.isWarmup = 1;
            this.setItem.technique = '';
            this.flushSave();
          }
        },
        {
          title: '递减',
          action: () => {
            this.setItem.isWarmup = 0;
            this.setItem.technique = 'drop';
            this.flushSave();
          }
        },
        {
          title: '递增',
          action: () => {
            this.setItem.isWarmup = 0;
            this.setItem.technique = 'ramp';
            this.flushSave();
          }
        }
      ],
      cancel: () => {
      }
    });
  }

  @Builder
  rirChip(value: number) {
    Text(rirLabel(value))
      .fontSize(12)
      .fontColor(this.setItem.rir === value ? $r('app.color.text_on_accent') : $r('app.color.text_secondary'))
      .backgroundColor(this.setItem.rir === value ? $r('app.color.accent') : $r('app.color.chip_bg'))
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(12)
      .onClick(() => {
        if (this.setItem.rir === value) {
          this.setItem.rir = -1;
        } else {
          this.setItem.rir = value;
        }
        this.flushSave();
      })
  }

  build() {
    Column() {
      Row() {
        Text(this.setItem.status === 'done' ? '✓' : '○')
          .fontSize(20)
          .fontColor(this.setItem.status === 'done' ? $r('app.color.accent') : $r('app.color.text_secondary'))
          .width(28)
          .onClick(() => {
            this.toggleDone();
          })
        TextInput({ text: this.setItem.weightText, placeholder: this.weightPlaceholder })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.setItem.weightText = keepWeight(value);
            this.markEdited();
          })
        TextInput({ text: this.setItem.repsText, placeholder: '次数' })
          .layoutWeight(1)
          .height(40)
          .margin({ left: 8 })
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.setItem.repsText = keepReps(value);
            this.markEdited();
          })
        if (!isDefaultTag(this.setItem.isWarmup, this.setItem.technique)) {
          Text(tagChipLabel(this.setItem.isWarmup, this.setItem.technique))
            .fontSize(11)
            .fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.accent_soft'))
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .borderRadius(8)
            .margin({ left: 6 })
            .onClick(() => {
              this.pickTag();
            })
        } else {
          Text('标记')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 6, right: 4 })
            .onClick(() => {
              this.pickTag();
            })
        }
        Text('删除')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .padding({ left: 8, right: 2 })
          .onClick(() => {
            this.onDeleted(this.setItem.id);
          })
      }
      .width('100%')
      .opacity(this.setItem.status === 'planned' ? 0.55 : 1)

      if (this.setItem.inputError.length > 0) {
        Text(this.setItem.inputError)
          .fontSize(12)
          .fontColor($r('app.color.danger'))
          .width('100%')
          .margin({ top: 4 })
      }

      Row() {
        Text('这组感觉')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 8 })
        this.rirChip(0)
        this.rirChip(1)
        this.rirChip(3)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
