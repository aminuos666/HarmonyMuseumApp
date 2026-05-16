import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { ArtworkService } from '../service/ArtworkService';
import { UserService } from '../service/UserService';
import { ImageSearchService } from '../service/ImageSearchService';
import { SortType, Dynasty } from '../utils/Constants';
import { ArtworkCard } from '../component/ArtworkCard';
import { SearchBar } from '../component/SearchBar';

class SortItem {
  label: string = '';
  value: SortType = SortType.DEFAULT;
}

class DailyRecommendation {
  artwork: Artwork | null = null;
  show: boolean = true;
}

@Component
export struct Index {
  @State private artworks: Artwork[] = [];
  @State private currentSort: SortType = SortType.DEFAULT;
  @State private currentPage: number = 1;
  @State private isLoading: boolean = false;
  @State private selectedDynasty: string = '全部';
  @State private sortVisible: boolean = false;
  @State private dailyRec: DailyRecommendation = new DailyRecommendation();
  @State private showDaily: boolean = true;

  private artworkService = ArtworkService.getInstance();
  private userService = UserService.getInstance();

  aboutToAppear(): void {
    // 先从缓存加载
    this.loadArtworks();
    const cachedRec = this.artworkService.getDailyRecommendation();
    if (cachedRec) {
      this.dailyRec.artwork = cachedRec;
    }

    // 异步从后端 API 加载最新数据
    this.artworkService.fetchArtworks(this.currentSort, this.currentPage).then((list) => {
      if (list.length > 0) {
        this.loadArtworks();
      }
    });

    this.artworkService.fetchDailyRecommendation().then((rec) => {
      if (rec) {
        this.dailyRec.artwork = rec;
      }
    });
  }

  loadArtworks(): void {
    this.artworks = this.artworkService.getArtworks(this.currentSort, this.currentPage);
  }

  build() {
    Column() {
      if (this.showDaily && this.dailyRec.artwork && this.currentPage === 1) {
        this.buildDailyCard()
      }

      if (this.sortVisible) {
        this.buildSortPanel()
      }

      if (this.artworks.length > 0) {
        this.buildArtworkGrid()
      } else {
        this.buildEmptyState()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildDailyCard(): void {
    Column() {
      Row() {
        Text('🌟 今日推荐')
          .fontSize(15)
          .fontColor($r('app.color.primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Row({ space: 12 }) {
        Image(this.dailyRec.artwork?.coverImage || '')
          .width(100)
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor($r('app.color.shimmer_base'))

        Column({ space: 6 }) {
          Text(this.dailyRec.artwork?.name || '')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 8 }) {
            Text(this.dailyRec.artwork?.dynasty || '')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text(this.dailyRec.artwork?.type || '')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }

          Text(this.dailyRec.artwork?.description || '')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(18)

          Button() {
            Text('👀 去看看')
              .fontSize(13)
              .fontColor(Color.White)
          }
          .height(30)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(15)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ArtworkDetailPage',
              params: { artworkId: this.dailyRec.artwork?.id }
            });
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .height(120)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.background_card'))
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

      // 关闭按钮
      Button() {
        Text('✕ 今日不再显示')
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
      }
      .height(28)
      .backgroundColor(Color.Transparent)
      .margin({ top: 4 })
      .onClick(() => {
        this.showDaily = false;
      })
    }
    .width('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  buildSortPanel(): void {
    Column() {
      // 搜索框
      SearchBar({
        onSearch: (keyword: string) => {
          router.pushUrl({
            url: 'pages/SearchPage',
            params: { keyword: keyword }
          });
        },
        onVoiceSearch: () => {
          router.pushUrl({ url: 'pages/SearchPage' });
        }
      })

      // 排序按钮
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        Button() {
          Row({ space: 4 }) {
            Text(this.currentSort === SortType.POPULAR ? '✅' : '🔥')
              .fontSize(14)
            Text('按热度')
              .fontSize(13)
              .fontColor(this.currentSort === SortType.POPULAR ?
                $r('app.color.primary') : $r('app.color.text_secondary'))
          }
        }
        .height(32)
        .backgroundColor(this.currentSort === SortType.POPULAR ?
          $r('app.color.accent_light') : $r('app.color.background_card'))
        .borderRadius(16)
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          this.currentSort = SortType.POPULAR;
          this.loadArtworks();
        })

        Button() {
          Row({ space: 4 }) {
            Text(this.currentSort === SortType.DYNASTY ? '✅' : '📅')
              .fontSize(14)
            Text('按年代')
              .fontSize(13)
              .fontColor(this.currentSort === SortType.DYNASTY ?
                $r('app.color.primary') : $r('app.color.text_secondary'))
          }
        }
        .height(32)
        .backgroundColor(this.currentSort === SortType.DYNASTY ?
          $r('app.color.accent_light') : $r('app.color.background_card'))
        .borderRadius(16)
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          this.currentSort = SortType.DYNASTY;
          this.loadArtworks();
        })

        Button() {
          Row({ space: 4 }) {
            Text(this.currentSort === SortType.TYPE ? '✅' : '🏷️')
              .fontSize(14)
            Text('按类型')
              .fontSize(13)
              .fontColor(this.currentSort === SortType.TYPE ?
                $r('app.color.primary') : $r('app.color.text_secondary'))
          }
        }
        .height(32)
        .backgroundColor(this.currentSort === SortType.TYPE ?
          $r('app.color.accent_light') : $r('app.color.background_card'))
        .borderRadius(16)
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          this.currentSort = SortType.TYPE;
          this.loadArtworks();
        })

        Button() {
          Row({ space: 4 }) {
            Text('📷')
              .fontSize(14)
            Text('以图搜图')
              .fontSize(13)
              .fontColor($r('app.color.primary'))
          }
        }
        .height(32)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(16)
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ImageSearchPage' });
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })
    }
  }

  @Builder
  buildArtworkGrid(): void {
    Scroll() {
      Column({ space: 0 }) {
        // 图片网格
        Grid() {
          ForEach(this.artworks, (artwork: Artwork) => {
            GridItem() {
              ArtworkCard({
                artwork: artwork,
                onTap: () => {
                  router.pushUrl({
                    url: 'pages/ArtworkDetailPage',
                    params: { artworkId: artwork.id }
                  });
                }
              })
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .padding({ left: 16, right: 16 })
      }
      .padding({ bottom: 80 })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  buildEmptyState(): void {
    Column({ space: 12 }) {
      Blank()
      Text('📭')
        .fontSize(64)
        .opacity(0.5)
      Text('暂无文物数据')
        .fontSize(16)
        .fontColor($r('app.color.text_hint'))
      Blank()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
