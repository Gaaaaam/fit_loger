import { router } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { displayChineseDate, todayString } from '../common/DateUtil';
import { filterExercises, isSelected, RecommendItem, recommendForMuscle } from '../common/MuscleLogic';
import { MuscleSceneView } from '../components/MuscleSceneView';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { ExerciseDef } from '../model/exerciseCatalog';
import { MuscleInfo, MUSCLE_REGIONS, muscleName } from '../model/muscleTypes';
import { EQUIPMENT_OPTIONS } from '../model/types';

interface MusclePickerParams {
  date: string;
}

@Entry
@Component
struct MusclePickerPage {
  @State date: string = '';
  @State isDark: boolean = false;
  @State tab: string = 'map';
  @State selectedKey: string = '';
  @State selectedIds: string[] = [];
  @State definitions: ExerciseDef[] = [];
  @State addedToday: string[] = [];
  @State items: RecommendItem[] = [];
  @State query: string = '';
  @State catalogueLoading: boolean = true;
  @State dayLoading: boolean = true;
  @State catalogueError: boolean = false;
  @State dayError: boolean = false;
  @State sceneState: string = 'loading';
  @State actionName: string = 'front';
  @State actionNonce: number = 0;
  @State dockOpen: boolean = true;
  @State showSheet: boolean = false;
  @State sheetMode: string = 'muscles';
  @State saving: boolean = false;
  @State saveError: string = '';
  private alive: boolean = false;
  private catalogueRequest: number = 0;
  private dayRequest: number = 0;

  aboutToAppear(): void {
    this.alive = true;
    const params: MusclePickerParams = router.getParams() as MusclePickerParams;
    this.date = params && params.date ? params.date : todayString();
    AppSettings.loadTheme().then((theme: string) => {
      if (this.alive) {
        this.isDark = theme === 'dark';
      }
    }).catch(() => {});
    this.loadCatalogue();
    this.loadDay();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.catalogueRequest++;
    this.dayRequest++;
  }

  onBackPress(): boolean {
    return this.saving;
  }

  private async loadCatalogue(): Promise<void> {
    const request: number = ++this.catalogueRequest;
    this.catalogueLoading = true;
    this.catalogueError = false;
    try {
      const result: ExerciseDef[] = await WorkoutRepository.listAllExercises();
      if (!this.alive || request !== this.catalogueRequest) {
        return;
      }
      this.definitions = result;
      this.updateItems();
    } catch (error) {
      if (this.alive && request === this.catalogueRequest) {
        this.catalogueError = true;
      }
    } finally {
      if (this.alive && request === this.catalogueRequest) {
        this.catalogueLoading = false;
      }
    }
  }

  private async loadDay(): Promise<void> {
    const request: number = ++this.dayRequest;
    this.dayLoading = true;
    this.dayError = false;
    try {
      const result: string[] = await WorkoutRepository.listDayExerciseIds(this.date);
      if (!this.alive || request !== this.dayRequest) {
        return;
      }
      this.addedToday = result;
      this.selectedIds = this.selectedIds.filter((id: string) => result.indexOf(id) < 0);
      this.updateItems();
    } catch (error) {
      if (this.alive && request === this.dayRequest) {
        this.dayError = true;
      }
    } finally {
      if (this.alive && request === this.dayRequest) {
        this.dayLoading = false;
      }
    }
  }

  private updateItems(): void {
    this.items = this.tab === 'all' ? filterExercises(this.definitions, this.query, this.addedToday) :
      recommendForMuscle(this.selectedKey, this.definitions, this.addedToday);
  }

  private pickMuscle(key: string): void {
    if (this.saving || !MUSCLE_REGIONS.some((muscle: MuscleInfo) => muscle.key === key)) {
      return;
    }
    this.selectedKey = key;
    this.dockOpen = true;
    this.updateItems();
  }

  private choose(id: string, checked: boolean): void {
    if (this.saving || this.dayLoading || this.dayError || this.addedToday.indexOf(id) >= 0) {
      return;
    }
    if (checked && !isSelected(this.selectedIds, id)) {
      this.selectedIds = this.selectedIds.concat([id]);
    } else if (!checked) {
      this.selectedIds = this.selectedIds.filter((selected: string) => selected !== id);
    }
    this.saveError = '';
  }

