import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { MonthCalendar } from '../components/MonthCalendar';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { buildMonthCells, shiftMonth, todayString } from '../common/DateUtil';
import { CalendarCell, DayMark } from '../model/DayModels';

@Component
export struct CalendarPage {
  @Consume('calRefresh') @Watch('onRefreshStamp') refreshStamp: number = 0;
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth();
  @State marks: DayMark[] = [];
  @State cells: CalendarCell[] = [];

  aboutToAppear(): void {
    this.refreshCells();
    this.reloadMarks();
  }

  onRefreshStamp(): void {
    this.reloadMarks();
  }

  private refreshCells(): void {
    this.cells = buildMonthCells(this.year, this.month, this.marks, todayString());
  }

  private async reloadMarks(): Promise<void> {
    try {
      this.marks = await WorkoutRepository.listMonthDayMarks(this.year, this.month);
      hilog.info(0xF170, 'CalendarPage', 'reloadMarks %{public}d days', this.marks.length);
    } catch (err) {
      hilog.error(0xF170, 'CalendarPage', 'reloadMarks failed');
      this.marks = [];
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

  @Builder
  legendItem(kind: string, label: string) {
    Row() {
      if (kind === 'rest') {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.dot_rest'))
          .margin({ right: 6 })
      } else if (kind === 'trained') {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.danger'))
          .margin({ right: 6 })
      } else if (kind === 'planned') {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.dot_planned'))
          .margin({ right: 6 })
      } else {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor($r('app.color.dot_empty'))
          .margin({ right: 6 })
      }
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
  }

  build() {
    Column() {
      Text('训练日志')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Button('记录今天')
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .width('100%')
        .height(44)
        .margin({ top: 12, bottom: 12 })
        .onClick(() => {
          this.openDay(todayString());
        })

      Column() {
        MonthCalendar({
          year: this.year,
          month: this.month,
          cells: this.cells,
          epoch: this.refreshStamp,
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

        Row() {
          this.legendItem('rest', '休息')
          this.legendItem('trained', '已训练')
          this.legendItem('planned', '已计划')
          this.legendItem('empty', '未安排')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .padding(12)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 28, bottom: 8 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
