import { CalendarCell } from '../model/DayModels';
import { displayMonthTitle, weekdayLabels } from '../common/DateUtil';

@Component
export struct MonthCalendar {
  @Prop year: number = 2026;
  @Prop month: number = 0;
  @Prop cells: CalendarCell[] = [];
  private weekLabels: string[] = weekdayLabels();
  onPrev: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onSelectDate: (date: string) => void = (_date: string) => {
  };

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
                  .fontSize(16)
                  .fontWeight(cell.isToday ? FontWeight.Medium : FontWeight.Regular)
                  .fontColor(cell.isToday ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .borderRadius(18)
                  .backgroundColor(cell.isToday ? $r('app.color.today_bg') : Color.Transparent)
                Column()
                  .width(5)
                  .height(5)
                  .borderRadius(3)
                  .margin({ top: 2 })
                  .backgroundColor(cell.marked ? $r('app.color.accent') : Color.Transparent)
              }
            }
            .width('100%')
            .height(56)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              if (cell.inMonth) {
                this.onSelectDate(cell.date);
              }
            })
          }
        }, (cell: CalendarCell) => cell.key)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(0)
      .rowsGap(4)
      .width('100%')
    }
    .width('100%')
  }
}
