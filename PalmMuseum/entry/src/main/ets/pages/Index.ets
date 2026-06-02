import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { ArtworkService } from '../service/ArtworkService';
import { SortType, Dynasty } from '../utils/Constants';
import { ArtworkCard } from '../component/ArtworkCard';
import { SearchBar } from '../component/SearchBar';

const PAGE_SIZE: number = 20;

class DailyRecommendation {
  artwork: Artwork | null = null;
}

/**
 * Fisher-Yates 洗牌
 */
function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

/**
 * 对 20 件藏品排序（客户端排序，不请求后端）
 */
function sortArtworks(list: Artwork[], sortType: SortType): Artwork[] {
  const sorted = [...list];
  switch (sortType) {
    case SortType.POPULAR:
      sorted.sort((a, b) =>
        (b.likeCount + b.favoriteCount + b.commentCount) -
        (a.likeCount + a.favoriteCount + a.commentCount));
      break;
    case SortType.DYNASTY:
      sorted.sort((a, b) => {
        const order = [Dynasty.TANG, Dynasty.SONG, Dynasty.YUAN, Dynasty.MING, Dynasty.QING];
        return order.indexOf(a.dynasty) - order.indexOf(b.dynasty);
      });
      break;
    case SortType.TYPE:
      sorted.sort((a, b) => a.type.localeCompare(b.type));
      break;
    default:
      break;
  }
  return sorted;
}

@Component
export struct Index {
  @State private artworks: Artwork[] = [];
  @State private currentSort: SortType = SortType.DEFAULT;
  @State private isRefreshing: boolean = false;
  @State private showDaily: boolean = true;
  @State private dailyRec: DailyRecommendation = new DailyRecommendation();

  private artworkService = ArtworkService.getInstance();
  private allItems: Artwork[] = []; // 全量缓存，用于随机抽取

  aboutToAppear(): void {
    this.loadFromCache();
    this.refreshFromBackend(false);
  }

  // ── 从缓存加载 + 随机 20 ──

  private loadFromCache(): void {
    this.allItems = this.artworkService.getAllArtworks(SortType.DEFAULT);
    this.pickRandom();

    const rec = this.artworkService.getDailyRecommendation();
    if (rec) {
      this.dailyRec.artwork = rec;
    }
  }

  private pickRandom(): void {
    if (this.allItems.length === 0) {
      this.artworks = [];
      return;
    }
    const shuffled = shuffle(this.allItems);
    const picked = shuffled.slice(0, Math.min(PAGE_SIZE, shuffled.length));
    // 刷新后完全随机，不应用排序
    this.artworks = picked;
  }

  // ── 从后端刷新 ──

  private async refreshFromBackend(showLoading: boolean): Promise<void> {
    if (showLoading) {
      this.isRefreshing = true;
    }

    await this.artworkService.fetchAllArtworks();

    const rec = await this.artworkService.fetchDailyRecommendation();
    if (rec) {
      this.dailyRec.artwork = rec;
    }

    this.allItems = this.artworkService.getAllArtworks(SortType.DEFAULT);
    this.currentSort = SortType.DEFAULT; // 刷新后重置排序
    this.pickRandom();
    this.isRefreshing = false;
  }

  // ── 排序切换（仅对当前 20 件重排） ──

  private onSortChange(sort: SortType): void {
    this.currentSort = sort;
    this.artworks = sortArtworks(this.artworks, sort);
  }

  // ── 下拉刷新 ──

  private async handleRefresh(): Promise<void> {
    await this.refreshFromBackend(true);
  }

  // ════════════ Build ════════════

