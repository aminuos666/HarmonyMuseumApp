import { NotificationType, ReviewStatus } from '../utils/Constants';

/**
 * 消息通知服务
 *
 * HarmonyOS通知能力：
 * - @ohos.notification: 发布通知、管理通知渠道
 * - @ohos.reminderAgent: 提醒代理服务
 * - 支持本地通知和推送通知
 *
 * 当前实现：通知队列管理（模拟），真实部署需集成华为推送服务
 */
export class NotificationService {
  private static instance: NotificationService;
  private notifications: AppNotification[] = [];
  private listeners: NotificationListener[] = [];

  private constructor() {}

  static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * 发送通知
   */
  sendNotification(type: NotificationType, title: string, content: string,
    relatedId?: string): void {
    const notification = new AppNotification();
    notification.id = `notif_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    notification.type = type;
    notification.title = title;
    notification.content = content;
    notification.relatedId = relatedId || '';
    notification.isRead = false;
    notification.createTime = Date.now();

    this.notifications.unshift(notification);

    // 提醒监听器
    this.listeners.forEach(listener => {
      try {
        listener.onNotification(notification);
      } catch (e) {
        console.error('Notification listener error: ' + e);
      }
    });

    // 真实应用中使用HarmonyOS通知API：
    // import notification from '@ohos.notification';
    // notification.publish({
    //   content: {
    //     contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
    //     text: content,
    //     title: title
    //   },
    //   id: notification.id
    // });
  }

  /**
   * 审核通过通知
   */
  notifyReviewPassed(contentType: string): void {
    this.sendNotification(
      NotificationType.REVIEW_PASSED,
      '审核通过通知',
      `您上传的${contentType}已通过审核，现在可以公开展示了。`
    );
  }

  /**
   * 审核未通过通知
   */
  notifyReviewRejected(contentType: string, reason: string): void {
    this.sendNotification(
      NotificationType.REVIEW_REJECTED,
      '审核未通过',
      `您上传的${contentType}未通过审核，原因：${reason}。`
    );
  }

  /**
   * 关注用户发布动态通知
   */
  notifyFollowDynamic(username: string, dynamicContent: string): void {
    this.sendNotification(
      NotificationType.NEW_FOLLOW_DYNAMIC,
      '新动态',
      `${username}发布了新动态：${dynamicContent.substring(0, 50)}${dynamicContent.length > 50 ? '...' : ''}`
    );
  }

  /**
   * 每日文物推荐
   */
  sendDailyRecommendation(artworkName: string, artworkId: string): void {
    this.sendNotification(
      NotificationType.DAILY_RECOMMEND,
      '今日文物推荐',
      `推荐您欣赏：${artworkName}，点击查看详情。`,
      artworkId
    );
  }

  /**
   * 获取通知列表
   */
  getNotifications(page: number = 1, pageSize: number = 20): AppNotification[] {
    const start = (page - 1) * pageSize;
    return this.notifications.slice(start, start + pageSize);
  }

  /**
   * 获取未读通知数量
   */
  getUnreadCount(): number {
    return this.notifications.filter(n => !n.isRead).length;
  }

  /**
   * 标记通知为已读
   */
  markAsRead(notificationId: string): void {
    const notif = this.notifications.find(n => n.id === notificationId);
    if (notif) {
      notif.isRead = true;
    }
  }

  /**
   * 标记所有通知为已读
   */
  markAllAsRead(): void {
    this.notifications.forEach(n => n.isRead = true);
  }

  /**
   * 注册监听器
   */
  addListener(listener: NotificationListener): void {
    this.listeners.push(listener);
  }

  /**
   * 移除监听器
   */
  removeListener(listener: NotificationListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 清除所有通知
   */
  clearAll(): void {
    this.notifications = [];
  }
}

export class AppNotification {
  id: string = '';
  type: NotificationType = NotificationType.SYSTEM;
  title: string = '';
  content: string = '';
  relatedId: string = '';
  isRead: boolean = false;
  createTime: number = 0;
}

export interface NotificationListener {
  onNotification(notification: AppNotification): void;
}
