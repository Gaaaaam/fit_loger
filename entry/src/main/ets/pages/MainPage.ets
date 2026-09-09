import { CalendarPage } from './CalendarPage';
import { MinePage } from './MinePage';
import { TrendsPage } from './TrendsPage';

@Entry
@Component
struct MainPage {
  @Provide('calRefresh') refreshStamp: number = 0;
  @Provide('mainTabIndex') currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  onPageShow(): void {
    this.refreshStamp++;
  }

  @Builder
  tabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentIndex === index ? $r('app.color.accent') : $r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller, index: this.currentIndex }) {
      TabContent() {
        CalendarPage()
      }
      .tabBar(this.tabItem('日历', 0))

      TabContent() {
        TrendsPage()
      }
      .tabBar(this.tabItem('趋势', 1))

      TabContent() {
        MinePage()
      }
      .tabBar(this.tabItem('我的', 2))
    }
    .barWidth('100%')
    .barHeight(56)
    .barBackgroundColor($r('app.color.card_bg'))
    .animationDuration(0)
    .onChange((index: number) => {
      this.currentIndex = index;
      this.refreshStamp++;
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
