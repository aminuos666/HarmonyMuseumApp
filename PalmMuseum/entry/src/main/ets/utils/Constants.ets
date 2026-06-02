export class Constants {
  // 应用信息
  static readonly APP_NAME: string = '掌上博物馆';
  static readonly VERSION: string = '1.0.0';

  // 主题：选择瓷器作为展示主题
  static readonly THEME_TYPE: string = 'porcelain';

  // =====================================================
  // API基础地址（后端：python app/main.py → 8000 端口）
  // 按调试场景切换，只改下面这一行即可
  // =====================================================
  // 模拟器调试（推荐）：模拟器通过宿主机 10.0.2.2 访问本机
  static readonly API_BASE_URL: string = 'http://10.4.122.57:8000';
  // 真机调试（USB/WiFi）：替换为你电脑的局域网IP，如
  // static readonly API_BASE_URL: string = 'http://192.168.1.100:8000';
  // 真机调试（同一网段WiFi）：ipconfig 查看本机IPv4地址后替换
  // static readonly API_BASE_URL: string = 'http://10.0.0.5:8000';
  // 生产环境：
  // static readonly API_BASE_URL: string = 'https://your-domain.com/api';

  // 分页
  static readonly PAGE_SIZE: number = 20;
  static readonly SEARCH_PAGE_SIZE: number = 50;

  // 图片质量
  static readonly THUMBNAIL_MAX_WIDTH: number = 400;
  static readonly DETAIL_IMAGE_MAX_WIDTH: number = 1200;

  // 语音相关
  static readonly SPEECH_RATE: number = 1.0;
  static readonly DEFAULT_PLAYBACK_SPEED: number = 1.0;

  // 相似度阈值
  static readonly IMAGE_SIMILARITY_THRESHOLD: number = 0.5;
  static readonly IMAGE_SEARCH_TOP_K: number = 20;

  // 缓存
  static readonly IMAGE_CACHE_SIZE: number = 100;
  static readonly SEARCH_CACHE_SIZE: number = 50;
}

export enum SortType {
  POPULAR = 'popular',
  DYNASTY = 'dynasty',
  TYPE = 'type',
  DEFAULT = 'default'
}

export enum Dynasty {
  ALL = '全部',
  XIA = '夏',
  SHANG = '商',
  ZHOU = '周',
  SPRING_AUTUMN = '春秋',
  WARRING = '战国',
  QIN = '秦',
  HAN = '汉',
  THREE_KINGDOMS = '三国',
  JIN = '晋',
  SOUTH_NORTH = '南北朝',
  SUI = '隋',
  TANG = '唐',
  SONG = '宋',
  LIAO = '辽',
  JIN_DYNASTY = '金',
  YUAN = '元',
  MING = '明',
  QING = '清',
  MODERN = '近现代'
}

export enum ReviewStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected'
}

export enum CollectionGroup {
  DEFAULT = '默认分组',
  FAVORITES = '最爱',
  TO_VISIT = '想去参观',
  VISITED = '已参观',
  CUSTOM = '自定义'
}

export enum NotificationType {
  REVIEW_PASSED = 'review_passed',
  REVIEW_REJECTED = 'review_rejected',
  NEW_FOLLOW_DYNAMIC = 'new_follow_dynamic',
  DAILY_RECOMMEND = 'daily_recommend',
  SYSTEM = 'system'
}
