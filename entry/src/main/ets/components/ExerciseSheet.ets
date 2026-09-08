import { filterPickerList, equipmentKeysIn, isCustomExercise } from '../common/ExerciseLogic';
import { WorkoutRepository } from '../db/WorkoutRepository';
import { cardImageOf } from '../model/exerciseArtwork';
import { ExerciseDef } from '../model/exerciseCatalog';
import {
  Equipment,
  equipmentName,
  EQUIPMENT_OPTIONS,
  EquipmentInfo,
  PartKey
} from '../model/types';
import { ExerciseInfoView } from './ExerciseInfoView';

@Component
export struct ExerciseSheet {
  @Prop partKey: PartKey = 'chest';
  @State allItems: ExerciseDef[] = [];
  @State visibleItems: ExerciseDef[] = [];
  @State filterChips: EquipmentInfo[] = [];
  @State searchText: string = '';
  @State equipmentFilter: string = '';
  @State loadState: string = 'loading';
  @State mode: string = 'list';
  @State detailId: string = '';
  private listScroller: Scroller = new Scroller();
  private savedY: number = 0;
  onPick: (exerciseId: string) => void = (_exerciseId: string) => {
  };
  onCreate: () => void = () => {
  };

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.loadState = 'loading';
    try {
      this.allItems = await WorkoutRepository.listExercises(this.partKey);
      this.filterChips = this.chipsOf(equipmentKeysIn(this.allItems));
      this.applyFilter();
      this.loadState = 'ready';
    } catch (err) {
      this.allItems = [];
      this.visibleItems = [];
      this.loadState = 'error';
    }
  }

  private applyFilter(): void {
    this.visibleItems = filterPickerList(this.allItems, this.searchText, this.equipmentFilter);
  }

  private openDetail(exerciseId: string): void {
    this.savedY = this.listScroller.currentOffset().yOffset;
    this.detailId = exerciseId;
    this.mode = 'detail';
  }

  private backToList(): void {
    this.mode = 'list';
    this.detailId = '';
  }

  private restoreScroll(): void {
    if (this.savedY <= 0) {
      return;
    }
    this.listScroller.scrollTo({ xOffset: 0, yOffset: this.savedY, animation: false });
  }

  private chipsOf(keys: Equipment[]): EquipmentInfo[] {
    const chips: EquipmentInfo[] = [];
    for (let i = 0; i < EQUIPMENT_OPTIONS.length; i++) {
      const option: EquipmentInfo = EQUIPMENT_OPTIONS[i];
      for (let k = 0; k < keys.length; k++) {
        if (keys[k] === option.key) {
          chips.push(option);
          break;
        }
      }
    }
    return chips;
  }

  private selectedDef(): ExerciseDef | null {
    for (let i = 0; i < this.allItems.length; i++) {
      if (this.allItems[i].id === this.detailId) {
        return this.allItems[i];
      }
    }
    return null;
  }

  private selectedName(): string {
    const def: ExerciseDef | null = this.selectedDef();
    if (def !== null) {
      return def.name;
    }
    return '';
  }

  private selectedPart(): PartKey {
    const def: ExerciseDef | null = this.selectedDef();
    if (def !== null) {
      return def.partKey;
    }
    return this.partKey;
  }

  @Builder
  CardItem(item: ExerciseDef) {
    Column({ space: 6 }) {
      Column({ space: 4 }) {
        Image(cardImageOf(item.id, item.partKey))
          .width('100%')
          .height(92)
          .objectFit(ImageFit.Contain)
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .onClick(() => {
        this.onPick(item.id);
      })

      Row() {
        Text(isCustomExercise(item.id) ? '自定义' : equipmentName(item.equipment))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.chip_bg'))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
        Blank()
        Text('详情')
          .fontSize(12)
          .fontColor($r('app.color.accent'))
          .padding({ left: 4, top: 4, bottom: 4 })
          .onClick(() => {
            this.openDetail(item.id);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(10)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.divider') })
    .accessibilityText(`${item.name}，${equipmentName(item.equipment)}`)
  }

  @Builder
  DetailView() {
    Column() {
      Row() {
        Text('返回')
          .fontSize(15)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            this.backToList();
          })
        Blank()
        Text('动作说明')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('返回')
          .fontSize(15)
          .fontColor(Color.Transparent)
      }
      .width('100%')
      .margin({ bottom: 12 })

      ExerciseInfoView({
        exerciseId: this.detailId,
        displayName: this.selectedName(),
        partKey: this.selectedPart(),
        showAdd: true,
        onAdd: () => {
          this.onPick(this.detailId);
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ListView() {
    Column() {
      Text('选择训练动作')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 10 })
        .width('100%')

      if (this.partKey === 'cardio') {
        Text('当前按组和次数记录；跑步、骑行的时长与距离记录暂未支持。')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: 8 })
      }

      TextInput({ text: this.searchText, placeholder: '搜索名称、别名或英文' })
        .height(40)
        .backgroundColor($r('app.color.chip_bg'))
        .borderRadius(8)
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.searchText = value;
          this.applyFilter();
        })

      Scroll() {
        Row() {
          Text('全部')
            .fontSize(13)
            .fontColor(this.equipmentFilter.length === 0 ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
            .backgroundColor(this.equipmentFilter.length === 0 ? $r('app.color.accent') : $r('app.color.chip_bg'))
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14)
            .margin({ right: 8 })
            .onClick(() => {
              this.equipmentFilter = '';
              this.applyFilter();
            })
          ForEach(this.filterChips, (item: EquipmentInfo) => {
            Text(item.name)
              .fontSize(13)
              .fontColor(this.equipmentFilter === item.key ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
              .backgroundColor(this.equipmentFilter === item.key ? $r('app.color.accent') : $r('app.color.chip_bg'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(14)
              .margin({ right: 8 })
              .onClick(() => {
                this.equipmentFilter = item.key;
                this.applyFilter();
              })
          }, (item: EquipmentInfo) => item.key)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ bottom: 10 })

      if (this.loadState === 'loading') {
        Text('加载中…')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 40 })
      } else if (this.loadState === 'error') {
        Column({ space: 12 }) {
          Text('动作列表读取失败')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Button('重试')
            .fontSize(15)
            .fontColor($r('app.color.accent'))
            .backgroundColor($r('app.color.accent_soft'))
            .onClick(() => {
              this.reload();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.visibleItems.length === 0) {
        Text('没有匹配的动作')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 40 })
      } else {
        Grid(this.listScroller) {
          ForEach(this.visibleItems, (item: ExerciseDef) => {
            GridItem() {
              this.CardItem(item)
            }
          }, (item: ExerciseDef) => item.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Auto)
        .onAppear(() => {
          this.restoreScroll();
        })
      }

      Button('新建动作')
        .fontSize(15)
        .fontColor($r('app.color.accent'))
        .backgroundColor($r('app.color.accent_soft'))
        .width('100%')
        .height(44)
        .margin({ top: 8 })
        .onClick(() => {
          this.onCreate();
        })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      if (this.mode === 'detail') {
        this.DetailView()
      } else {
        this.ListView()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 16 })
  }
}
