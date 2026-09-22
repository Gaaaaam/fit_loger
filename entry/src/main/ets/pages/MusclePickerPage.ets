import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction, router } from '@kit.ArkUI';
import { AppSettings } from '../common/AppSettings';
import { todayString } from '../common/DateUtil';
import { filterExercises, isSelected, RecommendItem, recommendForMuscle, toggleSelected } from '../common/MuscleLogic';
import { MuscleSceneView } from '../components/MuscleSceneView';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { ExerciseDef } from '../model/exerciseCatalog';
import { MuscleInfo, MuscleKey, muscleName, MUSCLE_REGIONS, toMuscleKey } from '../model/muscleTypes';
import { equipmentName } from '../model/types';

interface PickerDateParams { date: string; }

@Entry
@Component
struct MusclePickerPage {
  @State dateStr: string = '';
  @State searchText: string = '';
  @State selectedKey: string = '';
  @State selectedIds: string[] = [];
  @State allExercises: ExerciseDef[] = [];
  @State addedIds: string[] = [];
  @State panelOpen: boolean = false;
  @State showAll: boolean = false;
  @State modelFailed: boolean = false;
  @State isDark: boolean = false;
  @State themeReady: boolean = false;
  @State submitting: boolean = false;
  @State catalogLoading: boolean = true;
  @State actionNonce: number = 0;
  @State actionName: string = '';
  @State loadError: string = '';
  @State listItems: RecommendItem[] = [];
  @State sheetOpen: boolean = false;
  @State sheetKind: string = 'muscles';
  @State pageHeight: number = 760;
  private alive: boolean = false;
  private catalogRequest: number = 0;

  aboutToAppear(): void {
    this.alive = true;
    const raw: Object | undefined = router.getParams();
    if (raw !== undefined) {
      const params: PickerDateParams = raw as PickerDateParams;
      if (params.date !== undefined && params.date.length > 0) {
        this.dateStr = params.date;
      }
    }
    if (this.dateStr.length === 0) {
      this.dateStr = todayString();
    }
    this.bootstrap();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.catalogRequest++;
  }

  onBackPress(): boolean {
    return this.submitting;
  }

  private async bootstrap(): Promise<void> {
    try {
      const theme: string = await AppSettings.loadTheme();
      if (!this.alive) { return; }
      this.isDark = theme === 'dark';
    } catch (err) {
      hilog.warn(0xF170, 'MusclePickerPage', 'theme unavailable, using default');
    }
    if (!this.alive) { return; }
    this.themeReady = true;
    await this.reloadCatalog();
  }

  private async reloadCatalog(): Promise<void> {
    const request: number = ++this.catalogRequest;
    this.catalogLoading = true;
    this.loadError = '';
    try {
      const exercises: ExerciseDef[] = await WorkoutRepository.listExercisesAll();
      const added: string[] = await WorkoutRepository.listAddedExerciseIds(this.dateStr);
      if (!this.alive || request !== this.catalogRequest) { return; }
      this.allExercises = exercises;
      this.addedIds = added;
      this.selectedIds = this.selectedIds.filter((id: string) => !isSelected(added, id));
      this.refreshList();
    } catch (err) {
      if (this.alive && request === this.catalogRequest) {
        hilog.error(0xF170, 'MusclePickerPage', 'catalog load failed');
        this.loadError = '暂时无法加载动作';
      }
    } finally {
      if (this.alive && request === this.catalogRequest) { this.catalogLoading = false; }
    }
  }

  private refreshList(): void {
    if (this.showAll) {
      this.listItems = filterExercises(this.allExercises, this.searchText, this.addedIds);
      return;
    }
    const muscle: MuscleKey | null = toMuscleKey(this.selectedKey);
    this.listItems = muscle === null ? [] : recommendForMuscle(muscle, this.allExercises, this.addedIds);
  }

  private nameOf(id: string): string {
    for (let i = 0; i < this.allExercises.length; i++) {
      if (this.allExercises[i].id === id) { return this.allExercises[i].name; }
    }
    return id;
  }

