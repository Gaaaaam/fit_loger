import { keepReps, keepWeight } from '../common/InputUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { SetItem } from '../model/DayModels';
import { indexToTag, SET_TAG_OPTIONS, tagToIndex, tagToLabel } from '../model/types';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct SetRow {
  @ObjectLink setItem: SetItem;
  onDeleted: (setId: number) => void = (_setId: number) => {
  };
  private saveTimer: number = -1;

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

  private flushSave(): void {
    WorkoutRepository.updateSet(this.setItem.id, this.setItem.weightText, this.setItem.repsText, this.setItem.tag)
      .catch(() => {
        hilog.error(0xF170, 'SetRow', 'updateSet failed');
      });
  }

  build() {
    Column() {
      Row() {
        TextInput({ text: this.setItem.weightText, placeholder: '重量 kg' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.setItem.weightText = keepWeight(value);
            this.scheduleSave();
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
            this.scheduleSave();
          })
        Text('删除')
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .padding({ left: 10, right: 4 })
          .onClick(() => {
            this.onDeleted(this.setItem.id);
          })
      }
      .width('100%')

      Select([
        { value: SET_TAG_OPTIONS[0] },
        { value: SET_TAG_OPTIONS[1] },
        { value: SET_TAG_OPTIONS[2] },
        { value: SET_TAG_OPTIONS[3] }
      ])
        .selected(tagToIndex(this.setItem.tag))
        .value(tagToLabel(this.setItem.tag))
        .font({ size: 14 })
        .width('100%')
        .height(40)
        .margin({ top: 8 })
        .onSelect((index: number) => {
          this.setItem.tag = indexToTag(index);
          this.flushSave();
        })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
