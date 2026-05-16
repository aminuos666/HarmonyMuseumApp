import router from '@ohos.router';
import { BrowseHistory } from '../model/User';
import { Artwork } from '../model/Artwork';
import { UserService } from '../service/UserService';
import { ArtworkService } from '../service/ArtworkService';

@Entry
@Component
struct BrowseHistoryPage {
  @State private historyItems: BrowseHistory[] = [];
  @State private historyArtworks: Artwork[] = [];
  @State private isLoading: boolean = true;

  private userService = UserService.getInstance();
  private artworkService = ArtworkService.getInstance();

  aboutToAppear(): void {
    this.loadHistory();
  }

  loadHistory(): void {
    // 从缓存加载
    this.historyItems = this.userService.getBrowseHistory();
    const artworkIds = this.historyItems.map(h => h.artworkId);
    this.historyArtworks = this.artworkService.getArtworksByIds(artworkIds);
    this.isLoading = false;
    // 异步从后端加载最新数据
    this.userService.fetchBrowseHistory().then((ids) => {
      if (ids.length > 0) {
        this.historyItems = this.userService.getBrowseHistory();
        this.artworkService.fetchArtworksByIds(ids).then((artworks) => {
          this.historyArtworks = artworks;
        });
      }
    });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('◀')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { router.back(); })

        Blank()

        Text('浏览历史')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Button() {
          Text('🗑️ 清空')
            .fontSize(14)
            .fontColor($r('app.color.error'))
        }
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          await this.userService.clearBrowseHistory();
          this.historyItems = [];
          this.historyArtworks = [];
        })
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color($r('app.color.primary'))
          .margin({ top: 60 })
      } else if (this.historyItems.length === 0) {
        // 空状态
        Column({ space: 12 }) {
          Blank()
          Text('暂无浏览记录')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
          Blank()
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.historyItems, (item: BrowseHistory, index: number) => {
            ListItem() {
              this.buildHistoryItem(item, this.historyArtworks[index])
            }
          })
        }
        .width('100%')
        .padding(16)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildHistoryItem(item: BrowseHistory, artwork: Artwork): void {

    Row({ space: 12 }) {
      Image(artwork?.coverImage || '')
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor($r('app.color.shimmer_base'))

      Column({ space: 4 }) {
        Text(artwork?.name || '未知文物')
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(artwork?.dynasty || '')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(artwork?.type || '')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }

        Text(this.formatTime(item.browseTime))
          .fontSize(11)
          .fontColor($r('app.color.text_hint'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .height(80)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
    .onClick(() => {
      if (artwork) {
        router.pushUrl({
          url: 'pages/ArtworkDetailPage',
          params: { artworkId: artwork.id }
        });
      }
    })
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`;
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
}
