import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { TrendSparkline } from '../components/TrendSparkline';
import { TermHint } from '../components/TermHint';
import { findTerm } from '../common/TrendGuide';
import {
  buildExerciseTrendDetail,
  chartFromDate,
  ExerciseMeta,
  ExerciseSessionRow,
  ExerciseTrendDetail,
  formatTrendNumber,
  TrendSetRow
} from '../common/TrendLogic';
import { todayString } from '../common/DateUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { partName } from '../model/types';

interface RouterDetailParams {
  exerciseId: string;
  rangeKind: string;
}

@Entry
@Component
struct TrendExerciseDetailPage {
  @State exerciseId: string = '';
  @State rangeKind: string = '12';
  @State detail: ExerciseTrendDetail = new ExerciseTrendDetail();
  @State loaded: boolean = false;
  @State showTermSheet: boolean = false;
  @State activeTermId: string = '';

  aboutToAppear(): void {
    const raw: Object | undefined = router.getParams();
    if (raw !== undefined) {
      const params: RouterDetailParams = raw as RouterDetailParams;
      if (params.exerciseId !== undefined) {
        this.exerciseId = params.exerciseId;
      }
      if (params.rangeKind !== undefined && params.rangeKind.length > 0) {
        this.rangeKind = params.rangeKind;
      }
    }
    this.reload();
  }

  private async reload(): Promise<void> {
    if (this.exerciseId.length === 0) {
      return;
    }
    try {
      const meta: ExerciseMeta | null = await WorkoutRepository.loadExerciseMeta(this.exerciseId);
      if (meta === null) {
        this.loaded = true;
        return;
      }
      const today: string = todayString();
      const fromDate: string = chartFromDate(today, this.rangeKind);
      const rows: TrendSetRow[] = await WorkoutRepository.loadTrendSetsForExercise(this.exerciseId, fromDate, today);
      this.detail = buildExerciseTrendDetail(rows, meta);
      this.loaded = true;
    } catch (err) {
      hilog.error(0xF170, 'TrendExerciseDetailPage', 'reload failed');
      this.loaded = true;
    }
  }

  private setRange(kind: string): void {
    if (this.rangeKind === kind) {
      return;
    }
    this.rangeKind = kind;
    this.reload();
  }

  private openDay(date: string): void {
    router.pushUrl({ url: 'pages/DayDetailPage', params: { date: date } }).catch(() => {
      hilog.error(0xF170, 'TrendExerciseDetailPage', 'failed to open day detail');
    });
  }

  private openTerm(id: string): void {
    this.activeTermId = id;
    this.showTermSheet = true;
  }

  private rangeText(): string {
    const first: ExerciseSessionRow[] = this.detail.recentSessions;
    if (first.length === 0) {
      return '';
    }
    const last: string = first[0].date;
    const start: string = first[first.length - 1].date;
    return `${start} → ${last}`;
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
  sessionRow(item: ExerciseSessionRow) {
    Row() {
      Text(item.date)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(item.value === null ? '无可比较组' : formatTrendNumber(item.value))
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .margin({ right: 12 })
      Text(`${item.workSets} 组`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: 12 })
      Text(item.minRir === null ? 'RIR 未记录' : `RIR ${item.minRir}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      TermHint({
        termId: 'rir',
        onOpen: (id: string) => {
          this.openTerm(id);
        }
      })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      this.openDay(item.date);
    })
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            router.back();
          })
        Blank()
      }
      .width('100%')
      .padding({ bottom: 8 })

      Text(this.detail.name.length > 0 ? this.detail.name : this.exerciseId)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Row() {
        Text(this.detail.partKey.length > 0 ? `${partName(this.detail.partKey)} · ${this.detail.metricLabel}` :
          this.detail.metricLabel)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
        if (this.detail.metric === 'e1rm') {
          TermHint({
            termId: 'e1rm',
            onOpen: (id: string) => {
              this.openTerm(id);
            }
          })
        }
      }
      .width('100%')
      .margin({ top: 4, bottom: 16 })

      Row() {
        this.rangeChip('4周', '4')
        this.rangeChip('12周', '12')
        this.rangeChip('全部', 'all')
      }
      .width('100%')
      .margin({ bottom: 16 })

      Scroll() {
        Column() {
          if (!this.loaded) {
            Text('加载中…')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else if (this.detail.points.length === 0) {
            Text('这个范围内还没有可比较的数据')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          } else {
            Column() {
              if (this.detail.estimated && !this.detail.insufficientData) {
                Text('未填 RIR，曲线为估算')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .margin({ bottom: 8 })
              }
              if (this.detail.insufficientData) {
                Row() {
                  Text('数据不足：还需要至少 2 次可比较的正式组（次数 ≤ 8；没填 RIR 也会按估算计入）')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .layoutWeight(1)
                  TermHint({
                    termId: 'insufficient',
                    onOpen: (id: string) => {
                      this.openTerm(id);
                    }
                  })
                }
                .width('100%')
                .margin({ bottom: 8 })
              }
              Text(this.rangeText())
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })
              TrendSparkline({ points: this.detail.points, chartHeight: 160, showLabels: true, unit: this.detail.metricLabel })
              Row() {
                Text(`${this.detail.sessions} 次训练`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                Text(`${this.detail.workSets} 个正式组`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ left: 12 })
                TermHint({
                  termId: 'work_set',
                  onOpen: (id: string) => {
                    this.openTerm(id);
                  }
                })
              }
              .width('100%')
              .margin({ top: 8 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)

            if (this.detail.secondaryPoints.length > 0) {
              Text(this.detail.secondaryLabel)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ top: 20, bottom: 8 })
              Column() {
                TrendSparkline({
                  points: this.detail.secondaryPoints,
                  chartHeight: 100,
                  showLabels: true,
                  unit: '次'
                })
              }
              .width('100%')
              .padding(14)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(16)
            }

            Text('近期训练')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 20, bottom: 8 })
            Column() {
              if (this.detail.recentSessions.length === 0) {
                Text('还没有训练记录')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
              } else {
                ForEach(this.detail.recentSessions, (item: ExerciseSessionRow) => {
                  this.sessionRow(item)
                }, (item: ExerciseSessionRow) => item.date)
              }
            }
            .width('100%')
            .padding({ left: 14, right: 14 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .margin({ bottom: 16 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 12 })
    .backgroundColor($r('app.color.page_bg'))
    .bindSheet($$this.showTermSheet, this.TermSheet, {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.card_bg')
    })
  }

  @Builder
  TermSheet() {
    Column() {
      Text(findTerm(this.activeTermId).title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Text(findTerm(this.activeTermId).body)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
  }
}
