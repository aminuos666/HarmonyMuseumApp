import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { UserService } from '../service/UserService';
import { ArtworkService } from '../service/ArtworkService';
import { ArtworkCard, EmptyView } from '../component/ArtworkCard';

@Entry
@Component
struct CollectionPage {
  @State private collectedArtworks: Artwork[] = [];
  @State private isLoading: boolean = true;

  private userService = UserService.getInstance();
  private artworkService = ArtworkService.getInstance();

  aboutToAppear(): void {
    this.loadCollections();
  }

  loadCollections(): void {
    const collectedIds = this.userService.getCollections();
    this.collectedArtworks = this.artworkService.getArtworksByIds(collectedIds);
    this.isLoading = false;
    // 异步从后端加载最新的收藏列表
    this.userService.fetchCollections().then((ids) => {
      if (ids.length > 0) {
        this.artworkService.fetchArtworksByIds(ids).then((artworks) => {
          if (artworks.length > 0) {
            this.collectedArtworks = artworks;
          }
        });
      } else {
        this.collectedArtworks = [];
      }
    });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('◀')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { router.back(); })

        Blank()
        Text('我的收藏')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`共 ${this.collectedArtworks.length} 件`)
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color($r('app.color.primary'))
          .margin({ top: 60 })
      } else if (this.collectedArtworks.length === 0) {
        Column({ space: 12 }) {
          Blank()
          Text('📭')
            .fontSize(64)
            .opacity(0.5)
          Text('还没有收藏文物')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
          Text('去首页发现喜欢的文物吧')
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
          Blank()
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Grid() {
            ForEach(this.collectedArtworks, (artwork: Artwork) => {
              GridItem() {
                ArtworkCard({ artwork: artwork })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/ArtworkDetailPage',
                      params: { artworkId: artwork.id }
                    });
                  })
              }
            }, (artwork: Artwork) => artwork.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(16)
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}
