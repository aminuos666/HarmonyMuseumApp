import router from '@ohos.router';
import { UserDynamic, User } from '../model/User';
import { UserService } from '../service/UserService';
import { EmptyView } from '../component/ArtworkCard';

@Component
export struct DynamicTab {
  @State private dynamics: UserDynamic[] = [];
  @State private showPublish: boolean = false;
  @State private publishContent: string = '';
  @State private selectedTab: number = 0; // 0: 推荐, 1: 关注

  private userService = UserService.getInstance();

  aboutToAppear(): void {
    this.loadDynamics();
  }

  loadDynamics(): void {
    if (this.selectedTab === 0) {
      this.dynamics = this.userService.getDynamics();
    } else {
      this.dynamics = this.userService.getFollowDynamics();
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('动态')
          .fontSize(24)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Button() {
          Text('✏️ 发布')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .height(32)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(16)
        .onClick(() => { this.showPublish = true; })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      // 标签切换
      Row({ space: 0 }) {
        ForEach(['推荐', '关注'], (tab: string, idx: number) => {
          Column() {
            Text(tab)
              .fontSize(15)
              .fontColor(this.selectedTab === idx ?
                $r('app.color.primary') : $r('app.color.text_secondary'))
              .fontWeight(this.selectedTab === idx ? FontWeight.Medium : FontWeight.Regular)
              .padding({ bottom: 8 })
              .onClick(() => {
                this.selectedTab = idx;
                this.loadDynamics();
              })
            if (this.selectedTab === idx) {
              Divider().width(30).color($r('app.color.primary')).strokeWidth(2)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
      .padding({ left: 80, right: 80 })
      .borderWidth({ bottom: 1 })
      .borderColor({ bottom: $r('app.color.divider') })

      // 发布动态弹窗
      if (this.showPublish) {
        Column() {
          Row() {
            Text('发布动态')
              .fontSize(17)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)
            Blank()
            Text('取消')
              .fontSize(14)
              .fontColor($r('app.color.text_hint'))
              .onClick(() => {
                this.showPublish = false;
                this.publishContent = '';
              })
            Text('发布')
              .fontSize(14)
              .fontColor($r('app.color.primary'))
              .fontWeight(FontWeight.Medium)
              .margin({ left: 16 })
              .onClick(() => {
                if (this.publishContent.length > 0) {
                  this.userService.publishDynamic(this.publishContent, []);
                  this.showPublish = false;
                  this.publishContent = '';
                  this.loadDynamics();
                }
              })
          }
          .padding(16)

          TextArea({
            placeholder: '分享你的文物见闻...',
            text: this.publishContent
          })
            .height(160)
            .fontSize(14)
            .placeholderColor($r('app.color.text_hint'))
            .padding(12)
            .onChange((v) => { this.publishContent = v; })
        }
        .backgroundColor($r('app.color.background_card'))
        .borderRadius(12)
        .margin(16)
      }

      // 动态列表
      if (this.dynamics.length === 0) {
        EmptyView({ text: '暂无动态' })
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.dynamics, (dynamic: UserDynamic) => {
              this.buildDynamicCard(dynamic)
            })
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
  buildDynamicCard(dynamic: UserDynamic): void {
    Column() {
      Row({ space: 10 }) {
        Image('https://example.com/avatar/default.jpg')
          .width(40)
          .height(40)
          .objectFit(ImageFit.Cover)
          .borderRadius(20)

        Column({ space: 2 }) {
          Text('文物爱好者')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
          Row({ space: 8 }) {
            Text(this.formatTime(dynamic.createTime))
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      // 内容
      Text(dynamic.content)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })

      // 关联文物
      if (dynamic.relatedArtworkName) {
        Row() {
          Text(`关联文物: ${dynamic.relatedArtworkName}`)
            .fontSize(12)
            .fontColor($r('app.color.primary'))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4 })
        .onClick(() => {
          if (dynamic.relatedArtworkId) {
            router.pushUrl({
              url: 'pages/ArtworkDetailPage',
              params: { artworkId: dynamic.relatedArtworkId }
            });
          }
        })
      }

      // 互动
      Row({ space: 24 }) {
        Row({ space: 4 }) {
          Text('❤')
            .fontSize(14)
          Text(`${dynamic.likeCount}`)
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
        }
        Row({ space: 4 }) {
          Text('💬')
            .fontSize(14)
          Text(`${dynamic.commentCount}`)
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
        }
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 12 })

      Divider().color($r('app.color.divider_light'))
    }
    .width('100%')
    .backgroundColor($r('app.color.background_card'))
  }

  private formatTime(timestamp: number): string {
    const diff = Date.now() - timestamp;
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`;
    return new Date(timestamp).toLocaleDateString();
  }
}