  private equipmentOf(id: string): string {
    for (let i = 0; i < this.allExercises.length; i++) {
      if (this.allExercises[i].id === id) { return equipmentName(this.allExercises[i].equipment); }
    }
    return '';
  }

  private switchTab(all: boolean): void {
    this.showAll = all;
    this.refreshList();
  }

  private handlePickMuscle(key: string): void {
    if (this.submitting || toMuscleKey(key) === null) { return; }
    this.selectedKey = key;
    this.showAll = false;
    this.panelOpen = true;
    this.sheetOpen = false;
    this.refreshList();
  }

  private handleMissedPick(): void {
    if (this.submitting) { return; }
    promptAction.showToast({ message: '没有点到肌群，试试靠近一些，或用肌群列表', duration: 2000 });
  }

  private handleToggle(item: RecommendItem): void {
    if (!this.submitting) {
      this.selectedIds = toggleSelected(this.selectedIds, item.id, item.addedToday);
    }
  }

  private removeSelected(id: string): void {
    if (!this.submitting) {
      this.selectedIds = this.selectedIds.filter((selected: string) => selected !== id);
    }
  }

  private openSheet(kind: string): void {
    this.sheetKind = kind;
    this.sheetOpen = true;
  }

  private runSceneAction(name: string): void {
    this.actionName = name;
    this.actionNonce++;
  }

  private retryModel(): void {
    this.modelFailed = false;
    this.runSceneAction('retry');
  }

  private async confirmAdd(): Promise<void> {
    if (this.submitting || this.catalogLoading || this.loadError.length > 0 || this.selectedIds.length === 0) { return; }
    this.submitting = true;
    try {
      await WorkoutRepository.addExercisesBatch(this.dateStr, this.selectedIds.slice());
      if (this.alive) { router.back(); }
    } catch (err) {
      if (this.alive) {
        this.submitting = false;
        promptAction.showToast({ message: '添加失败，选择已保留，请重试', duration: 2000 });
      }
    }
  }

  private dockHeight(): number { return Math.min(300, Math.max(170, this.pageHeight * 0.35)); }

  @Builder
  Header() {
    Row({ space: 12 }) {
      Button('‹', { type: ButtonType.Circle })
        .width(42).height(42).fontSize(30).fontColor($r('app.color.scene_ink'))
        .backgroundColor($r('app.color.scene_header_btn'))
        .accessibilityText('返回训练记录').enabled(!this.submitting)
        .onClick(() => router.back())
      Column({ space: 3 }) {
        Text('添加动作').fontSize($r('app.float.font_hero')).fontWeight(FontWeight.Bold).fontColor($r('app.color.scene_ink'))
        Text(`${this.dateStr.replace(/-/g, '.')}  ·  为这一天选择训练`)
          .fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted'))
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ left: 20, right: 20, top: 14, bottom: 16 })
  }

