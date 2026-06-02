/**
 * 搜索入口页
 *
 * 点击首页搜索栏 → 跳转到此页
 * 顶部：搜索框（输入时联想）+ 语音按钮
 * 下方：联想词列表 / 热搜推荐 + 换一换
 */
import router from '@ohos.router';
import { Artwork } from '../model/Artwork';
import { ArtworkService } from '../service/ArtworkService';
import { SearchService } from '../service/SearchService';
import { SpeechService } from '../service/SpeechService';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

@Entry
@Component
struct SearchEntryPage {
  @State private searchText: string = '';
  @State private suggestions: string[] = [];
  @State private hotArtworks: Artwork[] = [];
  @State private isLoading: boolean = true;
  @State private isListening: boolean = false;

  private artworkService = ArtworkService.getInstance();
  private searchService = SearchService.getInstance();
  private speechService = SpeechService.getInstance();
  private allCache: Artwork[] = [];

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.artworkService.fetchAllArtworks();
    this.allCache = this.artworkService.getAllArtworks();
    this.shufflePick();
    this.isLoading = false;
  }

  private shufflePick(): void {
    if (this.allCache.length === 0) {
      this.hotArtworks = [];
      return;
    }
    this.hotArtworks = shuffle(this.allCache).slice(0, 6);
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

        // 输入框
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
            if (value.trim().length > 0) {
              this.suggestions = this.searchService.getSearchSuggestions(value);
            } else {
              this.suggestions = [];
            }
          })
          .onSubmit(() => {
            if (this.searchText.trim().length > 0) {
              this.doSearch();
            }
          })

        // 语音按钮
        Button() {
          Text(this.isListening ? '🔴' : '🎤').fontSize(17)
        }
        .width(36).height(36)
        .backgroundColor(this.isListening ? $r('app.color.error') : $r('app.color.accent_light'))
        .borderRadius(18)
        .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
        .onClick(() => { this.handleVoiceClick(); })
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 8, bottom: 8 })

      // 联想词列表
      if (this.suggestions.length > 0) {
        Column() {
          ForEach(this.suggestions.slice(0, 8), (s: string) => {
            Row({ space: 8 }) {
              Text('🔍').fontSize(13).opacity(0.4)
              Text(s)
                .fontSize(14).fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.searchText = s;
              this.suggestions = [];
              this.doSearch();
            })
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.background_card'))
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }

      // 热搜推荐
      if (this.suggestions.length === 0) {
        if (this.isLoading) {
          LoadingProgress()
            .width(36).height(36).color($r('app.color.primary'))
            .margin({ top: 60 })
        } else {
          Scroll() {
            Column() {
              Row() {
                Text('🔥 热搜推荐')
                  .fontSize(16).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Bold)
                Blank()
                Text('🔄 换一换')
                  .fontSize(13).fontColor($r('app.color.primary'))
                  .onClick(() => { this.shufflePick(); })
              }
              .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })

              ForEach(this.hotArtworks, (artwork: Artwork, index: number) => {
                this.buildHotItem(artwork, index + 1)
              })
              Blank().height(40)
            }
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
        }
      } else {
        Blank()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private doSearch(): void {
    router.pushUrl({
      url: 'pages/SearchPage',
      params: { keyword: this.searchText.trim() }
    });
  }

  private async handleVoiceClick(): Promise<void> {
    if (this.isListening) {
      this.speechService.cancelListening();
      this.isListening = false;
      return;
    }
    const hasPermission = await this.checkMicPermission();
    if (!hasPermission) {
      promptAction.showToast({ message: '请先授予麦克风权限', duration: 2000 });
      return;
    }
    this.isListening = true;
    try {
      const result = await this.speechService.startListening();
      if (result && result.trim().length > 0) {
        this.searchText = result;
        this.doSearch();
      }
    } catch (_) {
      promptAction.showToast({ message: '语音识别失败', duration: 2000 });
    }
    this.isListening = false;
  }

  private async checkMicPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;
      const permission: Permissions = 'ohos.permission.MICROPHONE';
      const grantStatus = atManager.checkAccessTokenSync(context.applicationInfo.accessTokenId, permission);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (_) { return false; }
  }

  @Builder
  buildHotItem(artwork: Artwork, rank: number): void {
    Row({ space: 12 }) {
      Text(`${rank}`)
        .fontSize(18)
        .fontColor(rank <= 3 ? $r('app.color.primary') : $r('app.color.text_hint'))
        .fontWeight(FontWeight.Bold).width(24).textAlign(TextAlign.Center)
      Image(artwork.coverImage)
        .width(56).height(56).objectFit(ImageFit.Cover).borderRadius(8)
        .backgroundColor($r('app.color.shimmer_base'))
      Column({ space: 4 }) {
        Text(artwork.name)
          .fontSize(15).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 10 }) {
          Text(artwork.dynasty).fontSize(11).fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.accent_light')).borderRadius(4)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          Text(artwork.type).fontSize(11).fontColor($r('app.color.text_secondary'))
          Text(`🔥 ${artwork.likeCount + artwork.favoriteCount + artwork.commentCount}`)
            .fontSize(11).fontColor($r('app.color.text_hint'))
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtworkDetailPage', params: { artworkId: artwork.id } });
    })
  }
}
