import router from '@ohos.router';
import { User, PrivacyLevel, UserUpload } from '../model/User';
import { UserService } from '../service/UserService';

@Entry
@Component
struct ProfilePage {
  @State private user: User | null = null;
  @State private isLoggedIn: boolean = false;
  @State private uploadCount: number = 0;
  @State private browseCount: number = 0;

  private userService = UserService.getInstance();

  aboutToAppear(): void {
    this.refreshUserState();
  }

  onPageShow(): void {
    this.refreshUserState();
  }

  private refreshUserState(): void {
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
          Column({ space: 16 }) {
            this.buildUserHeader()
            this.buildMenuSection()
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildNotLoggedIn(): void {
    Column({ space: 20 }) {
      Blank()
      Image($r('app.media.icon')).width(200).height(200)
        .objectFit(ImageFit.Contain).borderRadius(24)
        .shadow({ radius: 12, color: $r('app.color.shadow'), offsetY: 4 }).opacity(0.85)
      Text('登录后查看更多内容').fontSize(16).fontColor($r('app.color.text_hint'))
      Button() {
        Text('登录 / 注册').fontSize(16).fontColor(Color.White)
      }
      .width(200).height(48)
      .backgroundColor($r('app.color.primary')).borderRadius(24)
      .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }); })
      Blank()
    }
    .width('100%').height('100%').alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildUserHeader(): void {
    Column({ space: 12 }) {
      Row({ space: 16 }) {
        Stack() {
          Image(this.user?.avatar || '').width(72).height(72)
            .objectFit(ImageFit.Cover).borderRadius(36)
            .backgroundColor($r('app.color.shimmer_base'))
            .border({ width: 2.5, color: $r('app.color.primary') })
        }
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.user?.nickname || '').fontSize(22)
              .fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Bold)
            if (this.user?.isVip) {
              Text('V').fontSize(11).fontColor($r('app.color.primary'))
                .backgroundColor($r('app.color.accent_light'))
                .borderRadius(8).padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .fontWeight(FontWeight.Bold)
            }
          }
          Text(this.user?.bio || '').fontSize(13).fontColor($r('app.color.text_secondary'))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(18)
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)

        Button() {
          Text('编辑').fontSize(12).fontColor($r('app.color.primary'))
        }
        .height(30)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(15)
        .padding({ left: 12, right: 12 })
        .onClick(() => { router.pushUrl({ url: 'pages/SettingsPage' }); })
      }
      .width('100%').padding(16)
      .backgroundColor($r('app.color.background_card'))
      .borderRadius(16)
      .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
    }
  }

  @Builder
  buildMenuSection(): void {
    Column({ space: 10 }) {
      Column({ space: 0 }) {
        this.buildMenuItem('⭐', '我的收藏', () => { router.pushUrl({ url: 'pages/CollectionPage' }); })
        Divider().color('#333333').height(0.5).margin({ left: 50, right: 16 })
        this.buildMenuItem('❤️', '我的点赞', () => { router.pushUrl({ url: 'pages/MyLikesPage' }); })
        Divider().color('#333333').height(0.5).margin({ left: 50, right: 16 })
        this.buildMenuItem('🕐', '浏览记录', () => { router.pushUrl({ url: 'pages/BrowseHistoryPage' }); })
      }
      .width('100%').backgroundColor($r('app.color.background_card')).borderRadius(14)

      Column({ space: 0 }) {
        this.buildMenuItem('⚙️', '设置', () => { router.pushUrl({ url: 'pages/SettingsPage' }); })
      }
      .width('100%').backgroundColor($r('app.color.background_card')).borderRadius(14)
    }
    .width('100%')
  }

  @Builder
  buildMenuItem(emoji: string, label: string, onClick: () => void): void {
    Row() {
      Text(emoji).fontSize(20).opacity(0.8).margin({ right: 10 })
      Text(label).fontSize(15).fontColor($r('app.color.text_primary')).layoutWeight(1)
      Text('›').fontSize(18).fontColor($r('app.color.text_hint')).opacity(0.3)
    }
    .padding({ left: 16, top: 15, bottom: 15, right: 16 })
    .width('100%')
    .onClick(() => { onClick(); })
  }
}
