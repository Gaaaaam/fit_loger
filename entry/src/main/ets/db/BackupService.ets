import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { relationalStore } from '@kit.ArkData';
import { formatBackupName, retainBackupNames, BackupRetainResult } from '../common/WorkoutLogic';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xF170;
const TAG: string = 'BackupService';

export class BackupService {
  static async backupBeforeMigrate(store: relationalStore.RdbStore, context: common.UIAbilityContext): Promise<void> {
    const name: string = formatBackupName(new Date());
    await store.backup(name);
    hilog.info(DOMAIN, TAG, 'backup written %{public}s', name);
    await BackupService.prune(context);
  }

  static async prune(context: common.UIAbilityContext): Promise<void> {
    const dir: string = context.databaseDir;
    let names: string[] = [];
    try {
      names = await fileIo.listFile(dir);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'list backups failed');
      return;
    }
    const result: BackupRetainResult = retainBackupNames(names);
    for (let i = 0; i < result.remove.length; i++) {
      try {
        fileIo.unlinkSync(`${dir}/${result.remove[i]}`);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'delete old backup failed %{public}s', result.remove[i]);
      }
    }
  }
}
