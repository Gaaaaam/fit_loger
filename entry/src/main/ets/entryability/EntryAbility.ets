import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { WorkoutDatabase } from '../db/WorkoutDatabase';

const DOMAIN: number = 0xF170;
const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    WorkoutDatabase.init(this.context).then(() => {
      return AppSettings.init(this.context);
    }).then(async () => {
      const theme: string = await AppSettings.loadTheme();
      AppSettings.applyTheme(this.context, theme);
      this.loadMain(windowStage);
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Startup init failed: %{public}s', err.message);
      this.loadMain(windowStage);
    });
  }

  private loadMain(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Content loaded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
