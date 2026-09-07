@Component
export struct TrendsPage {
  build() {
    Column() {
      Text('趋势')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Column() {
        Text('趋势图表稍后提供')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 28, bottom: 8 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
