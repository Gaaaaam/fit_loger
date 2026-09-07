import { TrendSparkline } from '../components/TrendSparkline';
import { digestQueryStart, buildTrendDigest, formatTrendNumber, liftChangeText, liftMetricLabel,
  KeyLiftSeries, PartVolumeRow, TrendDigest, TrendPoint, TrendSetRow, TrendWeightRow, weightDeltaText } from '../common/TrendLogic';
import { todayString } from '../common/DateUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { partName } from '../model/types';

@Component
export struct TrendsPage {
  @Consume('calRefresh') @Watch('onRefreshStamp') refreshStamp: number = 0;
  @State rangeKind: string = '12';
  @State digest: TrendDigest = new TrendDigest();

  aboutToAppear(): void {
    this.reload();
  }

  onRefreshStamp(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    const today: string = todayString();
    const fromDate: string = digestQueryStart(today, this.rangeKind);
    try {
      const rows: TrendSetRow[] = await WorkoutRepository.loadTrendSets(fromDate, today);
      const weights: TrendWeightRow[] = await WorkoutRepository.loadTrendWeights(today);
      this.digest = buildTrendDigest(rows, weights, today, this.rangeKind);
    } catch (err) {
      this.digest = new TrendDigest();
    }
  }

  private setRange(kind: string): void {
    if (this.rangeKind === kind) {
      return;
    }
    this.rangeKind = kind;
    this.reload();
  }

  private valuesOf(points: TrendPoint[]): number[] {
    const vals: number[] = [];
    for (let i = 0; i < points.length; i++) {
      vals.push(points[i].value);
    }
    return vals;
  }

  private volumeMax(): number {
    let max: number = 1;
    for (let i = 0; i < this.digest.parts.length; i++) {
      const row: PartVolumeRow = this.digest.parts[i];
      if (row.thisWeek > max) {
        max = row.thisWeek;
      }
      if (row.avg4 > max) {
        max = row.avg4;
      }
    }
    return max;
  }

  private barPercent(value: number): string {
    const pct: number = (value / this.volumeMax()) * 100;
    if (pct < 0) {
      return '0%';
    }
    return `${pct}%`;
  }

  private belowAvg(row: PartVolumeRow): boolean {
    return row.thisWeek + 0.05 < row.avg4;
  }

  @Builder
  rangeChip(label: string, kind: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.rangeKind === kind ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(36)
      .borderRadius(8)
      .backgroundColor(this.rangeKind === kind ? $r('app.color.accent') : $r('app.color.chip_bg'))
      .onClick(() => {
        this.setRange(kind);
      })
  }

  @Builder
  summaryCell(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 4 })
        .maxLines(2)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  liftBlock(lift: KeyLiftSeries) {
    Column() {
      Row() {
        Text(lift.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(liftMetricLabel(lift.metric))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      Text(liftChangeText(lift))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 2, bottom: 6 })
      TrendSparkline({ values: this.valuesOf(lift.points) })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  partBlock(row: PartVolumeRow) {
    Column() {
      Row() {
        Text(partName(row.partKey))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .width(40)
        Column() {
          Column()
            .width(this.barPercent(row.thisWeek))
            .height(8)
            .borderRadius(4)
            .backgroundColor($r('app.color.accent'))
        }
        .layoutWeight(1)
        .margin({ left: 8, right: 8 })
        .alignItems(HorizontalAlign.Start)
        Text(`${row.thisWeek}`)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      Text(this.belowAvg(row) ? `近4周均值 ${formatTrendNumber(row.avg4)} · 低于近 4 周` :
        `近4周均值 ${formatTrendNumber(row.avg4)}`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 4, left: 48 })
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  build() {
    Scroll() {
      Column() {
        Text('趋势')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Row() {
          this.rangeChip('4周', '4')
          this.rangeChip('12周', '12')
          this.rangeChip('全部', 'all')
        }
        .width('100%')
        .margin({ top: 16, bottom: 16 })

        Text('本周')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: 8 })

        Row() {
          this.summaryCell('训练', `${this.digest.sessions} 次`)
          this.summaryCell('正式组', `${this.digest.workSets}`)
          this.summaryCell('体重', weightDeltaText(this.digest))
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)

        Text('力量')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 20, bottom: 8 })

        Column() {
          if (this.digest.lifts.length === 0) {
            Text('还没有足够的动作记录')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            ForEach(this.digest.lifts, (lift: KeyLiftSeries) => {
              this.liftBlock(lift)
            }, (lift: KeyLiftSeries) => lift.exerciseId)
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)

        Text('容量')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 20, bottom: 8 })

        Column() {
          if (this.digest.parts.length === 0) {
            Text('本周还没有正式组')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            ForEach(this.digest.parts, (row: PartVolumeRow) => {
              this.partBlock(row)
            }, (row: PartVolumeRow) => row.partKey)
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)

        Text('身体')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 20, bottom: 8 })

        Column() {
          if (this.digest.weights.length === 0) {
            Text('还没有体重记录')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            Text(weightDeltaText(this.digest))
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .margin({ bottom: 8 })
            TrendSparkline({ values: this.valuesOf(this.digest.weights) })
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(16)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 28, bottom: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .scrollBar(BarState.Off)
  }
}
