import { Index } from './Index';
import { ExploreTab } from './ExploreTab';
import { ProfileTab } from './ProfileTab';
import { UserService } from '../service/UserService';

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
    { label: '我的', icon: '👤' }
  ];

  aboutToAppear(): void {
    // 持久化 Token，App 重启后能恢复登录状态
    PersistentStorage.persistProp('access_token', '');

    // 尝试恢复登录会话
    const token = AppStorage.Get<string>('access_token') || '';
    if (token) {
      console.info('PalmMuseum 检测到已保存的 Token，尝试恢复登录');
      UserService.getInstance().restoreSession(token);
    }
  }

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

        // 我的 Tab
        TabContent() {
          ProfileTab()
        }
        .tabBar(this.buildTabBar(2))
      }
      .vertical(false)
      .scrollable(false)
      .barHeight(64)
      .barBackgroundColor($r('app.color.background_card'))
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildTabBar(index: number): void {
    Column({ space: 4 }) {
      // 顶部细线 — 选中时显示，增加厚重感
      Divider()
        .width(24)
        .height(2)
        .color($r('app.color.primary'))
        .opacity(this.currentIndex === index ? 1.0 : 0.0)
        .borderRadius(1)

      Text(this.tabs[index].icon)
        .fontSize(24)
        .fontColor(this.currentIndex === index ?
          $r('app.color.primary') : $r('app.color.text_hint'))

      Text(this.tabs[index].label)
        .fontSize(11)
        .fontColor(this.currentIndex === index ?
          $r('app.color.primary') : $r('app.color.text_hint'))
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Regular)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 4, bottom: 4 })
  }
}
