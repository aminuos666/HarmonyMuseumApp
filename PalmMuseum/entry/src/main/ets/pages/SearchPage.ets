import router from '@ohos.router';
import { Artwork, ArtworkSearchResult } from '../model/Artwork';
import { ArtworkService } from '../service/ArtworkService';
import { SpeechService } from '../service/SpeechService';

const PAGE_SIZE: number = 20;

@Entry
@Component
struct SearchPage {
  @State private searchText: string = '';
  @State private searchResult: ArtworkSearchResult = new ArtworkSearchResult();
  @State private displayCount: number = PAGE_SIZE;
  @State private hasMore: boolean = false;
  @State private isSearching: boolean = false;
  @State private isListening: boolean = false;

  private artworkService = ArtworkService.getInstance();
  private speechService = SpeechService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params && params['keyword']) {
      this.searchText = params['keyword'];
      this.doSearch();
    }
  }

  build() {
    Column() {
      // 搜索栏
      Row({ space: 8 }) {
        Button() {
          Text('←').fontSize(20).fontColor($r('app.color.text_primary'))
        }
        .width(36).height(36).backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(18)
        .onClick(() => { router.back(); })

        TextInput({
          placeholder: '搜索文物名称、朝代、关键字...',
          text: this.searchText
        })
          .layoutWeight(1).height(40).fontSize(15)
          .placeholderColor($r('app.color.text_hint'))
          .backgroundColor($r('app.color.search_bar_background'))
          .borderRadius(20).padding({ left: 16 })
          .onChange((value: string) => {
            this.searchText = value;
          })
          .onSubmit(() => { this.doSearch(); })

        Button() {
          Text(this.isListening ? '🔴' : '🎤').fontSize(17)
        }
        .width(36).height(36)
        .backgroundColor(this.isListening ? $r('app.color.error') : $r('app.color.accent_light'))
        .borderRadius(18)
        .onClick(async () => {
          this.isListening = true;
          try {
            const result = await this.speechService.startListening();
            if (result && result.trim().length > 0) {
              this.searchText = result;
              this.doSearch();
            }
          } catch (_) {}
          this.isListening = false;
        })
      }
      .width('100%').padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.isSearching) {
        LoadingProgress().width(36).height(36).color($r('app.color.primary')).margin({ top: 60 })
      } else if (this.searchResult.artworks.length > 0) {
        // 结果计数
        Row() {
          Text(`找到 ${this.searchResult.totalCount} 件`)
            .fontSize(13).fontColor($r('app.color.text_hint'))
          Blank()
        }
        .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 })

        // 紧凑卡片列表
        Scroll() {
          Column() {
            Grid() {
              ForEach(this.searchResult.artworks.slice(0, this.displayCount), (artwork: Artwork) => {
                GridItem() {
                  this.buildCompactCard(artwork)
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .padding({ left: 16, right: 16 })

            // 加载更多
            this.buildFooter()
          }
          .padding({ bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      } else if (this.searchText.length > 0) {
        Column({ space: 12 }) {
          Text('🔍').fontSize(64).opacity(0.4)
          Text('未找到相关文物').fontSize(16).fontColor($r('app.color.text_hint'))
          Text('试试其他关键词').fontSize(13).fontColor($r('app.color.text_hint'))
        }
        .width('100%').padding({ top: 80 }).alignItems(HorizontalAlign.Center)
      } else {
        Blank()
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.background'))
  }

  // ── 紧凑卡片（比 ArtworkCard 小） ──

  @Builder
  buildCompactCard(artwork: Artwork): void {
    Column() {
      Image(artwork.coverImage)
        .width('100%').aspectRatio(0.8)
        .objectFit(ImageFit.Cover).borderRadius(8)
        .backgroundColor($r('app.color.shimmer_base'))

      Column({ space: 3 }) {
        Text(artwork.name)
          .fontSize(13).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text(artwork.dynasty)
            .fontSize(10).fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.accent_light'))
            .borderRadius(3)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          Text(`🔥 ${artwork.likeCount + artwork.favoriteCount + artwork.commentCount}`)
            .fontSize(10).fontColor($r('app.color.text_hint'))
        }
      }
      .padding({ left: 4, right: 4, top: 6, bottom: 6 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(10)
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtworkDetailPage', params: { artworkId: artwork.id } });
    })
  }

  // ── 加载更多 ──

  @Builder
  buildFooter(): void {
    Column() {
      if (this.hasMore) {
        Button() {
          Text('↓ 加载更多').fontSize(13).fontColor($r('app.color.primary'))
        }
        .height(40).backgroundColor($r('app.color.accent_light')).borderRadius(20)
        .padding({ left: 20, right: 20 }).margin({ top: 16 })
        .onClick(() => {
          const next = this.displayCount + PAGE_SIZE;
          this.displayCount = Math.min(next, this.searchResult.artworks.length);
          this.hasMore = this.displayCount < this.searchResult.artworks.length;
        })
      } else if (this.searchResult.artworks.length > PAGE_SIZE) {
        Text('你已经到达世界尽头了~')
          .fontSize(12).fontColor($r('app.color.text_hint'))
          .padding({ top: 20 }).width('100%').textAlign(TextAlign.Center)
      }
    }
    .width('100%').alignItems(HorizontalAlign.Center)
  }

  // ── 搜索 ──

  private doSearch(): void {
    if (this.searchText.trim().length === 0) return;
    this.isSearching = true;
    this.displayCount = PAGE_SIZE;
    this.artworkService.searchArtworks(this.searchText.trim()).then((result) => {
      this.searchResult = result;
      this.hasMore = result.artworks.length > PAGE_SIZE;
      this.isSearching = false;
    });
  }
}
