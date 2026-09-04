import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { BodyPartSheet } from '../components/BodyPartSheet';
import { ExerciseSheet } from '../components/ExerciseSheet';
import { PartSection } from '../components/PartSection';
import { displayChineseDate, todayString } from '../common/DateUtil';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { DayModel, PartItem } from '../model/DayModels';
import { PartKey } from '../model/types';

interface RouterDateParams {
  date: string;
}

@Entry
@Component
struct DayDetailPage {
  @State dateStr: string = '';
  @State titleText: string = '';
  @State day: DayModel = new DayModel();
  @State viewEpoch: number = 0;
  @State showSheet: boolean = false;
  @State sheetMode: string = 'part';
  @State pickerPartId: number = 0;
  @State pickerPartKey: PartKey = 'chest';
  @State usedKeys: string[] = [];

  aboutToAppear(): void {
    const raw: Object | undefined = router.getParams();
    if (raw !== undefined) {
      const params: RouterDateParams = raw as RouterDateParams;
      if (params.date !== undefined && params.date.length > 0) {
        this.dateStr = params.date;
      }
    }
    if (this.dateStr.length === 0) {
      this.dateStr = todayString();
    }
    this.titleText = displayChineseDate(this.dateStr);
    this.reload(true);
  }

  private usedPartKeys(): string[] {
    const keys: string[] = [];
    for (let i = 0; i < this.day.parts.length; i++) {
      keys.push(this.day.parts[i].partKey);
    }
    return keys;
  }

  private async reload(autoOpenPart: boolean): Promise<void> {
    try {
      this.day = await WorkoutRepository.loadDay(this.dateStr);
      this.usedKeys = this.usedPartKeys();
      this.viewEpoch++;
      if (autoOpenPart && this.day.parts.length === 0) {
        this.sheetMode = 'part';
        this.showSheet = true;
      }
    } catch (err) {
      hilog.error(0xF170, 'DayDetailPage', 'reload failed');
      this.day = new DayModel();
      this.day.date = this.dateStr;
      this.usedKeys = [];
      this.viewEpoch++;
    }
  }

  private async handlePickPart(key: PartKey): Promise<void> {
    this.showSheet = false;
    await WorkoutRepository.addPart(this.dateStr, key);
    await this.reload(false);
  }

  private async handlePickExercise(exerciseId: string): Promise<void> {
    this.showSheet = false;
    if (this.pickerPartId <= 0) {
      return;
    }
    await WorkoutRepository.addExercise(this.pickerPartId, exerciseId);
    await this.reload(false);
  }

  private openExercisePicker(partId: number): void {
    for (let i = 0; i < this.day.parts.length; i++) {
      if (this.day.parts[i].id === partId) {
        this.pickerPartKey = this.day.parts[i].partKey;
        break;
      }
    }
    this.pickerPartId = partId;
    this.sheetMode = 'exercise';
    this.showSheet = true;
  }

  private async handleAddSet(exerciseRowId: number): Promise<void> {
    await WorkoutRepository.addSet(exerciseRowId);
    await this.reload(false);
  }

  private async handleDeleteSet(setId: number): Promise<void> {
    await WorkoutRepository.deleteSet(setId);
    await this.reload(false);
  }

  private async handleDeleteExercise(exerciseRowId: number): Promise<void> {
    await WorkoutRepository.deleteExercise(exerciseRowId);
    await this.reload(false);
  }

  private async handleDeletePart(partId: number): Promise<void> {
    await WorkoutRepository.deletePart(partId);
    await this.reload(false);
  }

  private confirmDeleteDay(): void {
    AlertDialog.show({
      title: '删除当天',
      message: '将删除这一天的全部训练记录。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: () => {
          this.handleDeleteDay();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  private async handleDeleteDay(): Promise<void> {
    await WorkoutRepository.deleteDay(this.dateStr);
    router.back();
  }

  @Builder
  SheetBuilder() {
    Column() {
      if (this.sheetMode === 'exercise') {
        ExerciseSheet({
          partKey: this.pickerPartKey,
          onPick: (exerciseId: string) => {
            this.handlePickExercise(exerciseId);
          }
        })
      } else {
        BodyPartSheet({
          usedKeys: this.usedKeys,
          onPick: (key: PartKey) => {
            this.handlePickPart(key);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      Row() {
        Text('< 日历')
          .fontSize(16)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            router.back();
          })
        Blank()
        if (this.day.parts.length > 0) {
          Text('删除当天')
            .fontSize(16)
            .fontColor($r('app.color.danger'))
            .onClick(() => {
              this.confirmDeleteDay();
            })
        }
      }
      .width('100%')
      .padding({ bottom: 8 })

      Text(this.titleText)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ bottom: 16 })

      if (this.day.parts.length === 0) {
        Column() {
          Text('这一天还没有训练记录')
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 16 })
          Button('选择训练部位')
            .backgroundColor($r('app.color.accent'))
            .fontColor($r('app.color.text_on_accent'))
            .onClick(() => {
              this.sheetMode = 'part';
              this.showSheet = true;
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.day.parts, (part: PartItem) => {
              PartSection({
                part: part,
                onAddExercise: (partId: number) => {
                  this.openExercisePicker(partId);
                },
                onDeletePart: (partId: number) => {
                  this.handleDeletePart(partId);
                },
                onAddSet: (exerciseRowId: number) => {
                  this.handleAddSet(exerciseRowId);
                },
                onDeleteExercise: (exerciseRowId: number) => {
                  this.handleDeleteExercise(exerciseRowId);
                },
                onDeleteSet: (setId: number) => {
                  this.handleDeleteSet(setId);
                }
              })
            }, (part: PartItem) => `${part.id}#${this.viewEpoch}`)

            if (this.usedKeys.length < 6) {
              Button('添加部位')
                .fontSize(15)
                .fontColor($r('app.color.accent'))
                .backgroundColor($r('app.color.accent_soft'))
                .width('100%')
                .height(44)
                .margin({ bottom: 24 })
                .onClick(() => {
                  this.sheetMode = 'part';
                  this.showSheet = true;
                })
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 12 })
    .backgroundColor($r('app.color.page_bg'))
    .bindSheet($$this.showSheet, this.SheetBuilder, {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true
    })
  }
}
