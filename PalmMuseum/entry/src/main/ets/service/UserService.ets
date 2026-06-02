/**
 * 用户服务
 *
 * 连接后端 API，提供用户认证、个人资料、收藏、点赞、浏览历史等功能。
 *
 * ─── 架构说明 ───
 * - async 方法调用后端 API
 * - 同步 getter 从本地缓存返回（build 方法中同步使用）
 * - 登录成功后将 JWT Token 存入 HttpClient，后续请求自动附加
 */
import { User, UserCollection, UserLike, BrowseHistory, UserUpload,
  UserDynamic, UserFollow, PrivacyLevel, UploadType } from '../model/User';
import { ReviewStatus } from '../utils/Constants';
import { MockUsers } from '../data/MockUsers';
import { HttpClient } from './HttpClient';

// ──────── API 响应类型定义 ────────

interface ApiUserOut {
  id: number;
  account: string;
  nickname: string;
  avatar: string;
  phone: string;
  email: string;
  gender: string;
  birthday: string | null;
  signature: string;
  created_at: string;
}

interface ApiTokenOut {
  access_token: string;
  token_type: string;
  user: ApiUserOut;
}

interface ApiLikesResponse {
  artwork_ids: string[];
}

interface ApiCollectionsResponse {
  artwork_ids: string[];
}

interface ApiHistoryResponse {
  message?: string;
}

interface ApiHistoryItem {
  artwork_id: string;
  browse_time: string;
}

interface ApiProfileResponse {
  message: string;
}

// ──────── 字段映射 ────────

function mapUser(api: ApiUserOut): User {
  const user = new User();
  user.id = api.id.toString();
  user.username = api.account;
  user.nickname = api.nickname || api.account;
  user.avatar = api.avatar || '';
  user.phone = api.phone || '';
  user.email = api.email || '';
  user.bio = api.signature || '';
  user.password = '';
  if (api.created_at) {
    const ts = Date.parse(api.created_at);
    user.registerTime = isNaN(ts) ? Date.now() : ts;
  }
  return user;
}

// ──────── 用户服务 ────────

export class UserService {
  private static instance: UserService;
  private currentUser: User | null;
  private likedIds: Set<string>;
  private collectedIds: Set<string>;
  private browseHistoryList: BrowseHistory[];
  private browseHistoryIds: string[];

  // Mock 数据（社交功能暂未接入后端）
  private uploads: UserUpload[];
  private dynamics: UserDynamic[];
  private follows: UserFollow[];
  private otherUsers: User[];

  private constructor() {
    this.currentUser = null;
    this.likedIds = new Set();
    this.collectedIds = new Set();
    this.browseHistoryList = [];
    this.browseHistoryIds = [];
    this.uploads = [];
    this.dynamics = [];
    this.follows = [];
    this.otherUsers = MockUsers.getOtherUsers();
  }

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  // ════════════ 认证 ════════════

  /** 登录（异步） */
  async login(account: string, password: string): Promise<string | null> {
    const http = HttpClient.getInstance();
    try {
      const loginBody: Record<string, Object> = {} as Record<string, Object>;
      loginBody['account'] = account;
      loginBody['password'] = password;
      const response = await http.post<ApiTokenOut>('/api/auth/login', loginBody);
      this.handleAuthSuccess(response);
      return null;
    } catch (e) {
      const msg = (e as Error).message;
      console.error(`登录失败: ${msg}`);
      return msg;
    }
  }

  /** 注册（异步） */
  async register(account: string, password: string, nickname: string): Promise<string | null> {
    const http = HttpClient.getInstance();
    try {
      const registerBody: Record<string, Object> = {} as Record<string, Object>;
      registerBody['account'] = account;
      registerBody['password'] = password;
      registerBody['nickname'] = nickname;
      const response = await http.post<ApiTokenOut>('/api/auth/register', registerBody);
      this.handleAuthSuccess(response);
      return null;
    } catch (e) {
      const msg = (e as Error).message;
      console.error(`注册失败: ${msg}`);
      return msg;
    }
  }

