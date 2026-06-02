import router from '@ohos.router';
import { Comment } from '../model/Comment';
import { ArtworkService } from '../service/ArtworkService';
import { EmptyView } from '../component/ArtworkCard';
import { ReplyComment } from '../model/Comment';

@Entry
@Component
struct CommentPage {
  @State private comments: Comment[] = [];
  @State private commentText: string = '';
  @State private replyTo: string = '';

  private artworkId: string = '';
  private artworkName: string = '';
  private artworkService = ArtworkService.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.artworkId = params['artworkId'] || '';
    this.artworkName = params['artworkName'] || '';
    // 异步从后端加载评论
    this.artworkService.fetchComments(this.artworkId).then((comments) => {
      this.comments = comments;
    });
  }

  build() {
    Column() {
      // 导航
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(20)
        .onClick(() => { router.back(); })

        Blank()
        Text('评论')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`共 ${this.comments.length} 条`)
          .fontSize(13)
          .fontColor($r('app.color.text_hint'))
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.comments.length === 0) {
        EmptyView({ text: '还没有评论，来说两句吧' })
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.comments, (comment: Comment) => {
              Column() {
                Row({ space: 10 }) {
                  Image(comment.userAvatar)
                    .width(40)
                    .height(40)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(20)

                  Column({ space: 4 }) {
                    Row() {
                      Text(comment.username)
                        .fontSize(14)
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

                    Row({ space: 16 }) {
                      Text(`❤ ${comment.likeCount}`)
                        .fontSize(12)
                        .fontColor($r('app.color.text_hint'))
                      Text('💬 回复')
                        .fontSize(12)
                        .fontColor($r('app.color.text_hint'))
                        .onClick(() => {
                          this.replyTo = comment.username;
                        })
                      if (comment.replies.length > 0) {
                        Text(`${comment.replies.length} 条回复`)
                          .fontSize(12)
                          .fontColor($r('app.color.primary'))
                      }
                    }
                    .margin({ top: 4 })

                    // 回复列表
                    if (comment.replies.length > 0) {
                      Column({ space: 8 }) {
                        ForEach(comment.replies.slice(0, 2), (reply: ReplyComment) => {
                          Row({ space: 8 }) {
                            Image(reply.userAvatar)
                              .width(28)
                              .height(28)
                              .objectFit(ImageFit.Cover)
                              .borderRadius(14)
                            Column({ space: 2 }) {
                              Row() {
                                Text(reply.username)
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_primary'))
                                  .fontWeight(FontWeight.Medium)
                                Text(` 回复 ${reply.replyToUsername}`)
                                  .fontSize(12)
                                  .fontColor($r('app.color.text_hint'))
                              }
                              Text(reply.content)
                                .fontSize(13)
                                .fontColor($r('app.color.text_secondary'))
                            }
                            .layoutWeight(1)
                          }
                          .width('100%')
                        })
                        if (comment.replies.length > 2) {
                          Text(`查看全部 ${comment.replies.length} 条回复 >`)
                            .fontSize(12)
                            .fontColor($r('app.color.primary'))
                            .padding({ left: 36 })
                        }
                      }
                      .padding({ left: 50, top: 8 })
                      .width('100%')
                    }
                  }
                  .layoutWeight(1)
                }
                .width('100%')

                Divider()
                  .color($r('app.color.divider_light'))
                  .margin({ left: 50 })
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 4 })
            })
          }
          .padding({ bottom: 80 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      // 底部输入区域
      Row({ space: 8 }) {
        TextInput({
          placeholder: this.replyTo ? `回复 ${this.replyTo}...` : '写下你的评论...',
          text: this.commentText
        })
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .placeholderColor($r('app.color.text_hint'))
          .backgroundColor($r('app.color.search_bar_background'))
          .borderRadius(22)
          .padding({ left: 16 })
          .onChange((v) => { this.commentText = v; })

        Button() {
          Text('📤')
            .fontSize(20)
        }
        .width(44)
        .height(44)
        .backgroundColor(this.commentText.length > 0 ?
          $r('app.color.primary') : $r('app.color.divider'))
        .borderRadius(22)
        .onClick(() => {
          if (this.commentText.length > 0) {
            this.commentText = '';
            this.replyTo = '';
          }
        })
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 24 })
      .backgroundColor($r('app.color.background_card'))
      .width('100%')
      .position({ bottom: 0 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private formatTime(timestamp: number): string {
    const diff = Date.now() - timestamp;
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`;
    return new Date(timestamp).toLocaleDateString();
  }
}
