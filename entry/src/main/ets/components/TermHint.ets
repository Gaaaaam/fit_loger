@Component
export struct TermHint {
  @Prop termId: string = '';
  onOpen: (id: string) => void = (_id: string) => {
  };

  build() {
    Text('?')
      .fontSize(11)
      .fontColor($r('app.color.accent'))
      .textAlign(TextAlign.Center)
      .width(18)
      .height(18)
      .borderRadius(9)
      .backgroundColor($r('app.color.accent_soft'))
      .margin({ left: 6 })
      .onClick(() => {
        if (this.termId.length === 0) {
          return;
        }
        this.onOpen(this.termId);
      })
      .hitTestBehavior(HitTestMode.Block)
  }
}
