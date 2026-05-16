import router from '@ohos.router';
import { Artwork, ArtworkImage } from '../model/Artwork';
import { Comment } from '../model/Comment';
import { ArtworkService } from '../service/ArtworkService';
import { SpeechService } from '../service/SpeechService';
import { ImageViewer } from '../component/ImageViewer';
import { AudioPlayer } from '../component/AudioPlayer';
import { EmptyView } from '../component/ArtworkCard';

class SectionTabItem {
  label: string = '';
  value: SectionTab = SectionTab.INFO;

  constructor(label: string, value: SectionTab) {
    this.label = label;
    this.value = value;
  }
}

@Entry
@Component
struct ArtworkDetailPage {
  @State private artwork: Artwork = new Artwork();
  @State private selectedSection: SectionTab = SectionTab.INFO;
  @State private isLiked: boolean = false;
  @State private isFavorited: boolean = false;
  @State private likeCount: number = 0;
  @State private favoriteCount: number = 0;
  @State private comments: Comment[] = [];
  @State private isPlayingAudio: boolean = false;
  @State private showCommentInput: boolean = false;
  @State private commentText: string = '';
  @State private showFullImage: boolean = false;
  @State private currentImageIndex: number = 0;

  private artworkId: string = '';
  private artworkService = ArtworkService.getInstance();
  private speechService = SpeechService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.artworkId = params['artworkId'] || '';
    // 先从缓存加载
    this.loadFromCache();
    // 异步从后端 API 加载最新数据
    if (this.artworkId) {
      this.artworkService.fetchArtworkById(this.artworkId).then((artwork) => {
        if (artwork) {
          this.applyArtworkData(artwork);
        }
      });
      this.artworkService.fetchComments(this.artworkId).then((comments) => {
        this.comments = comments;
      });
    }
  }

  private loadFromCache(): void {
    const result = this.artworkService.getArtworkById(this.artworkId);
    if (result) {
      this.applyArtworkData(result);
    }
  }

  private applyArtworkData(artwork: Artwork): void {
    this.artwork = artwork;
    this.isLiked = artwork.isLiked;
    this.isFavorited = artwork.isFavorited;
    this.likeCount = artwork.likeCount;
    this.favoriteCount = artwork.favoriteCount;
    // 记录浏览历史（略，由后端处理）
  }

  build() {
    Column() {
      if (!this.artwork) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color($r('app.color.primary'))
      } else {
        Scroll() {
          Column() {
            // 大图区
            this.buildImageHeader()

            // 基本信息
            this.buildBasicInfo()

            // 交互按钮
            this.buildActionButtons()

            // 分类标签
            this.buildSectionTabs()

            // 内容区
            this.buildSectionContent()

            // 评论区域
            this.buildCommentSection()

            // 底部间距
            Blank().height(80)
          }
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
  buildImageHeader(): void {
    Stack() {
      // 主图
      Image(this.artwork?.coverImage || '')
        .width('100%')
        .height(360)
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.showFullImage = true;
        })

      // 渐变遮罩
      Column()
        .width('100%')
        .height(120)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#00000000', 0], ['#99000000', 1]]
        })
        .position({ bottom: 0 })

      // 返回按钮
      Button() {
        Text('◀')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .position({ top: 40, left: 16 })
      .onClick(() => {
        router.back();
      })

      // 多图指示器
      if ((this.artwork?.images.length || 0) > 1) {
        Row({ space: 6 }) {
          ForEach(this.artwork?.images || [], (img: ArtworkImage, idx: number) => {
            Circle()
              .width(6)
              .height(6)
              .fill(idx === 0 ? Color.White : '#66FFFFFF')
          })
        }
        .position({ bottom: 16 })
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height(360)
  }

  @Builder
  buildBasicInfo(): void {
    Column({ space: 8 }) {
      // 名称
      Text(this.artwork?.name || '')
        .fontSize(22)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 年代和类型
      Row({ space: 12 }) {
        Text(this.artwork?.dynasty || '')
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.accent_light'))
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })

        Text(this.artwork?.type || '')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))

        Text(this.artwork?.material || '')
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
      }
      .width('100%')

      // 简介
      Text(this.artwork?.description || '')
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(22)
        .width('100%')
        .margin({ top: 4 })

      // 基本信息列表
      Column({ space: 6 }) {
        this.buildInfoRow('年代', this.artwork?.yearRange || '')
        this.buildInfoRow('尺寸', this.artwork?.dimensions || '')
        this.buildInfoRow('重量', this.artwork?.weight || '')
        this.buildInfoRow('产地', this.artwork?.origin || '')
        this.buildInfoRow('收藏地', this.artwork?.collectionPlace || '')
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.background_card'))
      .borderRadius(8)
      .margin({ top: 8 })
    }
    .padding({ left: 16, right: 16, top: 16 })
    .width('100%')
  }

  @Builder
  buildInfoRow(label: string, value: string): void {
    if (value.length > 0) {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
          .width(60)
        Text(value)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
  }

  @Builder
  buildActionButtons(): void {
    Row({ space: 0 }) {
      // 点赞
      this.buildActionButton(
        this.isLiked ? '❤️' : '🤍',
        this.isLiked ? $r('app.color.like_active') : $r('app.color.text_secondary'),
        `${this.likeCount}`,
        () => {
          // 乐观更新 UI
          const newLiked = !this.isLiked;
          this.isLiked = newLiked;
          this.likeCount += newLiked ? 1 : -1;
          // 异步调用后端 API
          this.artworkService.toggleLike(this.artworkId);
        }
      )

      // 收藏
      this.buildActionButton(
        this.isFavorited ? '⭐' : '☆',
        this.isFavorited ? $r('app.color.favorite_active') : $r('app.color.text_secondary'),
        `${this.favoriteCount}`,
        () => {
          // 乐观更新 UI
          const newFav = !this.isFavorited;
          this.isFavorited = newFav;
          this.favoriteCount += newFav ? 1 : -1;
          // 异步调用后端 API
          this.artworkService.toggleFavorite(this.artworkId);
        }
      )

      // 评论
      this.buildActionButton(
        '💬',
        $r('app.color.text_secondary'),
        `${this.comments.length}`,
        () => {
          this.showCommentInput = !this.showCommentInput;
        }
      )

      // 分享
      this.buildActionButton(
        '📤',
        $r('app.color.text_secondary'),
        '分享',
        () => {}
      )
    }
    .width('100%')
    .padding({ left: 32, right: 32, top: 12, bottom: 12 })
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder
  buildActionButton(icon: string, color: ResourceColor, label: string,
    onClick: () => void): void {
    Column({ space: 4 }) {
      Button() {
        Text(icon)
          .fontSize(22)
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .onClick(() => { onClick(); })

      Text(label)
        .fontSize(11)
        .fontColor(color)
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildSectionTabs(): void {
    Row({ space: 0 }) {
      ForEach([
        new SectionTabItem('详细介绍', SectionTab.INFO),
        new SectionTabItem('历史背景', SectionTab.HISTORY),
        new SectionTabItem('文化价值', SectionTab.CULTURE),
        new SectionTabItem('语音导览', SectionTab.AUDIO)
      ], (tab: SectionTabItem) => {
        Column() {
          Text(tab.label)
            .fontSize(14)
            .fontColor(this.selectedSection === tab.value ?
              $r('app.color.primary') : $r('app.color.text_secondary'))
            .fontWeight(this.selectedSection === tab.value ?
              FontWeight.Medium : FontWeight.Regular)
            .padding({ bottom: 8 })
            .onClick(() => {
              this.selectedSection = tab.value;
            })
          if (this.selectedSection === tab.value) {
            Divider()
              .width('60%')
              .color($r('app.color.primary'))
              .strokeWidth(2)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
    .borderWidth({ bottom: 1 })
    .borderColor({ bottom: $r('app.color.divider') })
  }

  @Builder
  buildSectionContent(): void {
    Column() {
      if (this.selectedSection === SectionTab.INFO) {
        Text(this.artwork?.detailDescription || '')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(24)
          .width('100%')
      } else if (this.selectedSection === SectionTab.HISTORY) {
        Text(this.artwork?.historicalBackground || '')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(24)
          .width('100%')
      } else if (this.selectedSection === SectionTab.CULTURE) {
        Text(this.artwork?.culturalSignificance || '')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(24)
          .width('100%')
      } else if (this.selectedSection === SectionTab.AUDIO) {
        this.buildAudioSection()
      }

      // 标签
      if (this.selectedSection !== SectionTab.AUDIO) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.artwork?.tags || [], (tag: string) => {
            Text(`# ${tag}`)
              .fontSize(12)
              .fontColor($r('app.color.primary'))
              .backgroundColor($r('app.color.accent_light'))
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .margin({ top: 16 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 })
  }

  @Builder
  buildAudioSection(): void {
    Column({ space: 16 }) {
      if (this.artwork?.audioGuide) {
        AudioPlayer({ audioGuide: this.artwork.audioGuide })

        // 讲解文稿
        if (this.artwork.audioGuide.textScript.length > 0) {
          Column({ space: 8 }) {
            Text('讲解文稿')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)

            Text(this.artwork.audioGuide.textScript)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(20)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(8)
        }
      } else {
        EmptyView({ text: '暂无语音讲解' })
      }

      // 视频讲解
      if (this.artwork?.videoGuide) {
        Column({ space: 8 }) {
          Text('视频讲解')
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Stack() {
            Image(this.artwork.videoGuide.coverUrl)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)

            Circle()
              .width(56)
              .height(56)
              .fill($r('app.color.overlay'))
              .overlay(() => {
                Text('▶')
                  .fontSize(24)
                  .fontColor(Color.White)
              })
          }
          .width('100%')
          .height(200)

          Text(this.artwork.videoGuide.description)
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .margin({ top: 16 })
      }

      // 语音问答入口
      Row({ space: 8 }) {
        Text('🎙️')
          .fontSize(20)
        Text('对这件文物提问')
          .fontSize(14)
          .fontColor($r('app.color.primary'))
      }
      .width('100%')
      .height(44)
      .backgroundColor($r('app.color.accent_light'))
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .onClick(async () => {
        const question = '这件文物有什么特点';
        const answer = await this.speechService.askQuestion(question);
        AlertDialog.show({
          title: 'AI语音问答',
          message: `Q: ${question}\nA: ${answer}`,
          confirm: { value: '知道了', action: () => {} }
        });
      })
    }
    .width('100%')
  }

  @Builder
  buildCommentSection(): void {
    Column({ space: 12 }) {
      Divider().color($r('app.color.divider')).margin({ top: 8 })

      Row() {
        Text(`评论区 (${this.comments.length})`)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('📝 查看全部 >')
          .fontSize(13)
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            router.pushUrl({
              url: 'pages/CommentPage',
              params: { artworkId: this.artworkId }
            });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 评论输入
      if (this.showCommentInput) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '写下你的评论...', text: this.commentText })
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .onChange((v) => { this.commentText = v; })
          Button() {
            Text('📤 发送')
              .fontSize(14)
              .fontColor(Color.White)
          }
            .height(36)
            .backgroundColor($r('app.color.primary'))
            .borderRadius(18)
            .onClick(() => {
              if (this.commentText.length > 0) {
                this.commentText = '';
                this.showCommentInput = false;
              }
            })
        }
        .padding({ left: 16, right: 16 })
      }

      // 评论列表（前3条）
      ForEach(this.comments.slice(0, 3), (comment: Comment) => {
        Column() {
          Row({ space: 10 }) {
            Image(comment.userAvatar)
              .width(36)
              .height(36)
              .objectFit(ImageFit.Cover)
              .borderRadius(18)

            Column({ space: 4 }) {
              Row() {
                Text(comment.username)
                  .fontSize(13)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text(this.formatTime(comment.createTime))
                  .fontSize(11)
                  .fontColor($r('app.color.text_hint'))
              }
              .width('100%')

              Text(comment.content)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .lineHeight(20)
                .width('100%')
            }
            .layoutWeight(1)
          }
          .width('100%')

          // 评论操作
          Row() {
            Text(`❤ ${comment.likeCount}`)
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
            Text('💬 回复')
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
              .margin({ left: 16 })
          }
          .padding({ left: 46 })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      })
    }
    .width('100%')
    .margin({ top: 16 })
  }

  private formatTime(timestamp: number): string {
    const diff = Date.now() - timestamp;
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`;
    return new Date(timestamp).toLocaleDateString();
  }
}

enum SectionTab {
  INFO = 'info',
  HISTORY = 'history',
  CULTURE = 'culture',
  AUDIO = 'audio'
}
