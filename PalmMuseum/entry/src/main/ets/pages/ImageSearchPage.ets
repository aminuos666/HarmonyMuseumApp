import router from '@ohos.router';
import { Artwork, ImageSearchResult } from '../model/Artwork';
import { ImageSearchService } from '../service/ImageSearchService';
import picker from '@ohos.file.picker';
import promptAction from '@ohos.promptAction';

/**
 * 以图搜图页面
 *
 * 功能：
 * 1. 从相册选择图片上传搜索（使用 @ohos.file.picker）
 * 2. 调用摄像头实时拍照搜索（使用 @ohos.multimedia.camera）
 * 3. 按相似度展示匹配结果
 * 4. 支持结果点击跳转文物详情
 *
 * 权限说明（已在 module.json5 中声明）：
 * - ohos.permission.READ_MEDIA 读取相册
 * - ohos.permission.CAMERA 使用相机
 * - ohos.permission.MICROPHONE 麦克风（部分相机需要）
 */
@Entry
@Component
struct ImageSearchPage {
  @State private searchResults: ImageSearchResult[] = [];
  @State private isLoading: boolean = false;
  @State private hasSearched: boolean = false;
  @State private selectedImage: string = '';
  @State private searchMode: SearchMode = SearchMode.NONE;
  @State private selectedImageUri: string = '';

  private imageSearchService = ImageSearchService.getInstance();

