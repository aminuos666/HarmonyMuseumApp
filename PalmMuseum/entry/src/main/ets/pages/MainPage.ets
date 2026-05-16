import { Index } from './Index';
import { ExploreTab } from './ExploreTab';
import { DynamicTab } from './DynamicTab';
import { ProfileTab } from './ProfileTab';

class TabConfig {
  label: string = '';
  icon: string = '';
}

@Entry
@Component
struct MainPage {
  @State private currentIndex: number = 0;

  private tabs: TabConfig[] = [
    { label: '首页', icon: '🏛' },
    { label: '发现', icon: '🔍' },
    { label: '动态', icon: '💬' },
    { label: '我的', icon: '👤' }
  ];

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentIndex
      }) {
        // 首页 Tab
        TabContent() {
          Index()
        }
        .tabBar(this.buildTabBar(0))

        // 发现 Tab
        TabContent() {
          ExploreTab()
        }
        .tabBar(this.buildTabBar(1))

        // 动态 Tab
        TabContent() {
          DynamicTab()
        }
        .tabBar(this.buildTabBar(2))

        // 我的 Tab
        TabContent() {
          ProfileTab()
        }
        .tabBar(this.buildTabBar(3))
      }
      .vertical(false)
      .scrollable(false)
      .barHeight(64)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabBar(index: number): void {
    Column({ space: 2 }) {
      Text(this.tabs[index].icon)
        .fontSize(22)
        .fontColor(this.currentIndex === index ?
          $r('app.color.primary') : $r('app.color.text_hint'))
      Text(this.tabs[index].label)
        .fontSize(10)
        .fontColor(this.currentIndex === index ?
          $r('app.color.primary') : $r('app.color.text_hint'))
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
  }
}
