import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { WorkoutDatabase } from '../db/WorkoutDatabase';

@Entry
@Component
struct StartupErrorPage {
  @State retrying: boolean = false;

  private async retry(): Promise<void> {
    if (this.retrying) {
      return;
    }
    this.retrying = true;
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    try {
      await WorkoutDatabase.init(ctx);
      await AppSettings.init(ctx);
      const theme: string = await AppSettings.loadTheme();
      AppSettings.applyTheme(ctx, theme);
      await router.replaceUrl({ url: 'pages/MainPage' });
    } catch (err) {
      const typed: BusinessError = err as BusinessError;
      hilog.error(0xF170, 'StartupErrorPage', 'retry failed: %{public}s', typed.message);
      promptAction.showToast({ message: '仍然无法打开，请稍后重试', duration: 2500 });
      this.retrying = false;
    }
  }

  build() {
    Column() {
      Text('数据未能打开')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 12 })
      Text('训练记录库没有准备好。可以重试，不会自动进入空白主页。')
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
      Button(this.retrying ? '正在重试…' : '重试')
        .width('100%')
        .height(44)
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .enabled(!this.retrying)
        .onClick(() => {
          this.retry();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 32, right: 32 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
