import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { SearchService } from '../service/SearchService';
import { SpeechService } from '../service/SpeechService';
import { ArtworkService } from '../service/ArtworkService';
import { ImageSearchService } from '../service/ImageSearchService';
import { Dynasty } from '../utils/Constants';
import { ArtworkCard } from '../component/ArtworkCard';

@Component
export struct ExploreTab {
  @State private searchText: string = '';
  @State private hotSearches: string[] = [
    '青花瓷', '汝窑', '粉彩', '唐三彩', '斗彩',
    '梅瓶', '雍正', '乾隆', '景德镇', '宋代'
  ];
  @State private isListening: boolean = false;
  @State private categoryArtworks: Artwork[] = [];
  @State private selectedDynasty: string = '全部';
  @State private exploreSections: ExploreSection[] = [];
  @State private isInitialized: boolean = false;

  private searchService = SearchService.getInstance();
  private speechService = SpeechService.getInstance();
  private artworkService = ArtworkService.getInstance();
  private imageSearchService = ImageSearchService.getInstance();

  aboutToAppear(): void {
    // 先从缓存加载
    this.buildSections();
    // 异步从后端 API 加载最新数据
    this.artworkService.fetchArtworks().then((list) => {
      if (list.length > 0) {
        this.buildSections();
      }
    });
  }

  private buildSections(): void {
    const all = this.artworkService.getArtworks();
    if (all.length === 0) {
      return;
    }
    this.categoryArtworks = all;
    this.exploreSections = [
      new ExploreSection('热门推荐', all.slice(0, 6)),
      new ExploreSection('唐代风华', all.filter(a => a.dynasty === Dynasty.TANG).slice(0, 6)),
      new ExploreSection('宋韵流芳', all.filter(a => a.dynasty === Dynasty.SONG).slice(0, 6)),
      new ExploreSection('明清精粹', all.filter(a => a.dynasty === Dynasty.MING || a.dynasty === Dynasty.QING).slice(0, 6)),
    ];
    this.isInitialized = true;
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('发现')
          .fontSize(24)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)
        Blank()
        // 以图搜图快捷入口
        Button() {
          Row({ space: 4 }) {
            Text('📷')
              .fontSize(16)
            Text('识图')
              .fontSize(12)
              .fontColor($r('app.color.primary'))
          }
        }
        .height(32)
        .backgroundColor($r('app.color.accent_light'))
        .borderRadius(16)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ImageSearchPage' });
        })
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      // 搜索栏
      Row({ space: 8 }) {
        Row({ space: 6 }) {
          Text('🔍')
            .fontSize(16)
          TextInput({
            placeholder: '搜索文物名称、朝代、关键字...',
            text: this.searchText
          })
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .placeholderColor($r('app.color.text_hint'))
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => {
              this.searchText = value;
            })
            .onSubmit(() => {
              if (this.searchText.length > 0) {
                router.pushUrl({
                  url: 'pages/SearchPage',
                  params: { keyword: this.searchText }
                });
                this.searchText = '';
              }
            })
        }
        .padding({ left: 12, right: 4 })
        .backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(20)
        .layoutWeight(1)
        .height(40)

        // 语音搜索
        Button() {
          Text('🎤')
            .fontSize(18)
        }
        .width(40)
        .height(40)
        .backgroundColor(this.isListening ?
          $r('app.color.error') : $r('app.color.primary'))
        .borderRadius(20)
        .onClick(async () => {
          this.isListening = true;
          try {
            const result = await this.speechService.startListening();
            if (result && result.length > 0) {
              router.pushUrl({
                url: 'pages/SearchPage',
                params: { keyword: result }
              });
            }
          } catch (e) {
            console.error('Voice search error');
          }
          this.isListening = false;
        })
      }
      .padding({ left: 16, right: 16, bottom: 8 })

      if (!this.isInitialized) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color($r('app.color.primary'))
          .margin({ top: 60 })
      } else {
        Scroll() {
          Column({ space: 20 }) {
            // 热门搜索标签
            this.buildHotSearches()

            // 功能快捷入口
            this.buildQuickActions()

            // 分类探索区块
            ForEach(this.exploreSections, (section: ExploreSection) => {
              this.buildSection(section)
            })
          }
          .padding({ left: 16, right: 16, bottom: 80 })
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
  buildHotSearches(): void {
    Column({ space: 10 }) {
      Row() {
        Text('🔥 热门搜索')
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('📋 更多 >')
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.hotSearches, (keyword: string) => {
          Text(keyword)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(16)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .margin({ bottom: 6, right: 6 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/SearchPage',
                params: { keyword: keyword }
              });
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
  }

  @Builder
  buildQuickActions(): void {
    Row({ space: 12 }) {
      // 以图搜图
      this.buildActionItem('📷', '以图搜图', () => {
        router.pushUrl({ url: 'pages/ImageSearchPage' });
      })
      // 语音搜索
      this.buildActionItem('🎤', '语音搜索', async () => {
        this.isListening = true;
        try {
          const result = await this.speechService.startListening();
          if (result && result.length > 0) {
            router.pushUrl({
              url: 'pages/SearchPage',
              params: { keyword: result }
            });
          }
        } catch (e) {
          console.error('Voice search error');
        }
        this.isListening = false;
      })
      // 语音问答
      this.buildActionItem('💬', '语音问答', () => {
        router.pushUrl({ url: 'pages/SearchPage' });
      })
      // 分类浏览
      this.buildActionItem('🏛️', '分类浏览', () => {})
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder
  buildActionItem(icon: string, label: string, onClick: () => void): void {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(24)
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { onClick(); })
  }

  @Builder
  buildSection(section: ExploreSection): void {
    Column({ space: 10 }) {
      // 区块标题
      Row() {
        Text(section.title)
          .fontSize(17)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('查看全部 >')
          .fontSize(12)
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SearchPage',
              params: { keyword: section.title }
            });
          })
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      if (section.artworks.length > 0) {
        // 横向滑动展示
        Scroll() {
          Row({ space: 12 }) {
            ForEach(section.artworks, (artwork: Artwork) => {
              Column({ space: 6 }) {
                Image(artwork.coverImage)
                  .width(140)
                  .height(160)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .backgroundColor($r('app.color.shimmer_base'))

                Text(artwork.name)
                  .fontSize(13)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(140)

                Text(`${artwork.dynasty} · ${artwork.type}`)
                  .fontSize(11)
                  .fontColor($r('app.color.text_hint'))
                  .maxLines(1)
                  .width(140)
              }
              .alignItems(HorizontalAlign.Start)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/ArtworkDetailPage',
                  params: { artworkId: artwork.id }
                });
              })
            })
          }
          .padding({ left: 4, right: 4 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(220)
      } else {
        Text('暂无内容')
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .padding({ left: 4, top: 8 })
      }
    }
    .width('100%')
  }
}

class ExploreSection {
  title: string = '';
  artworks: Artwork[] = [];

  constructor(title: string, artworks: Artwork[]) {
    this.title = title;
    this.artworks = artworks;
  }
}
