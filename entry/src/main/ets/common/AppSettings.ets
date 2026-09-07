import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'fit_loger_settings';
const KEY_THEME: string = 'theme';
const KEY_HEIGHT: string = 'height_cm';

export class AppSettings {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    const options: preferences.Options = { name: STORE_NAME };
    AppSettings.store = await preferences.getPreferences(context, options);
  }

  private static prefs(): preferences.Preferences {
    return AppSettings.store as preferences.Preferences;
  }

  static async loadTheme(): Promise<string> {
    if (AppSettings.store === null) {
      return 'light';
    }
    const value: preferences.ValueType = await AppSettings.prefs().get(KEY_THEME, 'light');
    if (value === 'dark') {
      return 'dark';
    }
    return 'light';
  }

  static async saveTheme(theme: string): Promise<void> {
    if (AppSettings.store === null) {
      return;
    }
    await AppSettings.prefs().put(KEY_THEME, theme);
    await AppSettings.prefs().flush();
  }

  static applyTheme(context: common.Context, theme: string): void {
    const appCtx: common.ApplicationContext = context.getApplicationContext();
    if (theme === 'dark') {
      appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } else {
      appCtx.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    }
  }

  static async loadHeightCm(): Promise<number> {
    if (AppSettings.store === null) {
      return 0;
    }
    const value: preferences.ValueType = await AppSettings.prefs().get(KEY_HEIGHT, 0);
    if (typeof value === 'number' && value > 0) {
      return value;
    }
    return 0;
  }

  static async saveHeightCm(heightCm: number): Promise<void> {
    if (AppSettings.store === null) {
      return;
    }
    await AppSettings.prefs().put(KEY_HEIGHT, heightCm);
    await AppSettings.prefs().flush();
  }
}