  private switchTab(tab: string): void {
    this.tab = tab;
    this.getUIContext().getFocusController().clearFocus();
    this.updateItems();
  }

  private sceneAction(action: string): void {
    if (action === 'retry') {
      this.sceneState = 'loading';
    }
    this.actionName = action;
    this.actionNonce++;
  }

  private openSheet(mode: string): void {
    this.sheetMode = mode;
    this.showSheet = true;
  }

  private equipmentName(key: string): string {
    for (let i: number = 0; i < EQUIPMENT_OPTIONS.length; i++) {
      if (EQUIPMENT_OPTIONS[i].key === key) {
        return EQUIPMENT_OPTIONS[i].name;
      }
    }
    return key;
  }

  private isPrimary(role: string): boolean {
    return role === 'primary' || role === '主要';
  }

  private hasRole(role: string): boolean {
    return this.isPrimary(role) || role === 'secondary' || role === '协同';
  }

  private selectionItems(): RecommendItem[] {
    const all: RecommendItem[] = filterExercises(this.definitions, '', this.addedToday);
    const selected: RecommendItem[] = [];
    for (let i: number = 0; i < this.selectedIds.length; i++) {
      for (let j: number = 0; j < all.length; j++) {
        if (all[j].id === this.selectedIds[i]) {
          selected.push(all[j]);
          break;
        }
      }
    }
    return selected;
  }

  private canSave(): boolean {
    return this.selectedIds.length > 0 && !this.saving && !this.catalogueLoading &&
      !this.dayLoading && !this.catalogueError && !this.dayError;
  }

  private async save(): Promise<void> {
    if (!this.canSave()) {
      return;
    }
    this.saving = true;
    this.saveError = '';
    try {
      await WorkoutRepository.addExercisesBatch(this.date, this.selectedIds.slice());
      if (this.alive) {
        router.back();
      }
    } catch (error) {
      if (this.alive) {
        this.saveError = '添加失败，已保留选择，请重试';
      }
    } finally {
      if (this.alive) {
        this.saving = false;
      }
    }
  }

  @Builder
  Header() {
    Row({ space: 12 }) {
      Button('‹', { type: ButtonType.Circle })
        .width(44).height(44).fontSize(30)
        .fontColor($r('app.color.text_primary')).backgroundColor($r('app.color.card_bg'))
        .accessibilityText('返回训练记录').enabled(!this.saving)
        .onClick(() => router.back())
      Column({ space: 3 }) {
        Text('添加动作').fontSize(25).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).maxFontScale(1.4)
        Text(displayChineseDate(this.date)).fontSize(12).fontColor($r('app.color.text_secondary'))
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('训练计划').fontSize(11).fontColor($r('app.color.accent'))
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor($r('app.color.accent_soft')).borderRadius(20)
    }.width('100%').padding({ left: 20, right: 20, top: 12, bottom: 14 })
  }

  @Builder
  Segments() {
    Row({ space: 4 }) {
      Button('肌肉地图', { type: ButtonType.Normal })
        .layoutWeight(1).height(42).borderRadius(12).fontSize(14)
        .fontWeight(this.tab === 'map' ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.tab === 'map' ? $r('app.color.accent') : $r('app.color.text_secondary'))
        .backgroundColor(this.tab === 'map' ? $r('app.color.card_bg') : Color.Transparent)
        .accessibilityText(this.tab === 'map' ? '肌肉地图，当前页面' : '肌肉地图')
        .onClick(() => this.switchTab('map'))
      Button('全部动作', { type: ButtonType.Normal })
        .layoutWeight(1).height(42).borderRadius(12).fontSize(14)
        .fontWeight(this.tab === 'all' ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.tab === 'all' ? $r('app.color.accent') : $r('app.color.text_secondary'))
        .backgroundColor(this.tab === 'all' ? $r('app.color.card_bg') : Color.Transparent)
        .accessibilityText(this.tab === 'all' ? '全部动作，当前页面' : '全部动作')
        .onClick(() => this.switchTab('all'))
    }.padding(4).margin({ left: 20, right: 20, bottom: 4 })
    .borderRadius(16).backgroundColor($r('app.color.chip_bg'))
  }

