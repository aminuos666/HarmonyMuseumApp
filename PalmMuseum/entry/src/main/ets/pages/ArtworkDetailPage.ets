import router from '@ohos.router';
import { Artwork, ArtworkImage } from '../model/Artwork';
import { Comment, ReplyComment } from '../model/Comment';
import { ArtworkService } from '../service/ArtworkService';
import { UserService } from '../service/UserService';
import { SpeechService } from '../service/SpeechService';
import { ImageViewer } from '../component/ImageViewer';
import { AudioPlayer } from '../component/AudioPlayer';
import { EmptyView } from '../component/ArtworkCard';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';

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
  @StorageLink('artwork_isLiked') isLiked: boolean = false;
  @StorageLink('artwork_isFavorited') isFavorited: boolean = false;
  @StorageLink('artwork_likeCount') likeCount: number = 0;
  @StorageLink('artwork_favoriteCount') favoriteCount: number = 0;
  @State private comments: Comment[] = [];
  @State private isPlayingAudio: boolean = false;
  @StorageLink('artwork_showCommentInput') showCommentInput: boolean = false;
  @StorageLink('artwork_commentText') commentText: string = '';
  @StorageLink('artwork_commentsRefresh') private commentsRefresh: number = 0;
  @State private showFullImage: boolean = false;
  @State private currentImageIndex: number = 0;

  private artworkId: string = '';
  private artworkService = ArtworkService.getInstance();
  private userService = UserService.getInstance();
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
    // 记录浏览历史
    this.userService.addBrowseHistory(this.artworkId);
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

            // 交互按钮 — @StorageLink 变量通过 AppStorage 广播，闭包内修改也能触发重渲染
            Row({ space: 0 }) {
              // 点赞
              Column({ space: 4 }) {
                Button() {
                  Text(this.isLiked ? '❤️' : '🤍')
                    .fontSize(24)
                }
                .width(48)
                .height(48)
                .backgroundColor(Color.Transparent)
                .onClick(() => { this.handleLike(); })

                Text(`${this.likeCount}`)
                  .fontSize(12)
                  .fontColor(this.isLiked ? $r('app.color.like_active') : $r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Center)

              // 收藏
              Column({ space: 4 }) {
                Button() {
                  Text(this.isFavorited ? '⭐' : '☆')
                    .fontSize(24)
                }
                .width(48)
                .height(48)
                .backgroundColor(Color.Transparent)
                .onClick(() => { this.handleFavorite(); })

                Text(`${this.favoriteCount}`)
                  .fontSize(12)
                  .fontColor(this.isFavorited ? $r('app.color.favorite_active') : $r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Center)

              // 评论
              Column({ space: 4 }) {
                Button() {
                  Text('💬')
                    .fontSize(24)
                }
                .width(48)
                .height(48)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.showCommentInput = !this.showCommentInput;
                })

                Text(`${this.comments.length}`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Center)

              // 分享
              Column({ space: 4 }) {
                Button() {
                  Text('📤')
                    .fontSize(24)
                }
                .width(48)
                .height(48)
                .backgroundColor(Color.Transparent)
                .onClick(() => { this.handleShare(); })

                Text('分享')
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ left: 28, right: 28, top: 14, bottom: 16 })
            .justifyContent(FlexAlign.SpaceAround)
            .backgroundColor($r('app.color.background_card'))
            .borderRadius({ topLeft: 16, topRight: 16 })
            .shadow({ radius: 8, color: $r('app.color.shadow'), offsetY: -2 })

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
        .edgeEffect(EdgeEffect.Spring)
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
        .height(380)
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.showFullImage = true;
        })

      // 渐变遮罩 — 更深色带来厚重感
      Column()
        .width('100%')
        .height(160)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#00000000', 0], ['#CC000000', 1]]
        })
        .position({ bottom: 0 })

      // 返回按钮 — 半透明毛玻璃效果
      Button() {
        Text('←')
          .fontSize(18)
          .fontColor(Color.White)
      }
      .width(36)
      .height(36)
      .backgroundColor('#40FFFFFF')
      .borderRadius(18)
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
        .position({ bottom: 20 })
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height(380)
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
      Column({ space: 8 }) {
        this.buildInfoRow('年代', this.artwork?.yearRange || '')
        this.buildInfoRow('尺寸', this.artwork?.dimensions || '')
        this.buildInfoRow('重量', this.artwork?.weight || '')
        this.buildInfoRow('产地', this.artwork?.origin || '')
        this.buildInfoRow('收藏地', this.artwork?.collectionPlace || '')
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('app.color.background_card'))
      .borderRadius(10)
      .shadow({ radius: 6, color: $r('app.color.shadow'), offsetY: 2 })
      .margin({ top: 10 })
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
            .fontSize(15)
            .fontColor(this.selectedSection === tab.value ?
              $r('app.color.primary') : $r('app.color.text_secondary'))
            .fontWeight(this.selectedSection === tab.value ?
              FontWeight.Bold : FontWeight.Regular)
            .padding({ bottom: 10 })
            .onClick(() => {
              this.selectedSection = tab.value;
            })
          if (this.selectedSection === tab.value) {
            Divider()
              .width('50%')
              .color($r('app.color.primary'))
              .strokeWidth(2.5)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
    .backgroundColor($r('app.color.background_card'))
    .borderWidth({ bottom: 0.5 })
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
          .id(`comments-${this.commentsRefresh}`)
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
            .onSubmit(() => { this.sendComment(); })
          Button() {
            Text('📤 发送')
              .fontSize(14)
              .fontColor(Color.White)
          }
            .height(36)
            .backgroundColor($r('app.color.primary'))
            .borderRadius(18)
            .onClick(() => { this.sendComment(); })
        }
        .padding({ left: 16, right: 16 })
      }

      // 评论列表（前3条）— keyGenerator 包含状态属性，确保 ForEach 在状态变化时重新渲染
      ForEach(this.comments.slice(0, 3),
        (comment: Comment) => {
        Column() {
          Row({ space: 10 }) {
            Image(comment.userAvatar)
              .width(36).height(36).objectFit(ImageFit.Cover).borderRadius(18)

            Column({ space: 4 }) {
              Row() {
                Text(comment.username)
                  .fontSize(13).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
                Blank()
                Text(this.formatTime(comment.createTime))
                  .fontSize(11).fontColor($r('app.color.text_hint'))
              }
              .width('100%')

              Text(comment.content)
                .fontSize(14).fontColor($r('app.color.text_secondary')).lineHeight(20).width('100%')
            }
            .layoutWeight(1)
          }
          .width('100%')

          // 操作按钮
          Row() {
            Button() {
              Text(comment.isLiked ? '❤️' : '🤍').fontSize(13)
            }
            .width(36).height(28).backgroundColor(Color.Transparent)
            .onClick(() => { this.handleCommentLike(comment); })

            Text(`${comment.likeCount}`)
              .fontSize(11)
              .fontColor(comment.isLiked ? $r('app.color.like_active') : $r('app.color.text_hint'))

            Text('💬 回复')
              .fontSize(12).fontColor($r('app.color.text_hint')).margin({ left: 16 })
              .onClick(() => {
                comment.showReplyInput = !comment.showReplyInput;
                if (!comment.showReplyInput) comment.replyText = '';
                this.commentsRefresh++;
              })
          }
          .padding({ left: 46, top: 4 })

          // 回复输入框
          if (comment.showReplyInput) {
            Row({ space: 6 }) {
              TextInput({ placeholder: `回复 ${comment.username}...`, text: comment.replyText })
                .layoutWeight(1).height(32).fontSize(13)
                .onChange((v) => { comment.replyText = v; })
                .onSubmit(() => { this.sendCommentReply(comment); })
              Button() {
                Text('发送').fontSize(12).fontColor(Color.White)
              }
                .height(32).backgroundColor($r('app.color.primary')).borderRadius(16)
                .onClick(() => { this.sendCommentReply(comment); })
            }
            .padding({ left: 46, top: 4 })
          }

          // 回复列表
          if (comment.replies && comment.replies.length > 0) {
            ForEach(
              comment.isExpanded ? comment.replies : comment.replies.slice(0, 2),
              (reply: ReplyComment): void => {
              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Image(reply.userAvatar)
                    .width(28).height(28).objectFit(ImageFit.Cover).borderRadius(14)

                  Column({ space: 2 }) {
                    Row() {
                      Text(reply.username).fontSize(12)
                        .fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
                      Blank()
                      Text(this.formatTime(reply.createTime)).fontSize(10)
                        .fontColor($r('app.color.text_hint'))
                    }
                    .width('100%')

                    Text(reply.content).fontSize(13)
                      .fontColor($r('app.color.text_secondary')).lineHeight(18).width('100%')
                  }
                  .layoutWeight(1)
                }
                .width('100%')

                Row() {
                  Text(reply.isLiked ? '❤️' : '🤍').fontSize(11)
                  Text(`${reply.likeCount}`).fontSize(10).fontColor($r('app.color.text_hint'))
                }
                .padding({ left: 36 })
              }
              .padding({ top: 6 })
            },
            (reply: ReplyComment): string => reply.id + '_' + reply.isLiked
          )

            // 展开/折叠
            if (comment.replies.length > 2) {
              Text(comment.isExpanded
                ? '△ 收起回复'
                : `▽ 展开全部 ${comment.replies.length} 条回复`)
                .fontSize(12).fontColor($r('app.color.primary')).padding({ left: 36, top: 4 })
                .onClick(() => {
                  comment.isExpanded = !comment.isExpanded;
                  this.commentsRefresh++;
                })
            }
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      },
      (comment: Comment): string => comment.id + '_' + comment.isLiked + '_' + comment.likeCount + '_' + comment.showReplyInput + '_' + comment.isExpanded
    )
    }
    .width('100%')
    .margin({ top: 16 })
  }

  private handleCommentLike(comment: Comment): void {
    const newLiked = !comment.isLiked;
    comment.isLiked = newLiked;
    comment.likeCount += newLiked ? 1 : -1;
    this.commentsRefresh++;
    this.artworkService.toggleCommentLike(comment.id);
  }

  private sendCommentReply(comment: Comment): void {
    const text = comment.replyText.trim();
    if (text.length === 0) {
      return;
    }
    // 先关闭输入框
    comment.replyText = '';
    comment.showReplyInput = false;
    this.commentsRefresh++;

    // 异步发送回复
    this.artworkService.addComment(this.artworkId, text, comment.id).then((newComment) => {
      if (newComment) {
        const reply = new ReplyComment();
        reply.id = newComment.id;
        reply.commentId = comment.id;
        reply.userId = newComment.userId;
        reply.username = newComment.username;
        reply.userAvatar = newComment.userAvatar;
        reply.content = newComment.content;
        reply.likeCount = 0;
        reply.isLiked = false;
        reply.reviewStatus = newComment.reviewStatus;
        reply.createTime = newComment.createTime;
        comment.replies.push(reply);
        comment.replyCount = comment.replies.length;
        comment.isExpanded = true;
        this.commentsRefresh++;
        promptAction.showToast({ message: '回复成功', duration: 1500 });
      } else {
        promptAction.showToast({ message: '回复失败，请重试', duration: 1500 });
      }
    });
  }

  private handleLike(): void {
    console.info(`handleLike called, was: ${this.isLiked}, count: ${this.likeCount}`);
    const newLiked = !this.isLiked;
    this.isLiked = newLiked;
    this.likeCount += newLiked ? 1 : -1;
    console.info(`handleLike now: ${this.isLiked}, count: ${this.likeCount}`);
    // fire-and-forget: API 请求在状态更新后异步执行
    this.artworkService.toggleLike(this.artworkId);
  }

  private handleFavorite(): void {
    console.info(`handleFavorite called, was: ${this.isFavorited}, count: ${this.favoriteCount}`);
    const newFav = !this.isFavorited;
    this.isFavorited = newFav;
    this.favoriteCount += newFav ? 1 : -1;
    console.info(`handleFavorite now: ${this.isFavorited}, count: ${this.favoriteCount}`);
    this.artworkService.toggleFavorite(this.artworkId);
  }

  private handleShare(): void {
    const name = this.artwork?.name || '文物';
    const dynasty = this.artwork?.dynasty || '';
    const desc = this.artwork?.description || '';
    const shareText = `📌 ${name}\n${dynasty ? `年代：${dynasty}\n` : ''}${desc ? `简介：${desc}\n` : ''}——来自「掌上博物馆」`;
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData).then(() => {
        promptAction.showToast({ message: '已复制文物信息到剪贴板，可粘贴分享', duration: 2000 });
      }).catch(() => {
        promptAction.showToast({ message: '分享失败', duration: 1500 });
      });
    } catch (e) {
      console.error(`分享失败: ${(e as Error).message}`);
      promptAction.showToast({ message: '分享失败', duration: 1500 });
    }
  }

  private sendComment(): void {
    const text = this.commentText.trim();
    if (text.length === 0) {
      return;
    }
    // 异步发送评论
    this.artworkService.addComment(this.artworkId, text).then((newComment) => {
      if (newComment) {
        this.comments.unshift(newComment);
        this.commentsRefresh++;
        promptAction.showToast({ message: '评论发表成功', duration: 1500 });
      } else {
        promptAction.showToast({ message: '评论发表失败，请重试', duration: 1500 });
      }
    });
    this.commentText = '';
    this.showCommentInput = false;
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

