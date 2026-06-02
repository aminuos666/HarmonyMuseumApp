/**
 * 分类浏览页面
 *
 * 顶部：标签筛选（热度 + 年代 + 类型，支持多选组合）
 * 下方：文物网格，每页20件，加载更多
 *
 * 状态说明：
 *   从"发现页"进入 → 新建实例，默认按热度，无筛选
 *   跳到详情页再返回 → 同一实例，保持筛选状态
 *   退出到"发现页"再进入 → 新实例，恢复默认
 */
import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { ArtworkService } from '../service/ArtworkService';
import { SortType, Dynasty } from '../utils/Constants';
import { ArtworkCard } from '../component/ArtworkCard';

const PAGE_SIZE: number = 20;

@Component
export struct TagChip {
  @Prop label: string;
  @Prop selected: boolean;
  onToggle?: () => void;

  build() {
    Text(this.label)
      .fontSize(12)
      .fontColor(this.selected ? $r('app.color.primary') : $r('app.color.text_secondary'))
      .fontWeight(this.selected ? FontWeight.Medium : FontWeight.Regular)
      .backgroundColor(this.selected ? $r('app.color.accent_light') : $r('app.color.search_bar_background'))
      .borderRadius(14)
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .margin({ right: 6, bottom: 6 })
      .onClick(() => {
        if (this.onToggle) {
          this.onToggle();
        }
      })
  }
}

@Entry
@Component
struct BrowsePage {
  @State private artworks: Artwork[] = [];
  @State private allArtworks: Artwork[] = [];
  @State private displayCount: number = PAGE_SIZE;
  @State private hasMore: boolean = false;
  @State private isLoading: boolean = true;

  // 标签状态
  @State private heatSelected: boolean = true; // 默认按热度
  @State private selectedDynasties: Set<string> = new Set();
  @State private selectedTypes: Set<string> = new Set();

  // 可选标签组
  @State private dynasties: string[] = [];
  @State private types: string[] = [];

  private artworkService = ArtworkService.getInstance();

  aboutToAppear(): void {
    // 读取路由参数：从发现页"唐代风华"等跳转时预选年代
    const params = router.getParams() as Record<string, string>;
    if (params && params['dynasty']) {
      const dynastyStr: string = params['dynasty'] as string;
      const parts = dynastyStr.split(',').filter(s => s.length > 0);
      parts.forEach((d: string) => this.selectedDynasties.add(d));
    }
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.artworkService.fetchAllArtworks(SortType.DEFAULT);
    this.allArtworks = this.artworkService.getAllArtworks(SortType.DEFAULT);
    this.dynasties = this.artworkService.getDynasties().filter(d => d !== Dynasty.ALL);
    this.types = this.artworkService.getTypes();
    this.isLoading = false;
    this.applyFilter();
  }

  // ── 筛选逻辑 ──

  private toggleHeat(): void {
    this.heatSelected = !this.heatSelected;
    this.applyFilter();
  }

  private toggleDynasty(d: string): void {
    if (this.selectedDynasties.has(d)) {
      this.selectedDynasties.delete(d);
    } else {
      this.selectedDynasties.add(d);
    }
    this.applyFilter();
  }

  private toggleType(t: string): void {
    if (this.selectedTypes.has(t)) {
      this.selectedTypes.delete(t);
    } else {
      this.selectedTypes.add(t);
    }
    this.applyFilter();
  }

  private applyFilter(): void {
    let filtered = [...this.allArtworks];

    // 年代筛选 (OR within group)
    if (this.selectedDynasties.size > 0) {
      filtered = filtered.filter((a: Artwork) => this.selectedDynasties.has(a.dynasty));
    }
    // 类型筛选 (OR within group)
    if (this.selectedTypes.size > 0) {
      filtered = filtered.filter((a: Artwork) => this.selectedTypes.has(a.type));
    }

    // 排序
    if (this.heatSelected) {
      filtered.sort((a: Artwork, b: Artwork) =>
        (b.likeCount + b.favoriteCount + b.commentCount) -
        (a.likeCount + a.favoriteCount + a.commentCount));
    }

    this.artworks = filtered;
    this.displayCount = Math.min(PAGE_SIZE, filtered.length);
    this.hasMore = filtered.length > PAGE_SIZE;
  }