  /** 华为账号一键登录（模拟） */
  async loginWithHuawei(): Promise<boolean> {
    const http = HttpClient.getInstance();
    try {
      const response = await http.post<ApiTokenOut>('/api/auth/huawei');
      this.handleAuthSuccess(response);
      return true;
    } catch (e) {
      console.error(`华为登录失败: ${(e as Error).message}`);
      return false;
    }
  }

  /** 处理登录成功 */
  private handleAuthSuccess(response: ApiTokenOut): void {
    // 存储 Token
    const http = HttpClient.getInstance();
    http.setToken(response.access_token);

    // 持久化 Token，App 重启后可恢复登录状态
    AppStorage.Set<string>('access_token', response.access_token);

    // 存储用户信息
    this.currentUser = mapUser(response.user);

    // 立即加载用户互动数据
    this.fetchLikes();
    this.fetchCollections();
    this.fetchBrowseHistory();
  }

  /** 从已有 Token 恢复登录状态 */
  async restoreSession(token: string): Promise<boolean> {
    const http = HttpClient.getInstance();
    http.setToken(token);
    try {
      const user = await http.get<ApiUserOut>('/api/users/profile');
      this.currentUser = mapUser(user);

      // 加载互动数据
      this.fetchLikes();
      this.fetchCollections();
      this.fetchBrowseHistory();

      return true;
    } catch (e) {
      console.error('恢复登录状态失败');
      http.clearToken();
      AppStorage.Set<string>('access_token', '');
      this.currentUser = null;
      return false;
    }
  }

  /** 退出登录 */
  logout(): void {
    const http = HttpClient.getInstance();
    http.clearToken();
    AppStorage.Set<string>('access_token', '');
    this.currentUser = null;
    this.likedIds.clear();
    this.collectedIds.clear();
    this.browseHistoryList = [];
    this.browseHistoryIds = [];
    this.uploads = [];
    this.dynamics = [];
    this.follows = [];
  }

  // ════════════ 用户信息（同步） ════════════

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  isLoggedIn(): boolean {
    return HttpClient.getInstance().isLoggedIn();
  }

  /** 更新个人资料（异步） */
  async updateProfile(nickname: string, bio: string): Promise<boolean> {
    const http = HttpClient.getInstance();
    try {
      const body: Record<string, Object> = {};
      if (nickname) body['nickname'] = nickname;
      if (bio) body['signature'] = bio;

      const response = await http.put<ApiUserOut>('/api/users/profile', body);

      if (this.currentUser) {
        this.currentUser.nickname = response.nickname || this.currentUser.nickname;
        this.currentUser.bio = response.signature || this.currentUser.bio;
      }
      return true;
    } catch (e) {
      console.error(`更新资料失败: ${(e as Error).message}`);
      return false;
    }
  }

  /** 更新头像（异步） */
  async updateAvatar(avatarUri: string): Promise<boolean> {
    const http = HttpClient.getInstance();
    try {
      const body: Record<string, Object> = {};
      body['avatar'] = avatarUri;
      const response = await http.put<ApiUserOut>('/api/users/profile', body);
      if (this.currentUser) {
        this.currentUser.avatar = response.avatar || this.currentUser.avatar;
      }
      // 通知各页面刷新
      try { AppStorage.SetOrCreate<number>('userDataRefresh', Date.now()); } catch (_) {}
      return true;
    } catch (e) {
      console.error(`更新头像失败: ${(e as Error).message}`);
      return false;
    }
  }

  /** 修改密码（异步） */
  async changePassword(oldPassword: string, newPassword: string): Promise<boolean> {
    const http = HttpClient.getInstance();
    try {
      const pwdBody: Record<string, Object> = {} as Record<string, Object>;
      pwdBody['old_password'] = oldPassword;
      pwdBody['new_password'] = newPassword;
      await http.put<ApiProfileResponse>('/api/users/password', pwdBody);
      return true;
    } catch (e) {
      console.error(`修改密码失败: ${(e as Error).message}`);
      return false;
    }
  }

