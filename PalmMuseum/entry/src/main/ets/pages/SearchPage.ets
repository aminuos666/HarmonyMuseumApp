import router from '@ohos.router';
import { Artwork, ArtworkSearchResult } from '../model/Artwork';
import { SearchService } from '../service/SearchService';
import { ArtworkService } from '../service/ArtworkService';
import { SpeechService } from '../service/SpeechService';
import { ArtworkCard } from '../component/ArtworkCard';

@Entry
@Component
struct SearchPage {
  @State private searchText: string = '';
  @State private searchResult: ArtworkSearchResult = new ArtworkSearchResult();
  @State private suggestions: string[] = [];
  @State private hotSearches: string[] = [
    '青花瓷', '汝窑', '粉彩', '唐三彩', '斗彩',
    '梅瓶', '雍正', '乾隆', '景德镇', '宋代'
  ];
  @State private isSearching: boolean = false;
  @State private isListening: boolean = false;
  @State private showSuggestions: boolean = false;
  @State private selectedCategory: string = '全部';

  private searchService = SearchService.getInstance();
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
          Text('◀')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        TextInput({
          placeholder: '搜索文物名称、朝代、关键字...',
          text: this.searchText
        })
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .placeholderColor($r('app.color.text_hint'))
          .backgroundColor($r('app.color.search_bar_background'))
          .borderRadius(20)
          .padding({ left: 16 })
          .onChange((value: string) => {
            this.searchText = value;
            if (value.length > 0) {
              this.suggestions = this.searchService.getSearchSuggestions(value);
              this.showSuggestions = this.suggestions.length > 0;
            } else {
              this.suggestions = [];
              this.showSuggestions = false;
            }
          })
          .onSubmit(() => {
            this.doSearch();
          })

        // 语音搜索
        Button() {
          Text('🎤')
            .fontSize(22)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(20)
        .onClick(async () => {
          this.isListening = true;
          try {
            const result = await this.speechService.startListening();
            this.searchText = result;
            this.doSearch();
          } catch (e) {
            console.error('Voice search error');
          }
          this.isListening = false;
        })
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      // 搜索建议
      if (this.showSuggestions) {
        Column() {
          ForEach(this.suggestions, (suggestion: string) => {
            Text(suggestion)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .width('100%')
              .onClick(() => {
                this.searchText = suggestion;
                this.showSuggestions = false;
                this.doSearch();
              })
          })
        }
        .backgroundColor($r('app.color.background_card'))
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }

      if (this.isSearching) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color($r('app.color.primary'))
          .margin({ top: 40 })
      } else if (this.searchResult.artworks.length > 0) {
        // 搜索结果
        Row() {
          Text(`找到 ${this.searchResult.totalCount} 件相关文物`)
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
          Blank()
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })

        // 分类筛选
        Scroll() {
          Row({ space: 8 }) {
            ForEach(['全部', ...this.searchResult.relatedTags.slice(0, 8)],
              (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .fontColor(this.selectedCategory === tag ?
                    $r('app.color.text_on_primary') : $r('app.color.text_secondary'))
                  .backgroundColor(this.selectedCategory === tag ?
                    $r('app.color.primary') : $r('app.color.background_card'))
                  .borderRadius(14)
                  .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                  .onClick(() => {
                    this.selectedCategory = tag;
                  })
              })
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(36)

        // 结果列表
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.searchResult.artworks, (artwork: Artwork) => {
              ArtworkCard({ artwork: artwork })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/ArtworkDetailPage',
                    params: { artworkId: artwork.id }
                  });
                })
            })
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      } else if (this.searchText.length > 0) {
        // 无结果
        Column({ space: 12 }) {
          Text('🔍')
            .fontSize(64)
            .opacity(0.4)
          Text('未找到相关文物')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
          Text('试试其他关键词，如"青花"、"宋代"、"汝窑"等')
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .padding({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else {
        // 初始状态 - 热门搜索
        Column({ space: 12 }) {
          Text('热门搜索')
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.hotSearches, (keyword: string) => {
              Text(keyword)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .backgroundColor($r('app.color.background_card'))
                .borderRadius(16)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .onClick(() => {
                  this.searchText = keyword;
                  this.doSearch();
                })
            })
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 24 })

        // 语音搜索引导
        Column({ space: 8 }) {
          Divider().color($r('app.color.divider')).margin({ top: 24, bottom: 8 })
          Text('或试试语音搜索')
            .fontSize(14)
            .fontColor($r('app.color.text_hint'))
          Row({ space: 8 }) {
            Text('🎤')
              .fontSize(20)
            Text('按住说话，语音搜索文物')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .padding(12)
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(12)
          .onClick(async () => {
            this.isListening = true;
            const result = await this.speechService.startListening();
            this.searchText = result;
            this.doSearch();
            this.isListening = false;
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private doSearch(): void {
    this.isSearching = true;
    this.showSuggestions = false;
    // 先从本地缓存搜索
    this.searchResult = this.searchService.search(this.searchText);
    // 异步从后端 API 搜索
    this.artworkService.searchArtworks(this.searchText).then((result) => {
      if (result.artworks.length > 0) {
        this.searchResult = result;
      }
      this.isSearching = false;
    });
    // 没有后端结果时，使用本地结果并结束加载
    if (this.searchResult.artworks.length > 0) {
      this.isSearching = false;
    }
  }
}
