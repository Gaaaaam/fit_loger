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

  private stageColor(): string { return this.isDark ? '#172522' : '#EDF3F0'; }
  private inkColor(): string { return this.isDark ? '#E9F3EE' : '#213D34'; }
  private accentColor(): string { return this.isDark ? '#7DD7B6' : '#21795E'; }
  private mutedColor(): string { return this.isDark ? '#A8BDB4' : '#71867C'; }
  private dockHeight(): number { return Math.min(300, Math.max(170, this.pageHeight * 0.35)); }

  @Builder
  Header() {
    Row({ space: 12 }) {
      Button('‹', { type: ButtonType.Circle })
        .width(42).height(42).fontSize(30).fontColor(this.inkColor())
        .backgroundColor(this.isDark ? '#263730' : '#FFFFFF')
        .accessibilityText('返回训练记录').enabled(!this.submitting)
        .onClick(() => router.back())
      Column({ space: 3 }) {
        Text('添加动作').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
        Text(`${this.dateStr.replace(/-/g, '.')}  ·  为这一天选择训练`)
          .fontSize(11).fontColor(this.mutedColor())
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ left: 20, right: 20, top: 14, bottom: 16 })
  }

  @Builder
  ModeTabs() {
    Row({ space: 4 }) {
      Button('肌肉地图', { type: ButtonType.Normal })
        .layoutWeight(1).height(38).fontSize(14)
        .fontWeight(!this.showAll ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(!this.showAll ? this.inkColor() : this.mutedColor())
        .backgroundColor(!this.showAll ? (this.isDark ? '#35483F' : '#FFFFFF') : Color.Transparent)
        .borderRadius(12).onClick(() => this.switchTab(false))
      Button('全部动作', { type: ButtonType.Normal })
        .layoutWeight(1).height(38).fontSize(14)
        .fontWeight(this.showAll ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.showAll ? this.inkColor() : this.mutedColor())
        .backgroundColor(this.showAll ? (this.isDark ? '#35483F' : '#FFFFFF') : Color.Transparent)
        .borderRadius(12).onClick(() => this.switchTab(true))
    }
    .padding(4).margin({ left: 20, right: 20, bottom: 8 })
    .backgroundColor(this.isDark ? '#20342B' : '#DDE8E1').borderRadius(16)
  }

  @Builder
  SceneControl(label: string, action: string) {
    Button(label, { type: ButtonType.Normal })
      .height(38).fontSize(12).fontColor(this.inkColor()).backgroundColor(Color.Transparent)
      .padding({ left: 16, right: 16 }).borderRadius(18)
      .onClick(() => this.runSceneAction(action))
  }

  @Builder
  ModelFailure() {
    Column({ space: 12 }) {
      Text('人体模型暂未加载').fontSize(19).fontWeight(FontWeight.Medium).fontColor(this.inkColor())
      Text('也可以从肌群列表选择目标，继续添加动作')
        .fontSize(12).fontColor(this.mutedColor()).textAlign(TextAlign.Center)
      Row({ space: 12 }) {
        Button('重试模型').fontSize(13).height(40).fontColor(this.accentColor())
          .backgroundColor(this.isDark ? '#253E33' : '#DFECE3').onClick(() => this.retryModel())
        Button('选择肌群').fontSize(13).height(40).fontColor('#FFFFFF')
          .backgroundColor('#21795E').onClick(() => this.openSheet('muscles'))
      }
    }.padding(24).width('100%')
  }

  @Builder
  ModelStage() {
    Stack() {
      if (this.modelFailed) {
        this.ModelFailure()
      } else if (this.themeReady) {
        MuscleSceneView({
          selectedKey: this.selectedKey,
          actionNonce: this.actionNonce,
          actionName: this.actionName,
          isDark: this.isDark,
          onPicked: (key: string) => this.handlePickMuscle(key),
          onStatus: (ok: boolean) => { this.modelFailed = !ok; }
        })
      } else {
        LoadingProgress().width(30).height(30).color(this.accentColor())
      }
      Row({ space: 8 }) {
        if (this.selectedKey.length > 0) {
          Row({ space: 6 }) {
            Circle().width(6).height(6).fill(this.accentColor())
            Text(muscleName(this.selectedKey)).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.inkColor())
          }
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.isDark ? '#DA253B30' : '#EFFFFFFF').borderRadius(18)
        }
        Blank()
        Button('肌群列表  ≡').height(36).fontSize(12).fontColor(this.inkColor())
          .backgroundColor(this.isDark ? '#DA253B30' : '#EFFFFFFF').onClick(() => this.openSheet('muscles'))
      }
      .width('100%').padding({ left: 20, right: 20, top: 10 }).align(Alignment.Top)
      if (!this.modelFailed) {
        Column({ space: 8 }) {
          Row() {
            this.SceneControl('正面', 'front')
            Divider().vertical(true).height(14).color(this.isDark ? '#43554B' : '#D8E2DC')
            this.SceneControl('背面', 'back')
            Divider().vertical(true).height(14).color(this.isDark ? '#43554B' : '#D8E2DC')
            this.SceneControl('复位', 'reset')
          }.backgroundColor(this.isDark ? '#E62B3E34' : '#F2FFFFFF').borderRadius(22)
          Text('拖动旋转  ·  双指缩放  ·  轻点肌肉').fontSize(10).fontColor(this.mutedColor())
        }.padding({ bottom: 12 }).align(Alignment.Bottom)
      }
    }
    .width('100%').layoutWeight(1).clip(true).backgroundColor(this.stageColor())
  }

  @Builder
  SelectionMark(item: RecommendItem) {
    Stack() {
      if (item.addedToday || isSelected(this.selectedIds, item.id)) {
        Text('✓').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(item.addedToday ? this.mutedColor() : '#FFFFFF')
      }
    }
    .width(24).height(24).borderRadius(8)
    .backgroundColor(isSelected(this.selectedIds, item.id) && !item.addedToday ? '#21795E' : Color.Transparent)
    .border({ width: 1.3, color: isSelected(this.selectedIds, item.id) && !item.addedToday ? '#21795E' :
      (this.isDark ? '#566B5D' : '#CAD8D0') })
  }

  @Builder
  RecommendRow(item: RecommendItem) {
    Row({ space: 12 }) {
      Column({ space: 6 }) {
        Text(item.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.inkColor())
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(this.equipmentOf(item.id)).fontSize(11).fontColor(this.mutedColor())
          if (item.role.length > 0) {
            Text(item.role === 'secondary' ? '辅助参与' : '主练肌群').fontSize(10)
              .fontColor(item.role === 'secondary' ? this.mutedColor() : this.accentColor())
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(item.role === 'secondary' ? Color.Transparent : (this.isDark ? '#233E32' : '#EAF4EC'))
              .borderRadius(4)
          }
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (item.addedToday) {
        Text('今日已添加').fontSize(11).fontColor(this.mutedColor())
      }
      this.SelectionMark(item)
    }
    .width('100%').padding({ left: 14, right: 14, top: 13, bottom: 13 })
    .backgroundColor(isSelected(this.selectedIds, item.id) && !item.addedToday ?
      (this.isDark ? '#20372B' : '#F0F7F1') : (this.isDark ? '#1C2C24' : '#FFFFFF'))
    .borderRadius(16)
    .border({ width: 1, color: isSelected(this.selectedIds, item.id) && !item.addedToday ?
      (this.isDark ? '#3C6A50' : '#BED8C5') : (this.isDark ? '#283B30' : '#ECF0EA') })
    .opacity(item.addedToday ? 0.6 : 1).accessibilityGroup(true)
    .accessibilityText(`${item.name}，${item.addedToday ? '今日已添加' :
      (isSelected(this.selectedIds, item.id) ? '已选择，点击取消' : '点击选择')}`)
    .onClick(() => this.handleToggle(item))
  }

  @Builder
  ListContent() {
    if (this.catalogLoading) {
      Column({ space: 10 }) {
        LoadingProgress().width(26).height(26).color(this.accentColor())
        Text('正在加载动作…').fontSize(13).fontColor(this.mutedColor())
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.loadError.length > 0) {
      Column({ space: 10 }) {
        Text(this.loadError).fontSize(14).fontColor(this.inkColor())
        Button('重新加载').height(36).fontSize(12).fontColor(this.accentColor())
          .backgroundColor(this.isDark ? '#273E31' : '#E5EFE7').onClick(() => this.reloadCatalog())
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.listItems.length === 0) {
      Column({ space: 8 }) {
        Text(this.showAll ? '没有找到相关动作' : '这个肌群暂时没有预设动作').fontSize(14).fontColor(this.inkColor())
        Text(this.showAll ? '试试其他名称或别名' : '可在全部动作中继续选择').fontSize(12).fontColor(this.mutedColor())
        if (!this.showAll) {
          Button('浏览全部动作').height(34).fontSize(12).fontColor(this.accentColor())
            .backgroundColor(this.isDark ? '#273E31' : '#E5EFE7').onClick(() => this.switchTab(true))
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
            .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
          Text(this.selectedKey.length > 0 ? `${this.listItems.length} 个动作  ·  可跨肌群多选` :
            '轻点人体上的肌肉，发现适合的动作').fontSize(11).fontColor(this.mutedColor())
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (this.selectedKey.length > 0) {
          Button(this.panelOpen ? '收起 ⌄' : '展开 ⌃').height(36).fontSize(12).fontColor(this.accentColor())
            .backgroundColor(this.isDark ? '#253C2F' : '#EDF4ED')
            .onClick(() => { this.panelOpen = !this.panelOpen; })
        }
      }.width('100%').padding({ top: 16, bottom: 14 })
      if (this.panelOpen && this.selectedKey.length > 0) { this.ListContent() }
    }
    .width('100%').height(this.panelOpen && this.selectedKey.length > 0 ? this.dockHeight() : 78)
    .padding({ left: 20, right: 20, bottom: this.panelOpen ? 10 : 0 })
    .backgroundColor(this.isDark ? '#17271E' : '#FBFCF8').borderRadius({ topLeft: 26, topRight: 26 })
  }

  @Builder
  Library() {
    Column({ space: 14 }) {
      TextInput({ text: this.searchText, placeholder: '搜索动作名称或别名' })
        .height(48).fontSize(14).fontColor(this.inkColor()).placeholderColor(this.mutedColor())
        .backgroundColor(this.isDark ? '#263D30' : '#FFFFFF').borderRadius(16).padding({ left: 16, right: 16 })
        .onChange((value: string) => { this.searchText = value; this.refreshList(); })
      Row() {
        Text(this.searchText.trim().length > 0 ? '搜索结果' : '动作库')
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
        Blank()
        Text(`${this.listItems.length} 个动作`).fontSize(12).fontColor(this.mutedColor())
      }.width('100%')
      this.ListContent()
    }.width('100%').layoutWeight(1).padding({ left: 20, right: 20, top: 10, bottom: 12 })
  }

  @Builder
  Footer() {
    Row({ space: 14 }) {
      Column({ space: 5 }) {
        Row({ space: 4 }) {
          Text(`${this.selectedIds.length}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
          Text('个已选').fontSize(12).fontColor(this.mutedColor())
        }
        Text(this.selectedIds.length > 0 ? '查看清单 ›' : '支持多选')
          .fontSize(11).fontColor(this.selectedIds.length > 0 ? this.accentColor() : this.mutedColor())
      }
      .alignItems(HorizontalAlign.Start).width(92).accessibilityGroup(true)
      .accessibilityText(`已选择 ${this.selectedIds.length} 个动作，查看选择清单`)
      .onClick(() => { if (this.selectedIds.length > 0) { this.openSheet('selected'); } })
      Button(this.submitting ? '正在添加…' :
        (this.selectedIds.length > 0 ? `添加 ${this.selectedIds.length} 个动作` : '选择动作后添加'),
        { type: ButtonType.Normal })
        .layoutWeight(1).height(52).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.selectedIds.length > 0 ? '#FFFFFF' : this.mutedColor())
        .backgroundColor(this.selectedIds.length > 0 ? '#21795E' : (this.isDark ? '#2B3D31' : '#E2EAE1'))
        .borderRadius(17)
        .enabled(this.selectedIds.length > 0 && !this.submitting && !this.catalogLoading && this.loadError.length === 0)
        .onClick(() => this.confirmAdd())
    }
    .width('100%').padding({ left: 22, right: 20, top: 13, bottom: 18 })
    .backgroundColor(this.isDark ? '#17271E' : '#FBFCF8')
    .border({ width: { top: 1 }, color: this.isDark ? '#2C3E32' : '#E8EDE6' })
  }

  @Builder
  MuscleGroup(title: string, muscles: MuscleInfo[]) {
    Column({ space: 12 }) {
      Text(title).fontSize(12).fontColor(this.mutedColor()).width('100%')
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(muscles, (info: MuscleInfo) => {
          Row() {
            Text(info.name).fontSize(14).fontColor(this.selectedKey === info.key ? this.accentColor() : this.inkColor())
            Blank()
            if (this.selectedKey === info.key) { Text('✓').fontSize(13).fontColor(this.accentColor()) }
          }
          .width('48%').height(48).padding({ left: 14, right: 12 }).margin({ bottom: 8 }).borderRadius(12)
          .backgroundColor(this.selectedKey === info.key ? (this.isDark ? '#284D37' : '#E4F1E5') :
            (this.isDark ? '#26372C' : '#F1F4ED')).onClick(() => this.handlePickMuscle(info.key))
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
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.inkColor())
          Text(this.sheetKind === 'muscles' ? '选择后，查看对应的推荐动作' : '确认添加前，可随时调整这份清单')
            .fontSize(12).fontColor(this.mutedColor())
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button('×', { type: ButtonType.Circle }).width(36).height(36).fontSize(23).fontColor(this.mutedColor())
          .backgroundColor(this.isDark ? '#2B3D30' : '#EEF2E9').accessibilityText('关闭清单')
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
          Text('清单已清空').fontSize(18).fontColor(this.inkColor())
          Text('返回肌肉地图或动作库，继续挑选').fontSize(13).fontColor(this.mutedColor())
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.selectedIds, (id: string, index: number) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(`${index + 1}`).fontSize(13).fontColor(this.accentColor()).width(24)
                Column({ space: 4 }) {
                  Text(this.nameOf(id)).fontSize(15).fontColor(this.inkColor())
                  Text(this.equipmentOf(id)).fontSize(11).fontColor(this.mutedColor())
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Button('移除').height(36).fontSize(12).fontColor(this.mutedColor()).backgroundColor(Color.Transparent)
                  .accessibilityText(`移除${this.nameOf(id)}`).enabled(!this.submitting).onClick(() => this.removeSelected(id))
              }.width('100%').padding(14).backgroundColor(this.isDark ? '#26372C' : '#F1F4ED').borderRadius(15)
            }
          }, (id: string) => id)
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
      Button(this.sheetKind === 'muscles' ? '返回人体模型' : '继续选择', { type: ButtonType.Normal })
        .width('100%').height(48).fontSize(14).fontColor(this.accentColor())
        .backgroundColor(this.isDark ? '#263D2F' : '#EAF2E7').borderRadius(15).margin({ top: 16, bottom: 18 })
        .onClick(() => { this.sheetOpen = false; })
    }.width('100%').height('100%').padding({ left: 22, right: 22 })
    .backgroundColor(this.isDark ? '#17271E' : '#FBFCF8')
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
    .width('100%').height('100%').backgroundColor(this.stageColor())
    .onAreaChange((_oldArea: Area, area: Area) => { this.pageHeight = area.height as number; })
    .bindSheet($$this.sheetOpen, this.PickerSheet, {
      height: '74%', dragBar: true, showClose: false,
      backgroundColor: this.isDark ? '#17271E' : '#FBFCF8'
    })
  }
}
