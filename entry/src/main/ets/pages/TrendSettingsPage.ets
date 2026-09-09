import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { PART_ORDER, TrendPreferences, WatchableExercise } from '../common/TrendLogic';
import { parseReps } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { partName } from '../model/types';

class PartGoalInput {
  partKey: string = '';
  text: string = '';
  error: string = '';
}

@Entry
@Component
struct TrendSettingsPage {
  @State sessionsTargetText: string = '';
  @State sessionsError: string = '';
  @State partGoalInputs: PartGoalInput[] = [];
  @State watchable: WatchableExercise[] = [];
  @State selectedIds: string[] = [];
  @State saving: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const prefs: TrendPreferences = await WorkoutRepository.loadTrendPreferences();
      this.sessionsTargetText = prefs.sessionsTarget === null ? '' : `${prefs.sessionsTarget}`;
      const goalByPart: Map<string, number> = new Map();
      for (let i = 0; i < prefs.partGoals.length; i++) {
        if (prefs.partGoals[i].workSetsTarget !== null) {
          goalByPart.set(prefs.partGoals[i].partKey, prefs.partGoals[i].workSetsTarget as number);
        }
      }
      const inputs: PartGoalInput[] = [];
      for (let i = 0; i < PART_ORDER.length; i++) {
        const item: PartGoalInput = new PartGoalInput();
        item.partKey = PART_ORDER[i];
        const value: number | undefined = goalByPart.get(PART_ORDER[i]);
        item.text = value === undefined ? '' : `${value}`;
        inputs.push(item);
      }
      this.partGoalInputs = inputs;
      this.selectedIds = prefs.watchedExerciseIds.slice();
      this.watchable = await WorkoutRepository.listExercisesWithHistory();
    } catch (err) {
      hilog.error(0xF170, 'TrendSettingsPage', 'load failed');
    }
  }

  private isSelected(exerciseId: string): boolean {
    return this.selectedIds.indexOf(exerciseId) !== -1;
  }

  private toggleWatched(exerciseId: string): void {
    const idx: number = this.selectedIds.indexOf(exerciseId);
    if (idx !== -1) {
      const next: string[] = this.selectedIds.slice();
      next.splice(idx, 1);
      this.selectedIds = next;
      return;
    }
    if (this.selectedIds.length >= 5) {
      promptAction.showToast({ message: '最多关注 5 个动作', duration: 1500 });
      return;
    }
    this.selectedIds = this.selectedIds.concat([exerciseId]);
  }

  private validateSessions(): boolean {
    const trimmed: string = this.sessionsTargetText.trim();
    if (trimmed.length === 0) {
      this.sessionsError = '';
      return true;
    }
    const parsed = parseReps(trimmed);
    if (!parsed.ok || parsed.value === null) {
      this.sessionsError = '训练天数无效';
      return false;
    }
    if (parsed.value < 1 || parsed.value > 7) {
      this.sessionsError = '训练天数需在 1-7 之间';
      return false;
    }
    this.sessionsError = '';
    return true;
  }

  private validatePartGoal(item: PartGoalInput): boolean {
    const trimmed: string = item.text.trim();
    if (trimmed.length === 0) {
      item.error = '';
      return true;
    }
    const parsed = parseReps(trimmed);
    if (!parsed.ok || parsed.value === null) {
      item.error = '目标无效';
      return false;
    }
    if (parsed.value < 1 || parsed.value > 50) {
      item.error = '目标需在 1-50 之间';
      return false;
    }
    item.error = '';
    return true;
  }

  private async handleSave(): Promise<void> {
    if (this.saving) {
      return;
    }
    let valid: boolean = this.validateSessions();
    for (let i = 0; i < this.partGoalInputs.length; i++) {
      if (!this.validatePartGoal(this.partGoalInputs[i])) {
        valid = false;
      }
    }
    this.partGoalInputs = this.partGoalInputs.slice();
    if (!valid) {
      return;
    }
    this.saving = true;
    try {
      const sessionsTrimmed: string = this.sessionsTargetText.trim();
      const sessionsTarget: number | null = sessionsTrimmed.length === 0 ? null : Number(sessionsTrimmed);
      await WorkoutRepository.saveSessionsTarget(sessionsTarget);
      for (let i = 0; i < this.partGoalInputs.length; i++) {
        const item: PartGoalInput = this.partGoalInputs[i];
        const trimmed: string = item.text.trim();
        const target: number | null = trimmed.length === 0 ? null : Number(trimmed);
        await WorkoutRepository.savePartGoal(item.partKey, target);
      }
      await WorkoutRepository.setWatchedExercises(this.selectedIds);
      promptAction.showToast({ message: '已保存', duration: 1500 });
      router.back();
    } catch (err) {
      hilog.error(0xF170, 'TrendSettingsPage', 'save failed');
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.saving = false;
    }
  }

  @Builder
  partGoalRow(item: PartGoalInput) {
    Column() {
      Row() {
        Text(partName(item.partKey))
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .width(56)
        TextInput({ text: item.text, placeholder: '不设目标' })
          .layoutWeight(1)
          .height(40)
          .type(InputType.Number)
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .onChange((value: string) => {
            item.text = value;
          })
        Text('组/周')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
      }
      .width('100%')
      if (item.error.length > 0) {
        Text(item.error)
          .fontSize(12)
          .fontColor($r('app.color.danger'))
          .width('100%')
          .margin({ top: 4, left: 56 })
      }
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  watchableRow(item: WatchableExercise) {
    Row() {
      Column() {
        Text(item.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text(`${partName(item.partKey)} · ${item.sessions} 次训练`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(this.isSelected(item.exerciseId) ? '已关注' : '关注')
        .fontSize(13)
        .fontColor(this.isSelected(item.exerciseId) ? $r('app.color.text_on_accent') : $r('app.color.accent'))
        .textAlign(TextAlign.Center)
        .width(64)
        .height(32)
        .borderRadius(8)
        .backgroundColor(this.isSelected(item.exerciseId) ? $r('app.color.accent') : $r('app.color.accent_soft'))
        .onClick(() => {
          this.toggleWatched(item.exerciseId);
        })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
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

      Text('趋势设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 16 })

      Scroll() {
        Column() {
          Text('每周训练天数')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: 8 })

          Column() {
            TextInput({ text: this.sessionsTargetText, placeholder: '例如 4（不设置留空）' })
              .height(44)
              .type(InputType.Number)
              .backgroundColor($r('app.color.chip_bg'))
              .borderRadius(8)
              .onChange((value: string) => {
                this.sessionsTargetText = value;
              })
            if (this.sessionsError.length > 0) {
              Text(this.sessionsError)
                .fontSize(12)
                .fontColor($r('app.color.danger'))
                .width('100%')
                .margin({ top: 6 })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)

          Text('各部位每周正式组目标')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: 20, bottom: 8 })

          Column() {
            ForEach(this.partGoalInputs, (item: PartGoalInput) => {
              this.partGoalRow(item)
            }, (item: PartGoalInput) => item.partKey)
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)

          Row() {
            Text('关注动作')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
            Text(`${this.selectedIds.length}/5`)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .margin({ top: 20, bottom: 8 })

          Column() {
            if (this.watchable.length === 0) {
              Text('还没有训练记录，先去练几组吧')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            } else {
              ForEach(this.watchable, (item: WatchableExercise) => {
                this.watchableRow(item)
              }, (item: WatchableExercise) => item.exerciseId)
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(16)
          .margin({ bottom: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Button(this.saving ? '保存中…' : '保存')
        .width('100%')
        .height(46)
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .margin({ top: 12 })
        .enabled(!this.saving)
        .onClick(() => {
          this.handleSave();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 12 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