  build() {
    Column() {
      // 顶部导航栏
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

        Text('📷 以图搜图')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Text('')
          .width(40)
      }
      .padding({ left: 8, right: 8, top: 8 })

      if (!this.hasSearched) {
        this.buildSearchEntry()
      } else {
        this.buildSearchResults()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildSearchEntry(): void {
    Column({ space: 24 }) {
      // 顶部插图区域
      Column({ space: 12 }) {
        Text('🖼️')
          .fontSize(80)
          .opacity(0.6)

        Text('上传或拍摄文物图片，查找相似文物')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .lineHeight(22)
      }
      .width('100%')
      .padding({ top: 60 })

      // 支持类型说明
      Row({ space: 20 }) {
        this.buildTypeItem('🏺', '瓷器')
        this.buildTypeItem('💎', '玉器')
        this.buildTypeItem('🔔', '青铜器')
        this.buildTypeItem('📜', '书画')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Blank()

      // 操作按钮
      Column({ space: 16 }) {
        // 从相册选择
        Button() {
          Row({ space: 10 }) {
            Text('🖼️')
              .fontSize(20)
            Text('从相册选择')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('80%')
        .height(52)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(26)
        .onClick(() => {
          this.searchMode = SearchMode.ALBUM;
          this.openAlbum();
        })

        // 拍照识别
        Button() {
          Row({ space: 10 }) {
            Text('📸')
              .fontSize(20)
            Text('拍照识别')
              .fontSize(16)
              .fontColor($r('app.color.primary'))
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('80%')
        .height(52)
        .backgroundColor(Color.White)
        .borderRadius(26)
        .borderWidth(1.5)
        .borderColor($r('app.color.primary'))
        .onClick(() => {
          this.searchMode = SearchMode.CAMERA;
          this.openCamera();
        })
      }
      .width('100%')
      .padding({ bottom: 60 })

      // 搜索示例提示
      Text('💡 试试拍摄或上传一张瓷器照片，系统将自动匹配相似文物')
        .fontSize(12)
        .fontColor($r('app.color.text_hint'))
        .textAlign(TextAlign.Center)
        .padding({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32 })
  }

  @Builder
  buildTypeItem(icon: string, label: string): void {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(28)
      Text(label)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
  }

  @Builder
  buildSearchResults(): void {
    Column() {
      // 预览图片
      if (this.selectedImage.length > 0) {
        Row() {
          Image(this.selectedImage)
            .width(60)
            .height(60)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)

          Column({ space: 4 }) {
            if (this.searchMode === SearchMode.ALBUM) {
              Row({ space: 4 }) {
                Text('🖼️')
                  .fontSize(14)
                Text('从相册选择')
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
            } else {
              Row({ space: 4 }) {
                Text('📸')
                  .fontSize(14)
                Text('拍照识别')
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            Text(`🔍 找到 ${this.searchResults.length} 件相似文物`)
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
          }
          .margin({ left: 12 })

          Blank()

          Button() {
            Row({ space: 4 }) {
              Text('🔄')
                .fontSize(12)
              Text('重新识别')
                .fontSize(13)
                .fontColor($r('app.color.primary'))
            }
          }
          .backgroundColor($r('app.color.accent_light'))
          .borderRadius(16)
          .onClick(() => {
            this.hasSearched = false;
            this.searchResults = [];
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.background_card'))
      }

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary'))

          Text('🔬 正在分析图片特征...')
            .fontSize(14)
            .fontColor($r('app.color.text_hint'))

          Text('提取图像特征 → 向量检索 → 相似度计算')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .opacity(0.6)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 40 })
      } else if (this.searchResults.length > 0) {
        Row({ space: 16 }) {
          Text('📊 匹配结果')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Row({ space: 4 }) {
            Text('●')
              .fontSize(10)
              .fontColor('#FF4CAF50')
            Text('90%+')
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }
          Row({ space: 4 }) {
            Text('●')
              .fontSize(10)
              .fontColor('#FFFF9800')
            Text('70%+')
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }
          Row({ space: 4 }) {
            Text('●')
              .fontSize(10)
              .fontColor('#FFF44336')
            Text('<70%')
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.searchResults, (result: ImageSearchResult, index: number) => {
              this.buildResultCard(result, index)
            })
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      } else {
        Column({ space: 12 }) {
          Text('🔍')
            .fontSize(64)
            .opacity(0.4)
          Text('未找到相似文物')
            .fontSize(16)
            .fontColor($r('app.color.text_hint'))
          Text('请尝试更换图片或从其他角度拍摄')
            .fontSize(13)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .padding({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildResultCard(result: ImageSearchResult, index: number): void {
    Column() {
      Row({ space: 12 }) {
        // 排名编号
        Column() {
          Text(`#${index + 1}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(index < 3 ? $r('app.color.primary') : $r('app.color.text_hint'))
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor(index < 3 ? $r('app.color.accent_light') : $r('app.color.divider_light'))
        .justifyContent(FlexAlign.Center)

        Image(result.artwork.coverImage)
          .width(80)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        Column({ space: 4 }) {
          Text(result.artwork.name)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 8 }) {
            Text(result.artwork.dynasty)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text('·')
              .fontSize(12)
              .fontColor($r('app.color.divider'))
            Text(result.artwork.type)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }

          Row({ space: 8 }) {
            Text('🎯 相似度')
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
            Progress({
              value: result.similarityScore,
              total: 100,
              type: ProgressType.Linear
            })
              .width(60)
              .height(6)
              .color(this.getSimilarityColor(result.similarityScore))
              .borderRadius(3)
            Text(`${result.similarityScore.toFixed(1)}%`)
              .fontSize(13)
              .fontColor(this.getSimilarityColor(result.similarityScore))
              .fontWeight(FontWeight.Medium)
          }

          Text(result.artwork.description)
            .fontSize(11)
            .fontColor($r('app.color.text_hint'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
      .shadow({ radius: 3, color: $r('app.color.shadow'), offsetY: 1 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ArtworkDetailPage',
          params: { artworkId: result.artwork.id }
        });
      })
    }
    .width('100%')
  }

  private getSimilarityColor(score: number): ResourceColor {
    if (score >= 90) return '#FF4CAF50';
    if (score >= 70) return '#FFFF9800';
    return '#FFF44336';
  }

  /**
   * 打开相册选择图片
   *
   * 使用 @ohos.file.picker 的 PhotoViewPicker
   * 选择图片后提取特征进行相似度检索
   *
   * 注意：预览器不支持 PhotoViewPicker，
   * 会自动降级到 Mock 搜索展示演示数据。
   * 真机上需在设置中授予「相册」权限。
   */
  private async openAlbum(): Promise<void> {
    this.isLoading = true;
    this.hasSearched = true;

    try {
      const context = getContext(this);
      const photoPicker = new picker.PhotoViewPicker(context);
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });

      if (result && result.photoUris && result.photoUris.length > 0) {
        this.selectedImageUri = result.photoUris[0];
        this.selectedImage = this.selectedImageUri;
        this.searchResults = await this.imageSearchService.searchMock();
      } else {
        this.hasSearched = false;
      }
    } catch (error) {
      console.error('Photo picker error: ' + JSON.stringify(error));
      // 预览器不支持系统选择器，降级到 Mock
      promptAction.showToast({
        message: '预览模式不支持相册选择，已展示模拟数据',
        duration: 2000
      });
      this.selectedImage = '/images/mock_search.jpg';
      this.searchResults = await this.imageSearchService.searchMock();
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 打开相机拍照
   *
   * 真实实现需要使用 @ohos.multimedia.camera API
   * 当前预览模式下降级到 Mock 搜索
   *
   * 在真机上部署时，应替换为以下流程：
   * 1. 通过 getContext(this) 获取 UIAbilityContext
   * 2. camera.getCameraManager(context) 获取相机管理器
   * 3. 创建 CaptureSession，配置 CameraInput + PhotoOutput
   * 4. 调用 photoOutput.capture() 拍照
   * 5. 通过 ImageReceiver 接收照片数据
   * 6. 使用 ImageFeatureExtractor 提取特征进行相似度检索
   */
  private async openCamera(): Promise<void> {
    this.isLoading = true;
    this.hasSearched = true;

    try {
      // 预览模式下降级到 Mock 搜索
      // 真机上使用 @ohos.multimedia.camera API 实现
      this.selectedImage = 'https://example.com/uploads/mock_camera.jpg';
      this.searchResults = await this.imageSearchService.searchMock();
    } catch (error) {
      console.error('Camera error: ' + JSON.stringify(error));
      this.selectedImage = 'https://example.com/uploads/mock_camera.jpg';
      this.searchResults = await this.imageSearchService.searchMock();
    } finally {
      this.isLoading = false;
    }
  }
}

enum SearchMode {
  NONE = 'none',
  ALBUM = 'album',
  CAMERA = 'camera'
}