  @Builder
  ModeTabs() {
    Row({ space: 4 }) {
      Button('肌肉地图', { type: ButtonType.Normal })
        .layoutWeight(1).height(38).fontSize($r('app.float.font_body'))
        .fontWeight(!this.showAll ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(!this.showAll ? $r('app.color.scene_ink') : $r('app.color.scene_muted'))
        .backgroundColor(!this.showAll ? $r('app.color.scene_tab_active') : Color.Transparent)
        .borderRadius($r('app.float.radius_md')).onClick(() => this.switchTab(false))
      Button('全部动作', { type: ButtonType.Normal })
        .layoutWeight(1).height(38).fontSize($r('app.float.font_body'))
        .fontWeight(this.showAll ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.showAll ? $r('app.color.scene_ink') : $r('app.color.scene_muted'))
        .backgroundColor(this.showAll ? $r('app.color.scene_tab_active') : Color.Transparent)
        .borderRadius($r('app.float.radius_md')).onClick(() => this.switchTab(true))
    }
    .padding(4).margin({ left: 20, right: 20, bottom: 8 })
    .backgroundColor($r('app.color.scene_tab_track')).borderRadius($r('app.float.radius_lg'))
  }

  @Builder
  SceneControl(label: string, action: string) {
    Button(label, { type: ButtonType.Normal })
      .height(38).fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_ink')).backgroundColor(Color.Transparent)
      .padding({ left: 16, right: 16 }).borderRadius(18)
      .onClick(() => this.runSceneAction(action))
  }

  @Builder
  ModelFailure() {
    Column({ space: 12 }) {
      Text('人体模型暂未加载').fontSize($r('app.float.font_title')).fontWeight(FontWeight.Medium).fontColor($r('app.color.scene_ink'))
      Text('也可以从肌群列表选择目标，继续添加动作')
        .fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted')).textAlign(TextAlign.Center)
      Row({ space: 12 }) {
        Button('重试模型').fontSize($r('app.float.font_body')).height(40).fontColor($r('app.color.accent'))
          .backgroundColor($r('app.color.scene_soft')).onClick(() => this.retryModel())
        Button('选择肌群').fontSize($r('app.float.font_body')).height(40).fontColor($r('app.color.text_on_accent'))
          .backgroundColor($r('app.color.accent')).onClick(() => this.openSheet('muscles'))
      }
    }.padding(24).width('100%')
  }

  @Builder
  ModelStage() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.modelFailed) {
        this.ModelFailure()
      } else if (this.themeReady) {
        MuscleSceneView({
          selectedKey: this.selectedKey,
          actionNonce: this.actionNonce,
          actionName: this.actionName,
          isDark: this.isDark,
          onPicked: (key: string) => this.handlePickMuscle(key),
          onMissed: () => this.handleMissedPick(),
          onStatus: (ok: boolean) => { this.modelFailed = !ok; }
        })
      } else {
        LoadingProgress().width(30).height(30).color($r('app.color.accent'))
      }
      Row({ space: 8 }) {
        if (this.selectedKey.length > 0) {
          Row({ space: 6 }) {
            Circle().width(6).height(6).fill($r('app.color.accent'))
            Text(muscleName(this.selectedKey)).fontSize($r('app.float.font_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.scene_ink'))
          }
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor($r('app.color.scene_overlay')).borderRadius(18)
        }
        Blank()
        Button('肌群列表  ≡').height(36).fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_ink'))
          .backgroundColor($r('app.color.scene_overlay')).onClick(() => this.openSheet('muscles'))
      }
      .width('100%').padding({ left: 20, right: 20, top: 10 })
      if (!this.modelFailed) {
        Column({ space: 8 }) {
          Row() {
            this.SceneControl('正面', 'front')
            Divider().vertical(true).height(14).color($r('app.color.scene_divider'))
            this.SceneControl('背面', 'back')
            Divider().vertical(true).height(14).color($r('app.color.scene_divider'))
            this.SceneControl('复位', 'reset')
          }.backgroundColor($r('app.color.scene_control_bar')).borderRadius($r('app.float.radius_xl'))
          Text('拖动旋转  ·  双指缩放  ·  轻点肌肉').fontSize(10).fontColor($r('app.color.scene_muted'))
        }.width('100%').height('100%').justifyContent(FlexAlign.End)
          .padding({ bottom: 12 }).hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%').layoutWeight(1).clip(true).backgroundColor($r('app.color.scene_bg'))
  }

  @Builder
  SelectionMark(item: RecommendItem) {
    Stack() {
      if (item.addedToday || isSelected(this.selectedIds, item.id)) {
        Text('✓').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(item.addedToday ? $r('app.color.scene_muted') : $r('app.color.text_on_accent'))
      }
    }
    .width(24).height(24).borderRadius($r('app.float.radius_sm'))
    .backgroundColor(isSelected(this.selectedIds, item.id) && !item.addedToday ? $r('app.color.accent') : Color.Transparent)
    .border({ width: 1.3, color: isSelected(this.selectedIds, item.id) && !item.addedToday ? $r('app.color.accent') :
      $r('app.color.scene_mark_border') })
  }

