import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { AppSettings } from '../common/AppSettings';
import { ExerciseModelPreference } from '../common/ExerciseArtworkLogic';
import { keepWeight } from '../common/InputUtil';
import { parseWeight } from '../common/WorkoutLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { BodyMetric } from '../model/DayModels';

@Component
export struct MinePage {
  @Consume('calRefresh') @Watch('onRefreshStamp') refreshStamp: number = 0;
  @State theme: string = 'light';
  @State exerciseModelPreference: ExerciseModelPreference = 'auto';
  private persistedExerciseModelPreference: ExerciseModelPreference = 'auto';
  private exerciseModelPreferenceRequestVersion: number = 0;
  private exerciseModelPreferenceLoad: Promise<void> = Promise.resolve();
  private exerciseModelPreferenceSaveQueue: Promise<void> = Promise.resolve();
  @State heightText: string = '';
  @State heightError: string = '';
  @State latestWeightText: string = '未记录';

  aboutToAppear(): void {
    this.load();
  }

  onRefreshStamp(): void {
    this.loadLatestWeight();
  }

  private async load(): Promise<void> {
    const requestVersionAtLoad: number = this.exerciseModelPreferenceRequestVersion;
    const priorLoad: Promise<void> = this.exerciseModelPreferenceLoad;
    const priorSaves: Promise<void> = this.exerciseModelPreferenceSaveQueue;
    const themeLoad: Promise<string> = AppSettings.loadTheme();
    const preferenceLoad: Promise<void> = priorLoad.catch(() => {}).then(async () => {
      await priorSaves;
      const preference: ExerciseModelPreference = await AppSettings.loadExerciseModelPreference();
      this.persistedExerciseModelPreference = preference;
      if (this.exerciseModelPreferenceRequestVersion === requestVersionAtLoad) {
        this.exerciseModelPreference = preference;
      }
    });
    this.exerciseModelPreferenceLoad = preferenceLoad;
    this.theme = await themeLoad;
    await preferenceLoad;
    const heightCm: number = await AppSettings.loadHeightCm();
    if (heightCm > 0) {
      this.heightText = `${heightCm}`;
    } else {
      this.heightText = '';
    }
    await this.loadLatestWeight();
  }

  private async loadLatestWeight(): Promise<void> {
    try {
      const metric: BodyMetric = await WorkoutRepository.loadLatestBodyMetric();
      if (metric.hasWeight) {
        this.latestWeightText = `${metric.weightKg} kg · ${metric.date}`;
      } else {
        this.latestWeightText = '未记录';
      }
    } catch (err) {
      this.latestWeightText = '未记录';
    }
  }

  private async saveHeight(): Promise<void> {
    const parsed = parseWeight(this.heightText);
    if (!parsed.ok) {
      this.heightError = parsed.error.length > 0 ? parsed.error : '身高无效';
      return;
    }
    this.heightError = '';
    const value: number = parsed.value === null ? 0 : parsed.value;
    await AppSettings.saveHeightCm(value);
    promptAction.showToast({ message: '身高已保存', duration: 1500 });
  }

  private async setTheme(next: string): Promise<void> {
    this.theme = next;
    await AppSettings.saveTheme(next);
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    AppSettings.applyTheme(ctx, next);
  }

  private async setExerciseModelPreference(next: ExerciseModelPreference): Promise<void> {
    const requestVersion: number = ++this.exerciseModelPreferenceRequestVersion;
    const preferenceLoadAtClick: Promise<void> = this.exerciseModelPreferenceLoad;
    this.exerciseModelPreference = next;
    const saveOperation: Promise<void> = this.exerciseModelPreferenceSaveQueue.then(async () => {
      try {
        await preferenceLoadAtClick;
        await AppSettings.saveExerciseModelPreference(next);
        this.persistedExerciseModelPreference = next;
      } catch (err) {
        if (requestVersion !== this.exerciseModelPreferenceRequestVersion) {
          return;
        }
        this.exerciseModelPreference = this.persistedExerciseModelPreference;
        promptAction.showToast({ message: '保存失败，请重试', duration: 2000 });
      }
    });
    this.exerciseModelPreferenceSaveQueue = saveOperation;
    await saveOperation;
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
      promptAction.showToast({ message: '导入完成', duration: 2000 });
    } catch (err) {
      hilog.error(0xF170, 'MinePage', 'import failed');
      promptAction.showToast({ message: '导入失败，请选择本应用导出的 JSON 文件', duration: 2500 });
    }
  }

  build() {
    Scroll() {
      Column() {
      Text('我的')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 16 })

      Text('个人信息')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Column() {
        Text('身高 cm')
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 8 })
        TextInput({ text: this.heightText, placeholder: '例如 175' })
          .height(44)
          .backgroundColor($r('app.color.chip_bg'))
          .borderRadius(8)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.heightText = keepWeight(value);
          })
        if (this.heightError.length > 0) {
          Text(this.heightError)
            .fontSize(13)
            .fontColor($r('app.color.danger'))
            .width('100%')
            .margin({ top: 6 })
        }
        Button('保存身高')
          .backgroundColor($r('app.color.accent'))
          .fontColor($r('app.color.text_on_accent'))
          .width('100%')
          .height(40)
          .margin({ top: 12 })
          .onClick(() => {
            this.saveHeight();
          })

        Row() {
          Column() {
            Text('体重记录')
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            Text(this.latestWeightText)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('>')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ top: 16 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/BodyMetricsPage' }).catch(() => {
          });
        })
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(16)

      Text('外观')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 20, bottom: 8 })

      Row() {
        Text('浅色')
          .fontSize(15)
          .fontColor(this.theme === 'light' ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(40)
          .borderRadius(8)
          .backgroundColor(this.theme === 'light' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .onClick(() => {
            this.setTheme('light');
          })
        Text('暗色')
          .fontSize(15)
          .fontColor(this.theme === 'dark' ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(40)
          .margin({ left: 10 })
          .borderRadius(8)
          .backgroundColor(this.theme === 'dark' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .onClick(() => {
            this.setTheme('dark');
          })
      }
      .width('100%')

      Text('动作模特')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 20, bottom: 8 })

      Row() {
        Text('自动混合')
          .fontSize(15)
          .fontColor(this.exerciseModelPreference === 'auto' ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(40)
          .borderRadius(8)
          .backgroundColor(this.exerciseModelPreference === 'auto' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .onClick(() => {
            this.setExerciseModelPreference('auto');
          })
        Text('女性模特')
          .fontSize(15)
          .fontColor(this.exerciseModelPreference === 'female' ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(40)
          .margin({ left: 10 })
          .borderRadius(8)
          .backgroundColor(this.exerciseModelPreference === 'female' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .onClick(() => {
            this.setExerciseModelPreference('female');
          })
        Text('男性模特')
          .fontSize(15)
          .fontColor(this.exerciseModelPreference === 'male' ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(40)
          .margin({ left: 10 })
          .borderRadius(8)
          .backgroundColor(this.exerciseModelPreference === 'male' ? $r('app.color.accent') : $r('app.color.chip_bg'))
          .onClick(() => {
            this.setExerciseModelPreference('male');
          })
      }
      .width('100%')

      Text('数据')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ top: 20, bottom: 8 })

      Row() {
        Text('导出 JSON/CSV')
          .fontSize(15)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.handleExport();
          })
        Blank()
        Text('从 JSON 导入')
          .fontSize(15)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.handleImport();
          })
      }
      .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 28, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    .scrollBar(BarState.Off)
  }
}
