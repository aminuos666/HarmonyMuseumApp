import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { UserService } from '../service/UserService';
import { ArtworkService } from '../service/ArtworkService';

@Entry
@Component
struct MyLikesPage {
  @State private likedArtworks: Artwork[] = [];
  @State private isLoading: boolean = true;

  private userService = UserService.getInstance();
  private artworkService = ArtworkService.getInstance();

  aboutToAppear(): void {
    this.loadLikes();
  }

  loadLikes(): void {
    const likedIds = this.userService.getLikes();
    this.likedArtworks = this.artworkService.getArtworksByIds(likedIds);
    this.isLoading = false;
    // 异步从后端加载最新的点赞列表
    this.userService.fetchLikes().then((ids) => {
      if (ids.length > 0) {
        this.artworkService.fetchArtworksByIds(ids).then((artworks) => {
          if (artworks.length > 0) {
            this.likedArtworks = artworks;
          }
        });
      }
    });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('←')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(20)
        .onClick(() => { router.back(); })

        Blank()

        Text('我的点赞')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Text(`共 ${this.likedArtworks.length} 件`)
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
      } else if (this.likedArtworks.length === 0) {
        Column({ space: 12 }) {
          Blank()
          Text('还没有点赞过文物')
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
        List({ space: 12 }) {
          ForEach(this.likedArtworks, (artwork: Artwork) => {
            ListItem() {
              this.buildLikeCard(artwork)
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
  buildLikeCard(artwork: Artwork): void {
    Row({ space: 12 }) {
      Image(artwork.coverImage)
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .backgroundColor($r('app.color.shimmer_base'))

      Column({ space: 4 }) {
        Text(artwork.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(artwork.dynasty)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(artwork.type)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }

        Row({ space: 4 }) {
          Text('❤')
            .fontSize(12)
            .fontColor($r('app.color.favorite_active'))
          Text(`${artwork.likeCount}`)
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
        }
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
      router.pushUrl({
        url: 'pages/ArtworkDetailPage',
        params: { artworkId: artwork.id }
      });
    })
  }
}