  @Builder
  RecommendRow(item: RecommendItem) {
    Row({ space: 12 }) {
      Column({ space: 6 }) {
        Text(item.name).fontSize($r('app.float.font_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.scene_ink'))
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(this.equipmentOf(item.id)).fontSize(11).fontColor($r('app.color.scene_muted'))
          if (item.role.length > 0) {
            Text(item.role === 'secondary' ? '辅助参与' : '主练肌群').fontSize(10)
              .fontColor(item.role === 'secondary' ? $r('app.color.scene_muted') : $r('app.color.accent'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(item.role === 'secondary' ? Color.Transparent : $r('app.color.scene_role'))
              .borderRadius(4)
          }
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (item.addedToday) {
        Text('今日已添加').fontSize(11).fontColor($r('app.color.scene_muted'))
      }
      this.SelectionMark(item)
    }
    .width('100%').padding({ left: 14, right: 14, top: 13, bottom: 13 })
    .backgroundColor(isSelected(this.selectedIds, item.id) && !item.addedToday ?
      $r('app.color.scene_row_selected') : $r('app.color.scene_row'))
    .borderRadius($r('app.float.radius_lg'))
    .border({ width: 1, color: isSelected(this.selectedIds, item.id) && !item.addedToday ?
      $r('app.color.scene_row_border_selected') : $r('app.color.scene_row_border') })
    .opacity(item.addedToday ? 0.6 : 1).accessibilityGroup(true)
    .accessibilityText(`${item.name}，${item.addedToday ? '今日已添加' :
      (isSelected(this.selectedIds, item.id) ? '已选择，点击取消' : '点击选择')}`)
    .onClick(() => this.handleToggle(item))
  }

  @Builder
  ListContent() {
    if (this.catalogLoading) {
      Column({ space: 10 }) {
        LoadingProgress().width(26).height(26).color($r('app.color.accent'))
        Text('正在加载动作…').fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_muted'))
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.loadError.length > 0) {
      Column({ space: 10 }) {
        Text(this.loadError).fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_ink'))
        Button('重新加载').height(36).fontSize($r('app.float.font_caption')).fontColor($r('app.color.accent'))
          .backgroundColor($r('app.color.scene_soft')).onClick(() => this.reloadCatalog())
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.listItems.length === 0) {
      Column({ space: 8 }) {
        Text(this.showAll ? '没有找到相关动作' : '这个肌群暂时没有预设动作').fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_ink'))
        Text(this.showAll ? '试试其他名称或别名' : '可在全部动作中继续选择').fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted'))
        if (!this.showAll) {
          Button('浏览全部动作').height(34).fontSize($r('app.float.font_caption')).fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.scene_soft')).onClick(() => this.switchTab(true))
        }
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else {
      List({ space: 8 }) {
        ForEach(this.listItems, (item: RecommendItem) => {
          ListItem() { this.RecommendRow(item) }
        }, (item: RecommendItem) => `${item.id}#${item.role}`)
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  RecommendationDock() {
    Column() {
      Row({ space: 8 }) {
        Column({ space: 4 }) {
          Text(this.selectedKey.length > 0 ? `${muscleName(this.selectedKey)} · 推荐动作` : '今天，想练哪里？')
            .fontSize($r('app.float.font_title')).fontWeight(FontWeight.Bold).fontColor($r('app.color.scene_ink'))
          Text(this.selectedKey.length > 0 ? `${this.listItems.length} 个动作  ·  可跨肌群多选` :
            '轻点人体上的肌肉，发现适合的动作').fontSize(11).fontColor($r('app.color.scene_muted'))
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (this.selectedKey.length > 0) {
          Button(this.panelOpen ? '收起 ⌄' : '展开 ⌃').height(36).fontSize($r('app.float.font_caption')).fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.scene_soft'))
            .onClick(() => { this.panelOpen = !this.panelOpen; })
        }
      }.width('100%').padding({ top: 16, bottom: 14 })
      if (this.panelOpen && this.selectedKey.length > 0) { this.ListContent() }
    }
    .width('100%').height(this.panelOpen && this.selectedKey.length > 0 ? this.dockHeight() : 78)
    .padding({ left: 20, right: 20, bottom: this.panelOpen ? 10 : 0 })
    .backgroundColor($r('app.color.scene_panel')).borderRadius({ topLeft: 26, topRight: 26 })
  }

  @Builder
  Library() {
    Column({ space: 14 }) {
      TextInput({ text: this.searchText, placeholder: '搜索动作名称或别名' })
        .height(48).fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_ink')).placeholderColor($r('app.color.scene_muted'))
        .backgroundColor($r('app.color.scene_search')).borderRadius($r('app.float.radius_lg')).padding({ left: 16, right: 16 })
        .onChange((value: string) => { this.searchText = value; this.refreshList(); })
      Row() {
        Text(this.searchText.trim().length > 0 ? '搜索结果' : '动作库')
          .fontSize($r('app.float.font_title')).fontWeight(FontWeight.Bold).fontColor($r('app.color.scene_ink'))
        Blank()
        Text(`${this.listItems.length} 个动作`).fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted'))
      }.width('100%')
      this.ListContent()
    }.width('100%').layoutWeight(1).padding({ left: 20, right: 20, top: 10, bottom: 12 })
  }

  @Builder
  Footer() {
    Row({ space: 14 }) {
      Column({ space: 5 }) {
        Row({ space: 4 }) {
          Text(`${this.selectedIds.length}`).fontSize($r('app.float.font_hero')).fontWeight(FontWeight.Bold).fontColor($r('app.color.scene_ink'))
          Text('个已选').fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted'))
        }
        Text(this.selectedIds.length > 0 ? '查看清单 ›' : '支持多选')
          .fontSize(11).fontColor(this.selectedIds.length > 0 ? $r('app.color.accent') : $r('app.color.scene_muted'))
      }
      .alignItems(HorizontalAlign.Start).width(92).accessibilityGroup(true)
      .accessibilityText(`已选择 ${this.selectedIds.length} 个动作，查看选择清单`)
      .onClick(() => { if (this.selectedIds.length > 0) { this.openSheet('selected'); } })
      Button(this.submitting ? '正在添加…' :
        (this.selectedIds.length > 0 ? `添加 ${this.selectedIds.length} 个动作` : '选择动作后添加'),
        { type: ButtonType.Normal })
        .layoutWeight(1).height(52).fontSize($r('app.float.font_body')).fontWeight(FontWeight.Medium)
        .fontColor(this.selectedIds.length > 0 ? $r('app.color.text_on_accent') : $r('app.color.scene_muted'))
        .backgroundColor(this.selectedIds.length > 0 ? $r('app.color.accent') : $r('app.color.scene_disabled'))
        .borderRadius(17)
        .enabled(this.selectedIds.length > 0 && !this.submitting && !this.catalogLoading && this.loadError.length === 0)
        .onClick(() => this.confirmAdd())
    }
    .width('100%').padding({ left: 22, right: 20, top: 13, bottom: 18 })
    .backgroundColor($r('app.color.scene_panel'))
    .border({ width: { top: 1 }, color: $r('app.color.scene_stroke') })
  }

  @Builder
  MuscleGroup(title: string, muscles: MuscleInfo[]) {
    Column({ space: 12 }) {
      Text(title).fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted')).width('100%')
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(muscles, (info: MuscleInfo) => {
          Row() {
            Text(info.name).fontSize($r('app.float.font_body')).fontColor(this.selectedKey === info.key ? $r('app.color.accent') : $r('app.color.scene_ink'))
            Blank()
            if (this.selectedKey === info.key) { Text('✓').fontSize(13).fontColor($r('app.color.accent')) }
          }
          .width('48%').height(48).padding({ left: 14, right: 12 }).margin({ bottom: 8 }).borderRadius(12)
          .backgroundColor(this.selectedKey === info.key ? $r('app.color.scene_fill_selected') :
            $r('app.color.scene_fill')).onClick(() => this.handlePickMuscle(info.key))
        }, (info: MuscleInfo) => info.key)
      }
    }.width('100%').margin({ bottom: 14 })
  }

  @Builder
  PickerSheet() {
    Column() {
      Row() {
        Column({ space: 5 }) {
          Text(this.sheetKind === 'muscles' ? '选择目标肌群' : `已选动作 · ${this.selectedIds.length}`)
            .fontSize($r('app.float.font_hero')).fontWeight(FontWeight.Bold).fontColor($r('app.color.scene_ink'))
          Text(this.sheetKind === 'muscles' ? '选择后，查看对应的推荐动作' : '确认添加前，可随时调整这份清单')
            .fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted'))
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button('×', { type: ButtonType.Circle }).width(36).height(36).fontSize(23).fontColor($r('app.color.scene_muted'))
          .backgroundColor($r('app.color.scene_soft')).accessibilityText('关闭清单')
          .onClick(() => { this.sheetOpen = false; })
      }.width('100%').padding({ top: 12, bottom: 24 })
      if (this.sheetKind === 'muscles') {
        Scroll() {
          Column() {
            this.MuscleGroup('胸 · 肩 · 背', MUSCLE_REGIONS.slice(0, 8))
            this.MuscleGroup('手臂', MUSCLE_REGIONS.slice(8, 11))
            this.MuscleGroup('核心', MUSCLE_REGIONS.slice(11, 13))
            this.MuscleGroup('臀 · 腿', MUSCLE_REGIONS.slice(13, 18))
          }.width('100%')
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      } else if (this.selectedIds.length === 0) {
        Column({ space: 10 }) {
          Text('清单已清空').fontSize($r('app.float.font_title')).fontColor($r('app.color.scene_ink'))
          Text('返回肌肉地图或动作库，继续挑选').fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_muted'))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.selectedIds, (id: string, index: number) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(`${index + 1}`).fontSize(13).fontColor($r('app.color.accent')).width(24)
                Column({ space: 4 }) {
                  Text(this.nameOf(id)).fontSize($r('app.float.font_body')).fontColor($r('app.color.scene_ink'))
                  Text(this.equipmentOf(id)).fontSize(11).fontColor($r('app.color.scene_muted'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Button('移除').height(36).fontSize($r('app.float.font_caption')).fontColor($r('app.color.scene_muted')).backgroundColor(Color.Transparent)
                  .accessibilityText(`移除${this.nameOf(id)}`).enabled(!this.submitting).onClick(() => this.removeSelected(id))
              }.width('100%').padding(14).backgroundColor($r('app.color.scene_fill')).borderRadius(15)
            }
          }, (id: string) => id)
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
      Button(this.sheetKind === 'muscles' ? '返回人体模型' : '继续选择', { type: ButtonType.Normal })
        .width('100%').height(48).fontSize($r('app.float.font_body')).fontColor($r('app.color.accent'))
        .backgroundColor($r('app.color.scene_soft')).borderRadius(15).margin({ top: 16, bottom: 18 })
        .onClick(() => { this.sheetOpen = false; })
    }.width('100%').height('100%').padding({ left: 22, right: 22 })
    .backgroundColor($r('app.color.scene_panel'))
  }

  build() {
    Column() {
      this.Header()
      this.ModeTabs()
      if (this.showAll) {
        this.Library()
      } else {
        this.ModelStage()
        this.RecommendationDock()
      }
      this.Footer()
    }
    .width('100%').height('100%').backgroundColor($r('app.color.scene_bg'))
    .onAreaChange((_oldArea: Area, area: Area) => { this.pageHeight = area.height as number; })
    .bindSheet($$this.sheetOpen, this.PickerSheet, {
      height: '74%', dragBar: true, showClose: false,
      backgroundColor: $r('app.color.scene_panel')
    })
  }
}