  @Builder
  SceneButton(label: string, action: string, accessibility: string) {
    Button(label, { type: ButtonType.Normal })
      .width(44).height(44).fontSize(12).borderRadius(14)
      .fontColor($r('app.color.text_secondary')).backgroundColor($r('app.color.card_bg'))
      .accessibilityText(accessibility).enabled(!this.saving)
      .onClick(() => this.sceneAction(action))
  }

  @Builder
  MuscleStage() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(this.selectedKey.length > 0 ? '当前目标' : '探索你的训练目标')
            .fontSize(11).fontColor($r('app.color.text_secondary'))
          Text(this.selectedKey.length > 0 ? muscleName(this.selectedKey) : '点击肌肉，发现动作')
            .fontSize(19).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            .maxFontScale(1.4)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Button('肌肉列表', { type: ButtonType.Normal })
          .height(44).fontSize(12).fontColor($r('app.color.accent'))
          .backgroundColor(Color.Transparent).onClick(() => this.openSheet('muscles'))
      }.width('100%').padding({ left: 22, right: 12, top: 12, bottom: 4 })

      Stack({ alignContent: Alignment.End }) {
        MuscleSceneView({
          selectedKey: this.selectedKey,
          actionName: this.actionName,
          actionNonce: this.actionNonce,
          isDark: this.isDark,
          onPicked: (key: string) => this.pickMuscle(key),
          onStatus: (ok: boolean) => {
            if (this.alive) {
              this.sceneState = ok ? 'ready' : 'error';
            }
          }
        }).width('100%').height('100%')
        Column({ space: 8 }) {
          this.SceneButton('正面', 'front', '转到人体正面')
          this.SceneButton('背面', 'back', '转到人体背面')
          this.SceneButton('↺', 'reset', '重置人体视角')
        }.margin({ right: 16 })
      }.width('100%').layoutWeight(1)

      if (this.sceneState === 'loading') {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16).color($r('app.color.accent'))
          Text('正在加载肌肉模型…').fontSize(12).fontColor($r('app.color.text_secondary'))
        }.height(30)
      } else if (this.sceneState === 'error') {
        Row({ space: 8 }) {
          Text('模型暂时无法显示').fontSize(12).fontColor($r('app.color.text_secondary'))
          Button('重试').height(40).fontSize(12).fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.accent_soft')).onClick(() => this.sceneAction('retry'))
          Button('使用列表').height(40).fontSize(12).fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.accent_soft')).onClick(() => this.openSheet('muscles'))
        }.padding({ bottom: 6 })
      } else {
        Text('拖动旋转 · 双指缩放 · 点击选择肌肉')
          .fontSize(11).fontColor($r('app.color.text_secondary')).padding({ top: 4, bottom: 10 })
      }
    }.width('100%').layoutWeight(1)
  }

  @Builder
  ItemRow(item: RecommendItem, review: boolean) {
    Row({ space: 12 }) {
      Column({ space: 7 }) {
        Text(item.name).fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary')).maxFontScale(1.5)
        Flex({ wrap: FlexWrap.Wrap }) {
          Text(this.equipmentName(item.equipment)).fontSize(11).fontColor($r('app.color.text_secondary'))
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .backgroundColor($r('app.color.chip_bg')).borderRadius(5).margin({ right: 6, bottom: 2 })
          if (this.hasRole(item.role)) {
            Text(this.isPrimary(item.role) ? '主练' : '辅助').fontSize(11)
              .fontColor(this.isPrimary(item.role) ? $r('app.color.accent') : $r('app.color.text_secondary'))
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(this.isPrimary(item.role) ? $r('app.color.accent_soft') : $r('app.color.chip_bg'))
              .borderRadius(5).margin({ bottom: 2 })
          }
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      .onClick(() => this.choose(item.id, !isSelected(this.selectedIds, item.id)))
      if (review) {
        Button('移除', { type: ButtonType.Normal }).height(44).fontSize(13)
          .fontColor($r('app.color.text_secondary')).backgroundColor(Color.Transparent)
          .accessibilityText('移除' + item.name).enabled(!this.saving)
          .onClick(() => this.choose(item.id, false))
      } else if (item.addedToday) {
        Text('今日已添加').fontSize(11).fontColor($r('app.color.text_secondary'))
      } else {
        Checkbox({ name: item.id }).select(isSelected(this.selectedIds, item.id))
          .selectedColor($r('app.color.accent')).width(23).height(23)
          .padding(10).enabled(!this.saving && !this.dayLoading && !this.dayError)
          .accessibilityText(item.name)
          .onChange((checked: boolean) => this.choose(item.id, checked))
      }
    }.width('100%').constraintSize({ minHeight: 76 }).padding({ top: 12, bottom: 12 })
  }

  @Builder
  ExerciseResults() {
    if (this.catalogueLoading || this.dayLoading) {
      Column({ space: 8 }) {
        LoadingProgress().width(26).height(26).color($r('app.color.accent'))
        Text(this.catalogueLoading ? '正在读取动作…' : '正在核对今日记录…')
          .fontSize(13).fontColor($r('app.color.text_secondary'))
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.catalogueError || this.dayError) {
      Column({ space: 8 }) {
        Text(this.catalogueError ? '动作未能加载' : '今日记录未能加载')
          .fontSize(14).fontColor($r('app.color.text_primary'))
        Button('重新加载').height(44).fontSize(13)
          .fontColor($r('app.color.accent')).backgroundColor($r('app.color.accent_soft'))
          .onClick(() => {
            if (this.catalogueError) {
              this.loadCatalogue();
            }
            if (this.dayError) {
              this.loadDay();
            }
          })
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.items.length === 0) {
      Column({ space: 7 }) {
        Text(this.tab === 'all' ? '没有找到匹配动作' : '该肌肉暂无匹配动作')
          .fontSize(15).fontColor($r('app.color.text_primary'))
        Text(this.tab === 'all' ? '试试动作名称或别名' : '可在全部动作中继续选择')
          .fontSize(12).fontColor($r('app.color.text_secondary'))
        if (this.tab === 'map') {
          Button('查看全部动作').height(40).fontSize(12)
            .fontColor($r('app.color.accent')).backgroundColor($r('app.color.accent_soft'))
            .onClick(() => this.switchTab('all'))
        }
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.items, (item: RecommendItem) => {
          ListItem() {
            this.ItemRow(item, false)
          }
        }, (item: RecommendItem) => item.id)
      }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
    }
  }

  @Builder
  RecommendationDock() {
    Column() {
      Row() {
        Column({ space: 3 }) {
          Text(muscleName(this.selectedKey) + ' · 动作').fontSize(16).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary')).maxFontScale(1.4)
          if (this.dockOpen) {
            Text('按主练与辅助关系推荐，可多选').fontSize(11).fontColor($r('app.color.text_secondary'))
          }
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Button(this.dockOpen ? '收起 ⌄' : '展开 ⌃', { type: ButtonType.Normal })
          .fontSize(12).height(44).fontColor($r('app.color.accent')).backgroundColor(Color.Transparent)
          .onClick(() => this.dockOpen = !this.dockOpen)
      }.width('100%').padding({ top: 8, bottom: 3 })
      if (this.dockOpen) {
        this.ExerciseResults()
      }
    }.width('100%').height(this.dockOpen ? '35%' : 62)
    .padding({ left: 20, right: 14 }).backgroundColor($r('app.color.card_bg'))
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  AllExercises() {
    Column({ space: 10 }) {
      TextInput({ placeholder: '搜索动作名称或别名', text: this.query })
        .height(46).fontSize(15).fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary')).backgroundColor($r('app.color.chip_bg'))
        .borderRadius(13).onChange((value: string) => {
          this.query = value;
          this.updateItems();
        })
      Row() {
        Text('动作库').fontSize(13).fontColor($r('app.color.text_secondary')).layoutWeight(1)
        Text('含自定义与有氧动作').fontSize(11).fontColor($r('app.color.text_secondary'))
      }.width('100%')
      this.ExerciseResults()
    }.width('100%').layoutWeight(1).padding({ left: 20, right: 20, top: 14 })
  }

  @Builder
  SheetContent() {
    Column() {
      Text(this.sheetMode === 'muscles' ? '选择目标肌肉' : '已选 ' + this.selectedIds.length.toString() + ' 个动作')
        .fontSize(21).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%').padding({ top: 12, bottom: 8 })
      Text(this.sheetMode === 'muscles' ? '选择后查看对应动作，已选动作会保留' : '可继续选择其他肌肉，也可移除动作')
        .fontSize(12).fontColor($r('app.color.text_secondary')).width('100%').margin({ bottom: 12 })
      if (this.sheetMode === 'muscles') {
        List() {
          ForEach(MUSCLE_REGIONS, (muscle: MuscleInfo) => {
            ListItem() {
              Row() {
                Text(muscle.name).fontSize(17).layoutWeight(1)
                  .fontColor(muscle.key === this.selectedKey ? $r('app.color.accent') : $r('app.color.text_primary'))
                Text(muscle.key === this.selectedKey ? '✓' : '›').fontSize(20).fontColor($r('app.color.accent'))
              }.width('100%').constraintSize({ minHeight: 56 }).padding({ top: 14, bottom: 14 })
              .accessibilityText(muscle.name + (muscle.key === this.selectedKey ? '，当前目标' : ''))
              .onClick(() => {
                this.tab = 'map';
                this.pickMuscle(muscle.key);
                this.showSheet = false;
              })
            }
          }, (muscle: MuscleInfo) => muscle.key)
        }.width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      } else if (this.selectedIds.length === 0) {
        Text('还没有选择动作').fontSize(15).fontColor($r('app.color.text_secondary'))
          .layoutWeight(1).width('100%').textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.selectionItems(), (item: RecommendItem) => {
            ListItem() {
              this.ItemRow(item, true)
            }
          }, (item: RecommendItem) => item.id)
        }.width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      }
      Button(this.sheetMode === 'muscles' ? '关闭' : '继续选择')
        .width('100%').height(48).fontSize(15).fontColor($r('app.color.accent'))
        .backgroundColor($r('app.color.accent_soft')).margin({ top: 10 })
        .onClick(() => this.showSheet = false)
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 20 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  Footer() {
    Column({ space: 6 }) {
      if (this.saveError.length > 0) {
        Text(this.saveError).fontSize(12).fontColor($r('app.color.danger')).width('100%')
      }
      Row({ space: 12 }) {
        Button('已选 ' + this.selectedIds.length.toString() + ' 个 ⌃', { type: ButtonType.Normal })
          .fontSize(14).fontColor($r('app.color.text_primary')).backgroundColor(Color.Transparent)
          .height(52).constraintSize({ minWidth: 100 }).borderRadius(14)
          .accessibilityText('查看已选的 ' + this.selectedIds.length.toString() + ' 个动作')
          .enabled(!this.saving).onClick(() => this.openSheet('review'))
        Button(this.saving ? '正在添加…' : this.saveError.length > 0 ? '重试添加' :
          '添加 ' + this.selectedIds.length.toString() + ' 个动作')
          .layoutWeight(1).height(52).fontSize(15).fontWeight(FontWeight.Medium).borderRadius(16)
          .fontColor($r('app.color.text_on_accent')).backgroundColor($r('app.color.accent'))
          .enabled(this.canSave()).opacity(this.canSave() || this.saving ? 1 : 0.4)
          .onClick(() => this.save())
      }.width('100%')
    }.width('100%').padding({ left: 16, right: 20, top: 10, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
  }

  build() {
    Column() {
      this.Header()
      this.Segments()
      if (this.tab === 'map') {
        Column() {
          this.MuscleStage()
          if (this.selectedKey.length > 0) {
            this.RecommendationDock()
          } else {
            Row({ space: 12 }) {
              Text('01').fontSize(20).fontColor($r('app.color.accent')).fontWeight(FontWeight.Medium)
              Column({ space: 4 }) {
                Text('从今天想练的肌肉开始').fontSize(15).fontColor($r('app.color.text_primary'))
                Text('选择肌肉后，适合的动作会出现在这里').fontSize(11).fontColor($r('app.color.text_secondary'))
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }.width('100%').padding({ left: 22, right: 22, top: 18, bottom: 18 })
            .backgroundColor($r('app.color.card_bg')).borderRadius({ topLeft: 24, topRight: 24 })
          }
        }.width('100%').layoutWeight(1)
      } else {
        this.AllExercises()
      }
      this.Footer()
    }.width('100%').height('100%').backgroundColor($r('app.color.page_bg'))
    .bindSheet($$this.showSheet, this.SheetContent, {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: $r('app.color.card_bg')
    })
  }
}