  /**
   * 加载更多
   */
  private loadMore(): void {
    const next = this.displayCount + PAGE_SIZE;
    this.displayCount = Math.min(next, this.artworks.length);
    this.hasMore = this.displayCount < this.artworks.length;
  }

  // ── 已选标签摘要 ──

  private hasAnyFilter(): boolean {
    return this.selectedDynasties.size > 0 || this.selectedTypes.size > 0 ||
      !this.heatSelected; // 切换排序也算活跃筛选
  }

  // ════════════ Build ════════════

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('←').fontSize(18).fontColor($r('app.color.text_primary'))
        }
        .width(36).height(36).backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(18)
        .onClick(() => { router.back(); })

        Text('分类浏览')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)

        Blank()

        // 重置按钮
        if (this.hasAnyFilter()) {
          Text('重置')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
            .padding({ left: 8, right: 8 })
            .onClick(() => {
              this.heatSelected = true;
              this.selectedDynasties.clear();
              this.selectedTypes.clear();
              this.applyFilter();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      // 标签筛选区
      this.buildTagSection()

      // 结果区
      if (this.isLoading) {
        LoadingProgress()
          .width(40).height(40).color($r('app.color.primary'))
          .margin({ top: 80 })
        Blank()
      } else if (this.artworks.length === 0) {
        this.buildEmptyState()
      } else {
        Scroll() {
          Column() {
            // 结果计数
            Row() {
              Text(`共 ${this.artworks.length} 件`)
                .fontSize(12).fontColor($r('app.color.text_hint'))
              Blank()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 8 })

            // 网格
            Grid() {
              ForEach(this.artworks.slice(0, this.displayCount), (artwork: Artwork) => {
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

            // 加载更多 / 到底
            this.buildFooter()
          }
          .padding({ bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  // ════════════ UI Builders ════════════

  @Builder
  buildTagSection(): void {
    Column({ space: 10 }) {
      // 热度
      Row({ space: 0 }) {
        Text('排序').fontSize(12).fontColor($r('app.color.text_hint')).margin({ right: 8 })
        TagChip({
          label: this.heatSelected ? '🔥 热度' : '默认',
          selected: this.heatSelected,
          onToggle: () => { this.toggleHeat(); }
        })
      }
      .width('100%')

      // 年代
      Row({ space: 0 }) {
        Text('年代').fontSize(12).fontColor($r('app.color.text_hint')).margin({ right: 8 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.dynasties, (d: string) => {
            TagChip({
              label: d,
              selected: this.selectedDynasties.has(d),
              onToggle: () => { this.toggleDynasty(d); }
            })
          })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 类型
      Row({ space: 0 }) {
        Text('类型').fontSize(12).fontColor($r('app.color.text_hint')).margin({ right: 8 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.types, (t: string) => {
            TagChip({
              label: t,
              selected: this.selectedTypes.has(t),
              onToggle: () => { this.toggleType(t); }
            })
          })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  buildFooter(): void {
    Column() {
      if (this.hasMore) {
        Button() {
          Text('↓ 加载更多')
            .fontSize(14).fontColor($r('app.color.primary'))
        }
        .height(44)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(22)
        .padding({ left: 24, right: 24 })
        .margin({ top: 16, bottom: 8 })
        .onClick(() => { this.loadMore(); })
      } else if (this.artworks.length > PAGE_SIZE) {
        Text('你已经到达世界尽头了~')
          .fontSize(13).fontColor($r('app.color.text_hint'))
          .padding({ top: 24, bottom: 24 })
          .width('100%').textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState(): void {
    Column({ space: 12 }) {
      Blank()
      Text('📭').fontSize(64).opacity(0.5)
      Text('没有匹配的文物').fontSize(16).fontColor($r('app.color.text_hint'))
      Text('试试调整筛选条件').fontSize(13).fontColor($r('app.color.text_hint'))
      Blank()
    }
    .width('100%').height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