  /** 注销账号（异步） */
  async deleteAccount(): Promise<boolean> {
    const http = HttpClient.getInstance();
    try {
      await http.delete<ApiProfileResponse>('/api/users/account');
      this.logout();
      return true;
    } catch (e) {
      console.error(`注销失败: ${(e as Error).message}`);
      return false;
    }
  }

  /** 更新隐私设置（本地 Mock，后端暂未支持） */
  updatePrivacy(level: PrivacyLevel): boolean {
    if (this.currentUser) {
      this.currentUser.privacyLevel = level;
      return true;
    }
    return false;
  }

  // ════════════ 点赞（异步 + 缓存） ════════════

  /** 从后端加载点赞列表 */
  async fetchLikes(): Promise<string[]> {
    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      this.likedIds.clear();
      return [];
    }
    try {
      const response = await http.get<ApiLikesResponse>('/api/likes');
      this.likedIds = new Set(response.artwork_ids || []);
      return Array.from(this.likedIds);
    } catch (e) {
      console.error(`获取点赞列表失败: ${(e as Error).message}`);
      return [];
    }
  }

  getLikes(): string[] {
    return Array.from(this.likedIds);
  }

  isLiked(artworkId: string): boolean {
    return this.likedIds.has(artworkId);
  }

  addLike(artworkId: string): boolean {
    this.likedIds.add(artworkId);
    return true;
  }

  removeLike(artworkId: string): boolean {
    this.likedIds.delete(artworkId);
    return true;
  }

  // ════════════ 收藏（异步 + 缓存） ════════════

  /** 从后端加载收藏列表 */
  async fetchCollections(): Promise<string[]> {
    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      this.collectedIds.clear();
      return [];
    }
    try {
      const response = await http.get<ApiCollectionsResponse>('/api/collections');
      this.collectedIds = new Set(response.artwork_ids || []);
      return Array.from(this.collectedIds);
    } catch (e) {
      console.error(`获取收藏列表失败: ${(e as Error).message}`);
      return [];
    }
  }

  getCollections(): string[] {
    return Array.from(this.collectedIds);
  }

  isCollected(artworkId: string): boolean {
    return this.collectedIds.has(artworkId);
  }

  addCollection(artworkId: string): boolean {
    this.collectedIds.add(artworkId);
    return true;
  }

  removeCollection(artworkId: string): boolean {
    this.collectedIds.delete(artworkId);
    return true;
  }

  // ════════════ 浏览历史（异步 + 缓存） ════════════

  /** 从后端加载浏览历史 */
  async fetchBrowseHistory(): Promise<string[]> {
    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      this.browseHistoryList = [];
      this.browseHistoryIds = [];
      return [];
    }
    try {
      const response = await http.get<ApiHistoryItem[]>('/api/history');
      this.browseHistoryList = response.map(item => {
        const h = new BrowseHistory();
        h.artworkId = item.artwork_id;
        const ts = Date.parse(item.browse_time);
        h.browseTime = isNaN(ts) ? Date.now() : ts;
        return h;
      });
      this.browseHistoryIds = response.map(item => item.artwork_id);
      return this.browseHistoryIds;
    } catch (e) {
      console.error(`获取浏览历史失败: ${(e as Error).message}`);
      return [];
    }
  }

  getBrowseHistory(): BrowseHistory[] {
    return this.browseHistoryList.sort((a, b) => b.browseTime - a.browseTime);
  }

  getBrowseHistoryIds(): string[] {
    return this.browseHistoryIds;
  }

  /** 添加浏览记录（异步） */
  async addBrowseHistory(artworkId: string): Promise<void> {
    // 更新本地缓存
    const existing = this.browseHistoryList.find(h => h.artworkId === artworkId);
    if (existing) {
      existing.browseTime = Date.now();
    } else {
      const h = new BrowseHistory();
      h.id = `hist_${Date.now()}`;
      h.artworkId = artworkId;
      h.browseTime = Date.now();
      this.browseHistoryList.push(h);
      this.browseHistoryIds.push(artworkId);
    }

    // 异步通知后端
    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      return;
    }
    try {
      const historyBody: Record<string, Object> = {} as Record<string, Object>;
      historyBody['artwork_id'] = artworkId;
      await http.post<ApiHistoryResponse>('/api/history', historyBody);
    } catch (e) {
      console.error(`记录浏览历史失败: ${(e as Error).message}`);
    }
  }

  /** 清空浏览历史（异步） */
  async clearBrowseHistory(): Promise<boolean> {
    this.browseHistoryList = [];
    this.browseHistoryIds = [];

    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      return true;
    }
    try {
      await http.delete<ApiHistoryResponse>('/api/history');
      return true;
    } catch (e) {
      console.error(`清空浏览历史失败: ${(e as Error).message}`);
      return false;
    }
  }

  // ════════════ 用户查找（Mock，社交功能待接入） ════════════

  getUserById(userId: string): User | undefined {
    if (this.currentUser?.id === userId) return this.currentUser;
    return this.otherUsers.find(u => u.id === userId);
  }

  getOtherUsers(): User[] {
    return this.otherUsers;
  }

  // ════════════ 上传管理（Mock） ════════════

  getUploads(): UserUpload[] {
    return this.uploads;
  }

  addUpload(artworkId: string, type: UploadType, caption: string,
    location?: string): UserUpload {
    const upload = new UserUpload();
    upload.id = `up_${Date.now()}`;
    upload.userId = this.currentUser?.id || '';
    upload.artworkId = artworkId;
    upload.uploadType = type;
    upload.caption = caption;
    upload.location = location || '';
    upload.reviewStatus = ReviewStatus.PENDING;
    upload.uploadTime = Date.now();
    this.uploads.push(upload);
    return upload;
  }

  // ════════════ 用户动态（Mock） ════════════

  getDynamics(): UserDynamic[] {
    return this.dynamics.filter(d => d.reviewStatus === ReviewStatus.APPROVED)
      .sort((a, b) => b.createTime - a.createTime);
  }

  getFollowDynamics(): UserDynamic[] {
    const allDynamics: UserDynamic[] = [...this.dynamics];
    this.otherUsers.forEach(user => {
      if (user.isFollowing) {
        const userDynamics = MockUsers.getDynamics(user.id)
          .filter(d => d.reviewStatus === ReviewStatus.APPROVED);
        allDynamics.push(...userDynamics);
      }
    });
    return allDynamics.sort((a, b) => b.createTime - a.createTime);
  }

  publishDynamic(content: string, images: string[], artworkId?: string,
    artworkName?: string): UserDynamic {
    const d = new UserDynamic();
    d.id = `dyn_${Date.now()}`;
    d.userId = this.currentUser?.id || '';
    d.content = content;
    d.images = images;
    d.relatedArtworkId = artworkId;
    d.relatedArtworkName = artworkName;
    d.reviewStatus = ReviewStatus.PENDING;
    d.createTime = Date.now();
    this.dynamics.push(d);
    return d;
  }

  // ════════════ 关注管理（Mock） ════════════

  toggleFollow(targetUserId: string): boolean {
    const user = this.otherUsers.find(u => u.id === targetUserId);
    if (user) {
      user.isFollowing = !user.isFollowing;
      user.followerCount += user.isFollowing ? 1 : -1;
      return user.isFollowing;
    }
    return false;
  }

  getFollowingUsers(): User[] {
    return this.otherUsers.filter(u => u.isFollowing);
  }

  getFollowers(): User[] {
    return this.otherUsers.slice(0, 3);
  }
}
