import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { MonthCalendar } from '../components/MonthCalendar';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { buildMonthCells, shiftMonth, todayString } from '../common/DateUtil';
import { CalendarCell } from '../model/DayModels';

@Entry
@Component
struct CalendarPage {
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth();
  @State markedDates: string[] = [];
  @State cells: CalendarCell[] = [];

  aboutToAppear(): void {
    this.refreshCells();
    this.reloadMarks();
  }

  onPageShow(): void {
    this.reloadMarks();
  }

  private refreshCells(): void {
    this.cells = buildMonthCells(this.year, this.month, this.markedDates);
  }

  private async reloadMarks(): Promise<void> {
    try {
      this.markedDates = await WorkoutRepository.listDatesInMonth(this.year, this.month);
    } catch (err) {
      hilog.error(0xF170, 'CalendarPage', 'reloadMarks failed');
      this.markedDates = [];
    }
    this.refreshCells();
  }

  private changeMonth(delta: number): void {
    const next: number[] = shiftMonth(this.year, this.month, delta);
    this.year = next[0];
    this.month = next[1];
    this.refreshCells();
    this.reloadMarks();
  }

  private openDay(date: string): void {
    router.pushUrl({
      url: 'pages/DayDetailPage',
      params: {
        'date': date
      }
    }).catch(() => {
      hilog.error(0xF170, 'CalendarPage', 'failed to open day detail');
    });
  }

  private async handleExport(): Promise<void> {
    try {
      const path: string = await WorkoutRepository.writeExportFiles();
      promptAction.showToast({ message: `已导出到 ${path}`, duration: 3500 });
    } catch (err) {
      promptAction.showToast({ message: '导出失败', duration: 2000 });
    }
  }

  private async handleImport(): Promise<void> {
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const documentPicker = new picker.DocumentViewPicker();
      const uris: string[] = await documentPicker.select(options);
      if (uris.length === 0) {
        return;
      }
      let text: string = '';
      try {
        text = fileIo.readTextSync(uris[0]);
      } catch (readErr) {
        const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
        const buf: ArrayBuffer = new ArrayBuffer(4 * 1024 * 1024);
        const len: number = fileIo.readSync(file.fd, buf);
        fileIo.closeSync(file);
        const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
        text = decoder.decodeToString(new Uint8Array(buf, 0, len));
      }
      await WorkoutRepository.importJsonText(text);
      await this.reloadMarks();
      promptAction.showToast({ message: '导入完成', duration: 2000 });
    } catch (err) {
      promptAction.showToast({ message: '导入失败，请选择 JSON 导出文件', duration: 2500 });
    }
  }

  build() {
    Column() {
      Row() {
        Text('训练日志')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text('体重')
          .fontSize(15)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/BodyMetricsPage' }).catch(() => {
            });
          })
      }
      .width('100%')

      Text('点选日期记录训练')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 12, top: 4 })

      Button('记录今天')
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .width('100%')
        .height(44)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.openDay(todayString());
        })

      Column() {
        MonthCalendar({
          year: this.year,
          month: this.month,
          cells: this.cells,
          onPrev: () => {
            this.changeMonth(-1);
          },
          onNext: () => {
            this.changeMonth(1);
          },
          onSelectDate: (date: string) => {
            this.openDay(date);
          }
        })
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)

      Row() {
        Text('导出 JSON/CSV')
          .fontSize(14)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.handleExport();
          })
        Blank()
        Text('从 JSON 导入')
          .fontSize(14)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.handleImport();
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 28, bottom: 16 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
