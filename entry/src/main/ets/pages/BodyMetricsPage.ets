import { promptAction, router } from '@kit.ArkUI';
import { keepWeight } from '../common/InputUtil';
import { parseWeight } from '../common/WorkoutLogic';
import { todayString } from '../common/DateUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { BodyMetric } from '../model/DayModels';

@Entry
@Component
struct BodyMetricsPage {
  @State dateStr: string = todayString();
  @State weightText: string = '';
  @State noteText: string = '';
  @State errorText: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const metric: BodyMetric = await WorkoutRepository.loadBodyMetric(this.dateStr);
    if (metric.hasWeight) {
      this.weightText = `${metric.weightKg}`;
    } else {
      this.weightText = '';
    }
    this.noteText = metric.note;
  }

  private async save(): Promise<void> {
    const parsed = parseWeight(this.weightText);
    if (!parsed.ok) {
      this.errorText = parsed.error;
      return;
    }
    this.errorText = '';
    await WorkoutRepository.upsertBodyMetric(this.dateStr, parsed.value, this.noteText.trim());
    promptAction.showToast({ message: '已保存', duration: 1500 });
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
      }
      .width('100%')
      .padding({ bottom: 12 })

      Text('体重')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 8 })

      Text('一周填一次即可。自重动作的真实负荷会用到这个数字。')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 20 })

      Text(`日期 ${this.dateStr}`)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 12 })

      TextInput({ text: this.weightText, placeholder: '体重 kg' })
        .height(44)
        .backgroundColor($r('app.color.chip_bg'))
        .borderRadius(8)
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.weightText = keepWeight(value);
        })

      TextInput({ text: this.noteText, placeholder: '备注（可选）' })
        .height(44)
        .margin({ top: 12 })
        .backgroundColor($r('app.color.chip_bg'))
        .borderRadius(8)
        .onChange((value: string) => {
          this.noteText = value;
        })

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .margin({ top: 8 })
          .width('100%')
      }

      Button('保存')
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .width('100%')
        .height(44)
        .margin({ top: 20 })
        .onClick(() => {
          this.save();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 16 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
