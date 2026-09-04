import { WorkoutRepository } from '../db/WorkoutRepository';
import { BODY_PARTS, BodyPartInfo, EQUIPMENT_OPTIONS, Equipment, EquipmentInfo, PartKey, toPartKey } from '../model/types';

@Component
export struct CreateExerciseSheet {
  @Prop defaultPart: PartKey = 'chest';
  @State nameText: string = '';
  @State partKey: PartKey = 'chest';
  @State equipment: Equipment = 'barbell';
  @State errorText: string = '';
  onCreated: (exerciseId: string) => void = (_id: string) => {
  };

  aboutToAppear(): void {
    this.partKey = this.defaultPart;
  }

  private async save(): Promise<void> {
    const name: string = this.nameText.trim();
    if (name.length === 0) {
      this.errorText = '请填写动作名称';
      return;
    }
    this.errorText = '';
    const id: string = await WorkoutRepository.createCustomExercise(name, this.partKey, this.equipment);
    this.onCreated(id);
  }

  build() {
    Column() {
      Text('新建动作')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 16 })
        .width('100%')

      TextInput({ text: this.nameText, placeholder: '动作名称' })
        .height(44)
        .backgroundColor($r('app.color.chip_bg'))
        .borderRadius(8)
        .onChange((value: string) => {
          this.nameText = value;
        })

      Text('部位')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16, bottom: 8 })
        .width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(BODY_PARTS, (part: BodyPartInfo) => {
          Text(part.name)
            .fontSize(14)
            .fontColor(this.partKey === part.key ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
            .backgroundColor(this.partKey === part.key ? $r('app.color.accent') : $r('app.color.chip_bg'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.partKey = toPartKey(part.key);
            })
        }, (part: BodyPartInfo) => part.key)
      }
      .width('100%')

      Text('器械')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8, bottom: 8 })
        .width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(EQUIPMENT_OPTIONS, (item: EquipmentInfo) => {
          Text(item.name)
            .fontSize(14)
            .fontColor(this.equipment === item.key ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
            .backgroundColor(this.equipment === item.key ? $r('app.color.accent') : $r('app.color.chip_bg'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.equipment = item.key;
            })
        }, (item: EquipmentInfo) => item.key)
      }
      .width('100%')

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .margin({ top: 8 })
          .width('100%')
      }

      Button('保存')
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.text_on_accent'))
        .width('100%')
        .height(44)
        .margin({ top: 20 })
        .onClick(() => {
          this.save();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 24 })
  }
}
