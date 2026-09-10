import { CalendarCell } from '../model/DayModels';
import { DayDotKind } from '../model/types';
import { displayMonthTitle, weekdayLabels } from '../common/DateUtil';
import { calendarCellKey } from '../common/WorkoutLogic';

@Component
export struct MonthCalendar {
  @Prop year: number = 2026;
  @Prop month: number = 0;
  @Prop cells: CalendarCell[] = [];
  @Prop epoch: number = 0;
  private weekLabels: string[] = weekdayLabels();
  onPrev: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onSelectDate: (date: string) => void = (_date: string) => {
  };

  private itemKey(cell: CalendarCell): string {
    if (!cell.inMonth) {
      return cell.key;
    }
    return `${calendarCellKey(cell.date, cell.dotKind)}#${this.epoch}`;
  }

  @Builder
  statusDot(kind: DayDotKind) {
    if (kind === 'trained') {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .margin({ top: 4 })
        .backgroundColor($r('app.color.dot_trained'))
    } else if (kind === 'planned') {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .margin({ top: 4 })
        .backgroundColor($r('app.color.dot_planned'))
    } else if (kind === 'missed') {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .margin({ top: 4 })
        .backgroundColor($r('app.color.dot_missed'))
    } else {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .margin({ top: 4 })
        .backgroundColor(Color.Transparent)
    }
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor($r('app.color.text_primary'))
          .padding(8)
          .onClick(() => {
            this.onPrev();
          })
        Text(displayMonthTitle(this.year, this.month))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('>')
          .fontSize(22)
          .fontColor($r('app.color.text_primary'))
          .padding(8)
          .onClick(() => {
            this.onNext();
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8, bottom: 8 })

      Row() {
        ForEach(this.weekLabels, (label: string) => {
          Text(label)
            .fontSize(13)
            .fontColor($r('app.color.weekday_text'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (label: string) => label)
      }
      .width('100%')
      .padding({ bottom: 6 })

      Grid() {
        ForEach(this.cells, (cell: CalendarCell) => {
          GridItem() {
            Column() {
              if (cell.inMonth) {
                Text(`${cell.day}`)
                  .fontSize(17)
                  .fontWeight(cell.isToday ? FontWeight.Medium : FontWeight.Regular)
                  .fontColor(cell.isToday ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .borderRadius(20)
                  .backgroundColor(cell.isToday ? $r('app.color.today_bg') : Color.Transparent)
                this.statusDot(cell.dotKind)
              }
            }
            .width('100%')
            .height(72)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              if (cell.inMonth) {
                this.onSelectDate(cell.date);
              }
            })
          }
        }, (cell: CalendarCell) => this.itemKey(cell))
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(0)
      .rowsGap(4)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }
}
