import router from '@ohos.router';
import { ImageSearchResult } from '../model/Artwork';
import { ImageSearchService } from '../service/ImageSearchService';
import { ArtworkService } from '../service/ArtworkService';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@ohos.base';

@Entry
@Component
struct ImageSearchPage {
  @State private searchResults: ImageSearchResult[] = [];
  @State private isLoading: boolean = false;
  @State private hasSearched: boolean = false;
  @State private selectedImageUri: string = '';
  @State private searchMode: SearchMode = SearchMode.NONE;
  @State private errorMessage: string = '';
  @State private isBackendFallback: boolean = false;

  private imageSearchService = ImageSearchService.getInstance();
  private artworkService = ArtworkService.getInstance();

  build() {
    Column() {
      Row() {
        Button() {
          Text('←').fontSize(20).fontColor($r('app.color.text_primary'))
        }
        .width(40).height(40)
        .backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(20)
        .onClick(() => { router.back(); })
        Blank()
        Text('📷 以图搜图').fontSize(18).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
        Blank()
        Text('').width(40)
      }
      .padding({ left: 8, right: 8, top: 8 })

      if (!this.hasSearched) {
        this.buildSearchEntry()
      } else {
        this.buildSearchResults()
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildSearchEntry(): void {
    Column({ space: 24 }) {
      Column({ space: 12 }) {
        Text('🖼️').fontSize(80).opacity(0.6)
        Text('上传或拍摄陶瓷/文物图片，智能匹配相似文物')
          .fontSize(15).fontColor($r('app.color.text_secondary')).textAlign(TextAlign.Center).lineHeight(22)
      }
      .width('100%').padding({ top: 60 })
      Row({ space: 20 }) {
        this.buildTypeItem('🏺', '瓷器')
        this.buildTypeItem('💎', '玉器')
        this.buildTypeItem('🔔', '青铜器')
        this.buildTypeItem('📜', '书画')
      }
      .width('100%').justifyContent(FlexAlign.Center)
      Blank()
      Column({ space: 16 }) {
        Button() {
          Row({ space: 10 }) {
            Text('🖼️').fontSize(20)
            Text('从相册选择').fontSize(16).fontColor(Color.White)
          }.justifyContent(FlexAlign.Center)
        }
        .width('80%').height(52)
        .backgroundColor($r('app.color.primary')).borderRadius(26)
        .onClick(() => { this.searchMode = SearchMode.ALBUM; this.openAlbum(); })

        Button() {
          Row({ space: 10 }) {
            Text('📸').fontSize(20)
            Text('拍照识别').fontSize(16).fontColor($r('app.color.primary'))
          }.justifyContent(FlexAlign.Center)
        }
        .width('80%').height(52)
        .backgroundColor(Color.White).borderRadius(26)
        .borderWidth(1.5).borderColor($r('app.color.primary'))
        .onClick(() => { this.searchMode = SearchMode.CAMERA; this.openCamera(); })
      }
      .width('100%').padding({ bottom: 60 })
    }
    .width('100%').height('100%').padding({ left: 32, right: 32 })
  }

  @Builder
  buildTypeItem(icon: string, label: string): void {
    Column({ space: 4 }) {
      Text(icon).fontSize(28)
      Text(label).fontSize(12).fontColor($r('app.color.text_secondary'))
    }
  }

  @Builder
  buildSearchResults(): void {
    Column() {
      Row() {
        Image(this.selectedImageUri).width(60).height(60).objectFit(ImageFit.Cover).borderRadius(8)
          .backgroundColor($r('app.color.shimmer_base'))
        Column({ space: 4 }) {
          Row({ space: 4 }) {
            Text(this.searchMode === SearchMode.ALBUM ? '🖼️' : '📸').fontSize(14)
            Text(this.searchMode === SearchMode.ALBUM ? '从相册选择' : '拍照识别')
              .fontSize(13).fontColor($r('app.color.text_secondary'))
          }
          if (this.isBackendFallback) {
            Text('⚠️ 后端不可用，展示模拟结果').fontSize(12).fontColor($r('app.color.warning'))
          } else {
            Text(`🔍 找到 ${this.searchResults.length} 件相似文物`).fontSize(12).fontColor($r('app.color.text_hint'))
          }
        }.margin({ left: 12 })
        Blank()
        Button() {
          Row({ space: 4 }) {
            Text('🔄').fontSize(12)
            Text('重新识别').fontSize(13).fontColor($r('app.color.primary'))
          }
        }
        .backgroundColor($r('app.color.accent_light')).borderRadius(16)
        .onClick(() => {
          this.hasSearched = false; this.searchResults = [];
          this.selectedImageUri = ''; this.errorMessage = ''; this.isBackendFallback = false;
        })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.background_card'))

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress().width(48).height(48).color($r('app.color.primary'))
          Text('🔬 正在提取图像特征...').fontSize(14).fontColor($r('app.color.text_hint'))
        }.width('100%').height(200).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).padding({ top: 40 })
      } else if (this.searchResults.length > 0) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.searchResults, (result: ImageSearchResult, index: number) => {
              Column() {
                Row({ space: 12 }) {
                  Column() {
                    Text(`#${index + 1}`).fontSize(16).fontWeight(FontWeight.Bold)
                      .fontColor(index < 3 ? $r('app.color.primary') : $r('app.color.text_hint'))
                  }
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor(index < 3 ? $r('app.color.accent_light') : $r('app.color.divider_light'))
                  .justifyContent(FlexAlign.Center)
                  Image(result.artwork.coverImage).width(80).height(80).objectFit(ImageFit.Cover).borderRadius(8)
                    .backgroundColor($r('app.color.shimmer_base'))
                  Column({ space: 4 }) {
                    Text(result.artwork.name).fontSize(15).fontColor($r('app.color.text_primary'))
                      .fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row({ space: 8 }) {
                      Text(result.artwork.dynasty).fontSize(12).fontColor($r('app.color.text_secondary'))
                      Text('·').fontSize(12).fontColor($r('app.color.divider'))
                      Text(result.artwork.type).fontSize(12).fontColor($r('app.color.text_secondary'))
                    }
                    Row({ space: 8 }) {
                      Text('🎯 相似度').fontSize(12).fontColor($r('app.color.text_hint'))
                      Progress({ value: result.similarityScore, total: 100, type: ProgressType.Linear })
                        .width(60).height(6).color(this.getSimilarityColor(result.similarityScore)).borderRadius(3)
                      Text(`${result.similarityScore.toFixed(1)}%`).fontSize(13)
                        .fontColor(this.getSimilarityColor(result.similarityScore)).fontWeight(FontWeight.Medium)
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start).height(80).justifyContent(FlexAlign.Center)
                }
                .width('100%').padding(12)
                .backgroundColor($r('app.color.background_card')).borderRadius(12)
                .shadow({ radius: 3, color: $r('app.color.shadow'), offsetY: 1 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/ArtworkDetailPage', params: { artworkId: result.artwork.id } });
                })
              }
            }, (result: ImageSearchResult): string => result.artwork.id)
          }.padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%')
  }

  private getSimilarityColor(score: number): ResourceColor {
    if (score >= 80) return '#FF4CAF50';
    if (score >= 50) return '#FFFF9800';
    return '#FFF44336';
  }

  private async openAlbum(): Promise<void> {
    this.isLoading = true;
    this.hasSearched = true;
    this.errorMessage = '';
    this.isBackendFallback = false;
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(options);
      if (result && result.photoUris && result.photoUris.length > 0) {
        this.selectedImageUri = result.photoUris[0];
        const uploadUri = await this.copyToCache(this.selectedImageUri);
        this.searchResults = await this.imageSearchService.searchByImageUri(uploadUri);
      } else {
        this.hasSearched = false;
      }
    } catch (error) {
      console.error('Photo picker error: ' + JSON.stringify(error));
      this.isBackendFallback = true;
      promptAction.showToast({ message: '预览模式或后端不可用，已展示模拟数据', duration: 2000 });
      this.selectedImageUri = '';
      this.searchResults = await this.imageSearchService.searchMock();
    } finally {
      this.isLoading = false;
    }
  }

  private async openCamera(): Promise<void> {
    this.isLoading = true;
    this.hasSearched = true;
    this.errorMessage = '';
    this.isBackendFallback = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pickerResult = await cameraPicker.pick(context,
        [cameraPicker.PickerMediaType.PHOTO],
        { cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK });
      if (pickerResult?.resultUri) {
        this.selectedImageUri = pickerResult.resultUri;
        const uploadUri = await this.copyToCache(this.selectedImageUri);
        this.searchResults = await this.imageSearchService.searchByImageUri(uploadUri);
        return;
      }
    } catch (error) {
      console.error('Camera error: ' + JSON.stringify(error));
    }
    this.isLoading = false;
    console.error('Camera unavailable');
    this.hasSearched = false;
    promptAction.showToast({ message: '相机不可用，请从相册选择', duration: 2000 });
  }

  private async copyToCache(uri: string): Promise<string> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const tempPath = `${ctx.cacheDir}/isearch_${Date.now()}.jpg`;
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      fileIo.copyFileSync(file.fd, tempPath);
      fileIo.closeSync(file);
      return tempPath;
    } catch (e) {
      return uri;
    }
  }
}

enum SearchMode {
  NONE = 'none',
  ALBUM = 'album',
  CAMERA = 'camera'
}
