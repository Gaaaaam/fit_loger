import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { TrendSparkline } from '../components/TrendSparkline';
import { TermHint } from '../components/TermHint';
import { TrendGuideCard } from '../components/TrendGuideCard';
import {
  buildTrendDigest,
  chartFromDate,
  KeyLiftSeries,
  liftChangeText,
  liftMetricLabel,
  PartGoalProgress,
  TrendDigest,
  TrendInsight,
  TrendPreferences,
  TrendSetRow,
  TrendWeightRow,
  weightDeltaText
} from '../common/TrendLogic';
import { closeCtaKind, findTerm, guideHighlight, nextGuideStep } from '../common/TrendGuide';
import { addDays, isoWeekStart, todayString } from '../common/DateUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { partName } from '../model/types';

@Component
export struct TrendsPage {
  @Consume('calRefresh') @Watch('onRefreshStamp') refreshStamp: number = 0;
  @Consume('mainTabIndex') @Watch('onMainTab') mainTabIndex: number = 0;
  @State rangeKind: string = '12';
  @State digest: TrendDigest = new TrendDigest();
  @State prefs: TrendPreferences = new TrendPreferences();
  @State hasAnyWorkSet: boolean = false;
  @State guideSeen: boolean = true;
  @State guideOpen: boolean = false;
  @State guideStep: string = 'intro';
  @State showTermSheet: boolean = false;
  @State activeTermId: string = '';
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.reload();
  }

  onRefreshStamp(): void {
    this.reload();
  }

  onMainTab(): void {
    this.maybeAutoStartGuide();
  }

  private async reload(): Promise<void> {
    const today: string = todayString();
    try {
      this.guideSeen = await AppSettings.loadTrendsGuideSeen();
    } catch (err) {
      hilog.error(0xF170, 'TrendsPage', 'guide flag load failed');
    }
    try {
      this.hasAnyWorkSet = await WorkoutRepository.hasAnyDoneWorkSet();
      this.prefs = await WorkoutRepository.loadTrendPreferences();
      const fromDate: string = chartFromDate(today, this.rangeKind);
      const rows: TrendSetRow[] = await WorkoutRepository.loadTrendSets(fromDate, today);
      const weights: TrendWeightRow[] = await WorkoutRepository.loadTrendWeights(today);
      this.digest = buildTrendDigest(rows, weights, today, this.rangeKind, this.prefs);
    } catch (err) {
      hilog.error(0xF170, 'TrendsPage', 'reload failed');
      this.digest = new TrendDigest();
      this.prefs = new TrendPreferences();
    }
    this.maybeAutoStartGuide();
  }

  private maybeAutoStartGuide(): void {
    if (this.guideOpen || this.guideSeen) {
      return;
    }
    if (this.mainTabIndex !== 1) {
      return;
    }
    this.guideOpen = true;
    this.guideStep = 'intro';
  }

  private startGuide(): void {
    this.guideOpen = true;
    this.guideStep = 'intro';
    this.scrollGuideStep('intro');
  }

  private setRange(kind: string): void {
    if (this.guideOpen || this.rangeKind === kind) {
      return;
    }
    this.rangeKind = kind;
    this.reload();
  }

  private openSettings(): void {
    if (this.guideOpen) {
      return;
    }
    router.pushUrl({ url: 'pages/TrendSettingsPage' }).catch(() => {
      hilog.error(0xF170, 'TrendsPage', 'failed to open settings');
    });
  }

  private openDetail(exerciseId: string): void {
    if (this.guideOpen || exerciseId.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/TrendExerciseDetailPage',
      params: { exerciseId: exerciseId, rangeKind: this.rangeKind }
    }).catch(() => {
      hilog.error(0xF170, 'TrendsPage', 'failed to open exercise detail');
    });
  }

  private openToday(): void {
    router.pushUrl({
      url: 'pages/DayDetailPage',
      params: { date: todayString() }
    }).catch(() => {
      hilog.error(0xF170, 'TrendsPage', 'failed to open today');
    });
  }

  private openTerm(id: string): void {
    this.activeTermId = id;
    this.showTermSheet = true;
  }

  private async finishGuide(cta: string): Promise<void> {
    this.guideOpen = false;
    this.guideSeen = true;
    await AppSettings.saveTrendsGuideSeen(true);
    if (cta === 'log_first') {
      this.openToday();
    }
  }

  private handleGuideNext(): void {
    const next: string = nextGuideStep(this.guideStep);
    if (next.length === 0) {
      this.finishGuide(closeCtaKind(this.hasAnyWorkSet));
      return;
    }
    this.guideStep = next;
    this.scrollGuideStep(next);
  }

  private handleGuideSkip(): void {
    this.finishGuide('');
  }

  private scrollGuideStep(step: string): void {
    let y: number = 0;
    if (step === 'lifts') {
      y = 280;
    } else if (step === 'weight') {
      y = 560;
    }
    this.scroller.scrollTo({ xOffset: 0, yOffset: y, animation: { duration: 280 } });
  }

  private isHighlight(section: string): boolean {
    return this.guideOpen && guideHighlight(this.guideStep) === section;
  }

  private insightText(): string {
    const insight: TrendInsight = this.digest.insight;
    if (insight.kind === 'part_goal') {
      return `${partName(insight.partKey)}本周还差 ${insight.remaining} 组正式组`;
    }
    return insight.message;
  }

  private weekGoalTitle(): string {
    const today: string = todayString();
    const start: string = isoWeekStart(today);
    const end: string = addDays(start, 6);
    return `本周目标 · ${start.slice(5).replace('-', '/')}–${end.slice(5).replace('-', '/')}`;
  }

  private termTitle(): string {
    return findTerm(this.activeTermId).title;
  }

  private termBody(): string {
    return findTerm(this.activeTermId).body;
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
  sectionHeader(title: string, showSettings: boolean) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      if (showSettings) {
        Text('设置')
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.openSettings();
          })
      }
    }
    .width('100%')
    .margin({ top: 20, bottom: 8 })
  }

  @Builder
  insightCard() {
    if (this.digest.insight.kind !== 'none') {
      Row() {
        Text(this.insightText())
          .fontSize(14)
          .fontColor($r('app.color.text_on_accent'))
          .layoutWeight(1)
        if (this.digest.insight.kind === 'setup') {
          Text('去设置')
            .fontSize(13)
            .fontColor($r('app.color.text_on_accent'))
            .onClick(() => {
              this.openSettings();
            })
        } else if (this.digest.insight.kind === 'stall' || this.digest.insight.kind === 'progress') {
          Text('查看')
            .fontSize(13)
            .fontColor($r('app.color.text_on_accent'))
            .onClick(() => {
              this.openDetail(this.digest.insight.exerciseId);
            })
        }
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('app.color.accent'))
      .borderRadius(16)
      .margin({ top: 16 })
    }
  }

  @Builder
  partGoalRow(row: PartGoalProgress) {
    Row() {
      Text(partName(row.partKey))
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .width(48)
      Text(`${row.done} / ${row.target} 组`)
        .fontSize(14)
        .fontColor(row.done >= row.target ? $r('app.color.accent') : $r('app.color.text_primary'))
        .layoutWeight(1)
      Text(row.done >= row.target ? '已达标' : `还差 ${row.target - row.done}`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .margin({ bottom: 8 })
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
        if (lift.metric === 'e1rm') {
          TermHint({
            termId: 'e1rm',
            onOpen: (id: string) => {
              this.openTerm(id);
            }
          })
        }
      }
      .width('100%')
      Text(liftChangeText(lift))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 2, bottom: 6 })
      if (lift.insufficientData || lift.points.length === 0) {
        Row() {
          Text('数据不足：还没有足够的可比较正式组')
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
        .margin({ bottom: 6 })
      }
      if (lift.points.length > 0) {
        TrendSparkline({ points: lift.points })
      }
    }
    .width('100%')
    .margin({ bottom: 12 })
    .onClick(() => {
      this.openDetail(lift.exerciseId);
    })
  }

  @Builder
  TermSheet() {
    Column() {
      Text(this.termTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Text(this.termBody())
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scroller) {
        Column() {
          Row() {
            Text('趋势')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Text('说明')
              .fontSize(14)
              .fontColor($r('app.color.accent'))
              .onClick(() => {
                this.startGuide();
              })
          }
          .width('100%')

          Row() {
            this.rangeChip('4周', '4')
            this.rangeChip('12周', '12')
            this.rangeChip('全部', 'all')
          }
          .width('100%')
          .margin({ top: 16 })

          this.insightCard()

          this.sectionHeader(this.weekGoalTitle(), true)

          Column() {
            Row() {
              Text('训练次数')
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              Text(this.digest.weekGoal.sessionsTarget === null ? `${this.digest.weekGoal.sessionsDone} 次` :
                `${this.digest.weekGoal.sessionsDone} / ${this.digest.weekGoal.sessionsTarget} 次`)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')
            .margin({ bottom: this.digest.weekGoal.parts.length > 0 ? 10 : 0 })

            if (this.digest.weekGoal.parts.length > 0) {
              ForEach(this.digest.weekGoal.parts, (row: PartGoalProgress) => {
                this.partGoalRow(row)
              }, (row: PartGoalProgress) => row.partKey)
            }

            if (this.digest.weekGoal.sessionsTarget === null && this.digest.weekGoal.parts.length === 0) {
              Text('还没有设置每周目标，去设置一下')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ top: 8 })
                .onClick(() => {
                  this.openSettings();
                })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
          .border({
            width: this.isHighlight('weekGoal') ? 2 : 0,
            color: $r('app.color.accent')
          })
          .id('trendWeekGoal')

          this.sectionHeader('关注动作', true)

          Column() {
            if (this.digest.lifts.length === 0) {
              Text(this.prefs.watchedExerciseIds.length === 0 ? '还没有足够的训练记录，先去练几组吧' :
                '关注的动作在当前范围内还没有记录')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            } else {
              if (this.prefs.watchedExerciseIds.length === 0) {
                Text('还没有设置关注动作，先自动展示训练最多的动作')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .margin({ bottom: 10 })
              }
              ForEach(this.digest.lifts, (lift: KeyLiftSeries) => {
                this.liftBlock(lift)
              }, (lift: KeyLiftSeries) => lift.exerciseId)
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
          .border({
            width: this.isHighlight('lifts') ? 2 : 0,
            color: $r('app.color.accent')
          })
          .id('trendLifts')

          this.sectionHeader('身体趋势', false)

          Column() {
            if (!this.digest.weightTrend.hasWeight) {
              Text('还没有体重记录')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            } else {
              Text(weightDeltaText(this.digest.weightTrend))
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .margin({ bottom: 8 })
              TrendSparkline({ points: this.digest.weightPoints })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
          .border({
            width: this.isHighlight('weight') ? 2 : 0,
            color: $r('app.color.accent')
          })
          .margin({ bottom: this.guideOpen ? 16 : 16 })
          .id('trendWeight')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 28, bottom: this.guideOpen ? 200 : 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      if (this.guideOpen) {
        Column() {
          TrendGuideCard({
            step: this.guideStep,
            hasAnyWorkSet: this.hasAnyWorkSet,
            onNext: () => {
              this.handleGuideNext();
            },
            onSkip: () => {
              this.handleGuideSkip();
            }
          })
        }
        .width('100%')
        .zIndex(8)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .bindSheet($$this.showTermSheet, this.TermSheet, {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.card_bg')
    })
  }
}
