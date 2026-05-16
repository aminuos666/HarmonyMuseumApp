import router from '@ohos.router';
import { NotificationService, AppNotification } from '../service/NotificationService';
import { NotificationType } from '../utils/Constants';
import { EmptyView } from '../component/ArtworkCard';

@Entry
@Component
struct NotificationPage {
  @State private notifications: AppNotification[] = [];
  @State private unreadCount: number = 0;

  private notificationService = NotificationService.getInstance();

  aboutToAppear(): void {
    this.notifications = this.notificationService.getNotifications();
    this.unreadCount = this.notificationService.getUnreadCount();
  }

  build() {
    Column() {
      // 导航
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
        Text('消息通知')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()

        if (this.unreadCount > 0) {
          Text('✅ 全部已读')
            .fontSize(14)
            .fontColor($r('app.color.primary'))
            .onClick(() => {
              this.notificationService.markAllAsRead();
              this.unreadCount = 0;
            })
        }
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.notifications.length === 0) {
        EmptyView({ text: '暂无消息通知' })
          .margin({ top: 60 })
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.notifications, (notif: AppNotification) => {
              Column() {
                Row({ space: 12 }) {
                  // 通知图标
                  Circle()
                    .width(10)
                    .height(10)
                    .fill(notif.isRead ? Color.Transparent : $r('app.color.badge'))
                    .margin({ top: 6 })

                  Column({ space: 4 }) {
                    Row() {
                      Text(notif.title)
                        .fontSize(15)
                        .fontColor($r('app.color.text_primary'))
                        .fontWeight(notif.isRead ? FontWeight.Regular : FontWeight.Medium)
                      Blank()
                      Text(this.formatTime(notif.createTime))
                        .fontSize(11)
                        .fontColor($r('app.color.text_hint'))
                    }
                    .width('100%')

                    Text(notif.content)
                      .fontSize(13)
                      .fontColor($r('app.color.text_secondary'))
                      .lineHeight(18)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onClick(() => {
                  if (!notif.isRead) {
                    this.notificationService.markAsRead(notif.id);
                    this.unreadCount = this.notificationService.getUnreadCount();
                  }
                  // 跳转到相关内容
                  if (notif.relatedId) {
                    router.pushUrl({
                      url: 'pages/ArtworkDetailPage',
                      params: { artworkId: notif.relatedId }
                    });
                  }
                })

                Divider()
                  .color($r('app.color.divider_light'))
                  .margin({ left: 38 })
              }
            })
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

  private formatTime(timestamp: number): string {
    const diff = Date.now() - timestamp;
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`;
    return new Date(timestamp).toLocaleDateString();
  }
}