  build() {
    Column() {
      // 品牌头
      Row() {
        Column({ space: 2 }) {
          Text('掌上博物馆')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('沉浸式文物鉴赏')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor($r('app.color.background'))

      // 排序 + 搜索
      this.buildSortPanel()

      // 日推
      if (this.showDaily && this.dailyRec.artwork) {
        this.buildDailyCard()
      }

      // 文物列表
      if (this.artworks.length > 0) {
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              Row() {
                Text('馆藏精选')
                  .fontSize(14).fontColor($r('app.color.text_secondary')).fontWeight(FontWeight.Medium)
                Blank()
                Text(`${this.artworks.length} 件`)
                  .fontSize(12).fontColor($r('app.color.text_hint'))
              }
              .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 })

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
              .columnsGap(12)
              .rowsGap(12)
              .padding({ left: 16, right: 16 })
            }
            .padding({ bottom: 80 })
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .height('100%')
        }
        .onRefreshing(() => {
          this.isRefreshing = true;
          this.handleRefresh();
        })
        .refreshOffset(64)
        .layoutWeight(1)
      } else {
        this.buildEmptyState()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  // ════════════ UI Builders ════════════

  @Builder
  buildSortPanel(): void {
    Column() {
      Row({ space: 8 }) {
        Text('排序').fontSize(12).fontColor($r('app.color.text_hint')).fontWeight(FontWeight.Medium)
        Row({ space: 6 }) {
          Button() {
            Row({ space: 3 }) {
              Text(this.currentSort === SortType.POPULAR ? '✅' : '🔥').fontSize(13)
              Text('热度').fontSize(12)
                .fontColor(this.currentSort === SortType.POPULAR ?
                  $r('app.color.primary') : $r('app.color.text_secondary'))
            }
          }
          .height(30)
          .backgroundColor(this.currentSort === SortType.POPULAR ?
            $r('app.color.accent_light') : $r('app.color.search_bar_background'))
          .borderRadius(15).padding({ left: 10, right: 10 })
          .onClick(() => { this.onSortChange(SortType.POPULAR); })

          Button() {
            Row({ space: 3 }) {
              Text(this.currentSort === SortType.DYNASTY ? '✅' : '📅').fontSize(13)
              Text('年代').fontSize(12)
                .fontColor(this.currentSort === SortType.DYNASTY ?
                  $r('app.color.primary') : $r('app.color.text_secondary'))
            }
          }
          .height(30)
          .backgroundColor(this.currentSort === SortType.DYNASTY ?
            $r('app.color.accent_light') : $r('app.color.search_bar_background'))
          .borderRadius(15).padding({ left: 10, right: 10 })
          .onClick(() => { this.onSortChange(SortType.DYNASTY); })

          Button() {
            Row({ space: 3 }) {
              Text(this.currentSort === SortType.TYPE ? '✅' : '🏷️').fontSize(13)
              Text('类型').fontSize(12)
                .fontColor(this.currentSort === SortType.TYPE ?
                  $r('app.color.primary') : $r('app.color.text_secondary'))
            }
          }
          .height(30)
          .backgroundColor(this.currentSort === SortType.TYPE ?
            $r('app.color.accent_light') : $r('app.color.search_bar_background'))
          .borderRadius(15).padding({ left: 10, right: 10 })
          .onClick(() => { this.onSortChange(SortType.TYPE); })
        }
      }
      .width('100%')

      Row({ space: 8 }) {
        SearchBar({
          showVoiceButton: false,
          onTap: () => {
            router.pushUrl({ url: 'pages/SearchEntryPage' });
          }
        })
        Button() {
          Text('📷').fontSize(18)
        }
        .width(40).height(40)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(20)
        .onClick(() => { router.pushUrl({ url: 'pages/ImageSearchPage' }); })
      }
      .width('100%').margin({ top: 8 })
    }
    .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  buildDailyCard(): void {
    Column() {
      Row({ space: 12 }) {
        Image(this.dailyRec.artwork?.coverImage || '')
          .width(100).height(120).objectFit(ImageFit.Cover).borderRadius(8)
          .backgroundColor($r('app.color.shimmer_base'))

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text('🌟').fontSize(13)
            Text('今日推荐').fontSize(12).fontColor($r('app.color.primary')).fontWeight(FontWeight.Bold)
          }
          Text(this.dailyRec.artwork?.name || '')
            .fontSize(17).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Bold)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Row({ space: 8 }) {
            Text(this.dailyRec.artwork?.dynasty || '')
              .fontSize(12).fontColor($r('app.color.primary'))
              .backgroundColor($r('app.color.accent_light')).borderRadius(4)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            Text(this.dailyRec.artwork?.type || '')
              .fontSize(12).fontColor($r('app.color.text_secondary'))
          }
          Text(this.dailyRec.artwork?.description || '')
            .fontSize(12).fontColor($r('app.color.text_hint'))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(18)
          Button() {
            Text('👀 去看看').fontSize(13).fontColor(Color.White)
          }
          .height(32).backgroundColor($r('app.color.primary')).borderRadius(16)
          .padding({ left: 14, right: 14 }).margin({ top: 4 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ArtworkDetailPage',
              params: { artworkId: this.dailyRec.artwork?.id }
            });
          })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start).height(120)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%').padding(14)
      .backgroundColor($r('app.color.background_card')).borderRadius(12)
      .shadow({ radius: 8, color: $r('app.color.shadow'), offsetY: 3 })
      .margin({ left: 16, right: 16, top: 4 })

      Row() {
        Blank()
        Text('✕ 今日不再显示').fontSize(11).fontColor($r('app.color.text_hint'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width('100%').height(28)
      .onClick(() => { this.showDaily = false; })
    }
    .width('100%').padding({ bottom: 4 })
  }

  @Builder
  buildEmptyState(): void {
    Column({ space: 12 }) {
      Blank()
      Text('📭').fontSize(64).opacity(0.5)
      Text('暂无文物数据').fontSize(16).fontColor($r('app.color.text_hint'))
      Blank()
    }
    .width('100%').height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
