import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { MonthCalendar } from '../components/MonthCalendar';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { buildMonthCells, shiftMonth } from '../common/DateUtil';
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

  build() {
    Column() {
      Text('训练日志')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 4 })
      Text('点选日期记录训练')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 18 })

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
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 28, bottom: 16 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
