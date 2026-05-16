import router from '@ohos.router';
import { User, PrivacyLevel, UserUpload } from '../model/User';
import { UserService } from '../service/UserService';

@Component
export struct ProfileTab {
  @State private user: User | null = null;
  @State private isLoggedIn: boolean = false;
  @State private uploadCount: number = 0;
  @State private browseCount: number = 0;

  private userService = UserService.getInstance();

  aboutToAppear(): void {
    this.syncUserState();
  }

  /** 从 UserService 同步登录状态 */
  private syncUserState(): void {
    this.isLoggedIn = this.userService.isLoggedIn();
    if (this.isLoggedIn) {
      this.user = this.userService.getCurrentUser();
      this.uploadCount = this.userService.getUploads().length;
      this.browseCount = this.userService.getBrowseHistory().length;
    }
  }

  build() {
    Column() {
      if (!this.isLoggedIn) {
        this.buildNotLoggedIn()
      } else {
        Scroll() {
          Column() {
            this.buildUserHeader()
            this.buildStatsRow()
            this.buildMenuSection()
          }
          .padding({ bottom: 80 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildNotLoggedIn(): void {
    Column({ space: 24 }) {
      Blank()

      Text('👤')
        .fontSize(80)
        .opacity(0.4)

      Text('登录后查看更多内容')
        .fontSize(16)
        .fontColor($r('app.color.text_hint'))

      Button() {
        Text('登录 / 注册')
          .fontSize(16)
          .fontColor(Color.White)
      }
      .width(200)
      .height(48)
      .backgroundColor($r('app.color.primary'))
      .borderRadius(24)
      .onClick(() => {
        router.pushUrl({ url: 'pages/LoginPage' });
      })

      Blank()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildUserHeader(): void {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        Image(this.user?.avatar || '')
          .width(64)
          .height(64)
          .objectFit(ImageFit.Cover)
          .borderRadius(32)
          .backgroundColor($r('app.color.shimmer_base'))

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.user?.nickname || '')
              .fontSize(20)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
            if (this.user?.isVip) {
              Text('VIP')
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.favorite_active'))
                .borderRadius(4)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            }
          }

          Text(this.user?.bio || '')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.user?.email || this.user?.phone || '')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button() {
          Text('⚙️ 设置')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
        }
        .height(32)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(16)
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsPage' });
        })
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  buildStatsRow(): void {
    Row({ space: 0 }) {
      this.buildStatItem('收藏', `${this.userService.getCollections().length}`)
      this.buildStatItem('粉丝', `${this.user?.followerCount || 0}`)
      this.buildStatItem('关注', `${this.user?.followingCount || 0}`)
      this.buildStatItem('浏览', `${this.browseCount}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
  }

  @Builder
  buildStatItem(label: string, value: string): void {
    Column() {
      Text(value)
        .fontSize(20)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildMenuSection(): void {
    Column({ space: 0 }) {
      this.buildMenuItem('⭐', '我的收藏', () => {
        router.pushUrl({ url: 'pages/CollectionPage' });
      })
      this.buildMenuItem('❤️', '我的点赞', () => {
        router.pushUrl({ url: 'pages/MyLikesPage' });
      })
      this.buildMenuItem('📤', '我的上传', () => {
        router.pushUrl({ url: 'pages/UploadPage' });
      })
      Divider().color($r('app.color.divider')).margin({ left: 50 })
      this.buildMenuItem('🕐', '浏览历史', () => {
        router.pushUrl({ url: 'pages/BrowseHistoryPage' });
      })
      Divider().color($r('app.color.divider')).margin({ left: 50 })
      this.buildMenuItem('💬', '我的动态', () => {
        router.pushUrl({ url: 'pages/UserDynamicPage' });
      })
      Divider().color($r('app.color.divider')).margin({ left: 50 })
      this.buildMenuItem('🔔', '消息通知', () => {
        router.pushUrl({ url: 'pages/NotificationPage' });
      })
      Divider().color($r('app.color.divider')).margin({ left: 50 })
      this.buildMenuItem('⚙️', '设置', () => {
        router.pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 16 })
  }

  @Builder
  buildMenuItem(emoji: string, label: string, onClick: () => void): void {
    Row() {
      Text(emoji)
        .fontSize(20)
        .opacity(0.7)

      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 10 })
        .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor($r('app.color.text_hint'))
        .opacity(0.3)
        .margin({ right: 16 })
    }
    .padding({ left: 16, top: 16, bottom: 16 })
    .width('100%')
    .onClick(() => { onClick(); })
  }
}
