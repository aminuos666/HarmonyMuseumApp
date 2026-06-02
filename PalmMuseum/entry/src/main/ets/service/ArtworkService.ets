/**
 * 文物服务
 *
 * 连接后端 API，提供文物相关操作。
 *
 * ─── 架构说明 ───
 * - 异步方法 (fetch*)  从后端 API 加载数据
 * - 同步 getter 从本地缓存返回数据（页面 build 方法中同步使用）
 * - 调用流程：aboutToAppear → fetchArtworks() → build() 中使用 getArtworks()
 *
 * ─── 字段映射 ───
 * 后端返回 snake_case（如 like_count），前端模型使用 camelCase（如 likeCount）。
 * mapArtwork() 函数处理转换。
 */
import { Artwork, ArtworkImage, AudioGuide, ArtworkSearchResult, ImageSearchResult } from '../model/Artwork';
import { Comment, ReplyComment } from '../model/Comment';
import { MockArtworks } from '../data/MockArtworks';
import { MockComments } from '../data/MockComments';
import { SortType, Dynasty, Constants, ReviewStatus } from '../utils/Constants';
import { HttpClient } from './HttpClient';
import { UserService } from './UserService';

// ──────── API 响应类型定义 ────────

interface ApiArtworkImage {
  id: string;
  url: string;
  thumbnail_url: string;
  title: string;
  description: string;
  width: number;
  height: number;
}

interface ApiAudioGuide {
  id: string;
  url: string;
  duration: number;
  narrator: string;
  text_script: string;
}

interface ApiArtworkOut {
  id: string;
  name: string;
  dynasty: string;
  type: string;
  material: string;
  description: string;
  detail_description: string;
  cover_image: string;
  popularity: number;
  like_count: number;
  favorite_count: number;
  comment_count: number;
  year_range: string;
  origin: string;
  dimensions: string;
  weight: string;
  collection_place: string;
  tags: string[];
  historical_background: string;
  cultural_significance: string;
  images: ApiArtworkImage[];
  audio_guide: ApiAudioGuide | null;
  create_time: string;
}

interface ApiArtworkListResponse {
  artworks: ApiArtworkOut[];
  total: number;
  page: number;
  page_size: number;
}

interface ApiLikeResult {
  is_liked: boolean;
  like_count: number;
}

interface ApiFavoriteResult {
  is_favorited: boolean;
  favorite_count: number;
}

interface ApiCommentOut {
  id: string;
  artwork_id: string;
  user_id: string;
  username: string;
  avatar: string;
  content: string;
  parent_id: string;
  created_at: string;
  like_count: number;
  is_liked: boolean;
  replies: ApiCommentOut[];
}

// ──────── 点赞/收藏同步 API 响应类型 ────────

interface ApiSyncIdsResponse {
  artwork_ids: string[];
}

// ──────── 工具类型 ────────

class ToggleResult {
  isLiked: boolean = false;
  likeCount: number = 0;
}

class FavoriteResult {
  isFavorited: boolean = false;
  favoriteCount: number = 0;
}

class CommentLikeResult {
  isLiked: boolean = false;
  likeCount: number = 0;
}

// ──────── 字段映射函数 ────────

function mapArtworkImage(img: ApiArtworkImage): ArtworkImage {
  const ai = new ArtworkImage();
  ai.id = img.id;
  ai.url = img.url;
  ai.thumbnailUrl = img.thumbnail_url;
  ai.title = img.title;
  ai.description = img.description;
  ai.width = img.width || 0;
  ai.height = img.height || 0;
  return ai;
}

interface ApiCommentLikeResponse {
  is_liked: boolean;
  like_count: number;
}

function mapAudioGuide(ag: ApiAudioGuide): AudioGuide {
  const guide = new AudioGuide();
  guide.id = ag.id;
  guide.url = ag.url;
  guide.duration = ag.duration || 0;
  guide.narrator = ag.narrator || '';
  guide.textScript = ag.text_script || '';
  return guide;
}

function mapArtwork(api: ApiArtworkOut, isLiked?: boolean, isFavorited?: boolean): Artwork {
  const a = new Artwork();
  a.id = api.id;
  a.name = api.name;
  a.dynasty = api.dynasty as Dynasty;
  a.type = api.type || '';
  a.material = api.material || '';
  a.description = api.description || '';
  a.detailDescription = api.detail_description || '';
  a.coverImage = api.cover_image || '';
  a.popularity = api.popularity || 0;
  a.likeCount = api.like_count || 0;
  a.favoriteCount = api.favorite_count || 0;
  a.commentCount = api.comment_count || 0;
  a.isLiked = isLiked === true;
  a.isFavorited = isFavorited === true;
  a.yearRange = api.year_range || '';
  a.origin = api.origin || '';
  a.dimensions = api.dimensions || '';
  a.weight = api.weight || '';
  a.collectionPlace = api.collection_place || '';
  a.tags = api.tags || [];
  a.historicalBackground = api.historical_background || '';
  a.culturalSignificance = api.cultural_significance || '';
  a.images = (api.images || []).map(mapArtworkImage);
  if (api.audio_guide) {
    a.audioGuide = mapAudioGuide(api.audio_guide);
  }
  // createTime: 后端可能是 ISO 字符串，转为时间戳
  if (api.create_time) {
    const ts = Date.parse(api.create_time);
    a.createTime = isNaN(ts) ? Date.now() : ts;
  } else {
    a.createTime = Date.now();
  }
  return a;
}

function mapComment(c: ApiCommentOut): Comment {
  const comment = new Comment();
  comment.id = String(c.id);
  comment.artworkId = c.artwork_id;
  comment.userId = String(c.user_id);
  comment.username = c.username;
  comment.userAvatar = c.avatar || '';
  comment.content = c.content;
  comment.likeCount = c.like_count || 0;
  comment.replyCount = c.replies ? c.replies.length : 0;
  comment.isLiked = c.is_liked || false;
  comment.parentId = c.parent_id ? String(c.parent_id) : '';
  comment.reviewStatus = ReviewStatus.APPROVED;
  if (c.created_at) {
    const ts = Date.parse(c.created_at);
    comment.createTime = isNaN(ts) ? Date.now() : ts;
  }
  comment.replies = (c.replies || []).map(r => {
    const reply = new ReplyComment();
    reply.id = String(r.id);
    reply.commentId = String(c.id);
    reply.userId = String(r.user_id);
    reply.username = r.username;
    reply.userAvatar = r.avatar || '';
    reply.content = r.content;
    reply.replyToUserId = String(r.user_id);
    reply.replyToUsername = r.username;
    reply.likeCount = r.like_count || 0;
    reply.isLiked = r.is_liked || false;
    reply.reviewStatus = ReviewStatus.APPROVED;
    if (r.created_at) {
      const ts = Date.parse(r.created_at);
      reply.createTime = isNaN(ts) ? Date.now() : ts;
    }
    return reply;
  });
  return comment;
}

// ──────── 文物服务 ────────

export class ArtworkService {
  private static instance: ArtworkService;
  private allArtworks: Artwork[];
  private cacheLoaded: boolean = false;
  private totalCount: number = 0;
  private likedIds: Set<string>;
  private collectedIds: Set<string>;
  private isInitialized: boolean = false;

  private constructor() {
    this.allArtworks = [];
    this.likedIds = new Set();
    this.collectedIds = new Set();
  }

  static getInstance(): ArtworkService {
    if (!ArtworkService.instance) {
      ArtworkService.instance = new ArtworkService();
    }
    return ArtworkService.instance;
  }

  // ════════════ 初始化 ════════════

  /** 初始化：加载数据（在应用启动时调用） */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    try {
      await this.fetchArtworks();
      this.isInitialized = true;
    } catch (e) {
      console.error(`ArtworkService 初始化失败: ${(e as Error).message}`);
      // 初始化失败不阻止应用运行
    }
  }

  // ════════════ 数据加载（异步 API 调用） ════════════

  /** 从后端加载文物列表（分页） */
  async fetchArtworks(
    sortType: SortType = SortType.DEFAULT,
    page: number = 1,
    dynasty?: string,
    pageSize: number = Constants.PAGE_SIZE,
  ): Promise<Artwork[]> {
    const params: Record<string, string> = {} as Record<string, string>;
    params['page'] = page.toString();
    params['page_size'] = pageSize.toString();
    if (sortType !== SortType.DEFAULT) {
      params['sort'] = sortType;
    }
    if (dynasty && dynasty !== '全部') {
      params['dynasty'] = dynasty;
    }

    try {
      const http = HttpClient.getInstance();
      const response = await http.get<ApiArtworkListResponse>('/api/artworks', params);

      this.allArtworks = response.artworks.map(a => mapArtwork(a));
      this.totalCount = response.total;
      this.cacheLoaded = true;

      // 同步加载点赞/收藏状态
      await this.syncUserFlags();

      return this.allArtworks;
    } catch (e) {
      console.error(`获取文物列表失败: ${(e as Error).message}`);
      // 后端不可用时加载 Mock 数据
      if (!this.cacheLoaded) {
        this.allArtworks = MockArtworks.getArtworks();
        this.totalCount = this.allArtworks.length;
        this.cacheLoaded = true;
      }
      return this.allArtworks;
    }
  }

  /** 从后端加载全量文物（用于首页无分页展示） */
  async fetchAllArtworks(sortType: SortType = SortType.DEFAULT): Promise<Artwork[]> {
    // page_size 最大 100（后端限制），大于文物总数即可取全
    return this.fetchArtworks(sortType, 1, undefined, 100);
  }

  /** 从后端加载单件文物详情 */
  async fetchArtworkById(id: string): Promise<Artwork | undefined> {
    const http = HttpClient.getInstance();
    try {
      const response = await http.get<ApiArtworkOut>(`/api/artworks/${id}`);
      const artwork = mapArtwork(response);

      // 更新缓存
      const idx = this.allArtworks.findIndex(a => a.id === id);
      if (idx >= 0) {
        this.allArtworks[idx] = artwork;
      } else {
        this.allArtworks.push(artwork);
      }

      // 合并用户状态
      artwork.isLiked = this.likedIds.has(id);
      artwork.isFavorited = this.collectedIds.has(id);

      return artwork;
    } catch (e) {
      console.error(`获取文物详情失败: ${(e as Error).message}`);
      return undefined;
    }
  }

  /** 从后端加载每日推荐 */
  async fetchDailyRecommendation(): Promise<Artwork | null> {
    const http = HttpClient.getInstance();
    try {
      const response = await http.get<ApiArtworkOut>('/api/artworks/daily');
      const artwork = mapArtwork(response);

      // 合并用户状态
      artwork.isLiked = this.likedIds.has(artwork.id);
      artwork.isFavorited = this.collectedIds.has(artwork.id);

      return artwork;
    } catch (e) {
      console.error(`获取每日推荐失败: ${(e as Error).message}`);
      return null;
    }
  }

  /** 搜索文物 */
  async searchArtworks(keyword: string, page: number = 1): Promise<ArtworkSearchResult> {
    const http = HttpClient.getInstance();
    try {
      const searchParams: Record<string, string> = {} as Record<string, string>;
      searchParams['keyword'] = keyword;
      searchParams['page'] = page.toString();
      searchParams['page_size'] = Constants.SEARCH_PAGE_SIZE.toString();
      const response = await http.get<ApiArtworkListResponse>('/api/artworks/search', searchParams);

      const result = new ArtworkSearchResult();
      result.artworks = response.artworks.map(a => mapArtwork(a));
      result.totalCount = response.total;
      result.searchTime = Date.now();

      // 合并用户状态
      for (const artwork of result.artworks) {
        artwork.isLiked = this.likedIds.has(artwork.id);
        artwork.isFavorited = this.collectedIds.has(artwork.id);
      }

      return result;
    } catch (e) {
      console.error(`搜索文物失败: ${(e as Error).message}`);
      const result = new ArtworkSearchResult();
      result.artworks = [];
      result.totalCount = 0;
      result.searchTime = Date.now();
      return result;
    }
  }

  /** 批量获取文物（用于浏览历史、点赞列表等） */
  async fetchArtworksByIds(ids: string[]): Promise<Artwork[]> {
    if (ids.length === 0) {
      return [];
    }
    const http = HttpClient.getInstance();
    try {
      const batchParams: Record<string, string> = {} as Record<string, string>;
      batchParams['ids'] = ids.join(',');
      const response = await http.get<ApiArtworkOut[]>('/api/artworks/batch', batchParams);
      const artworks = response.map(a => mapArtwork(a));
      for (const artwork of artworks) {
        artwork.isLiked = this.likedIds.has(artwork.id);
        artwork.isFavorited = this.collectedIds.has(artwork.id);
      }
      return artworks;
    } catch (e) {
      console.error(`批量获取文物失败: ${(e as Error).message}`);
      return [];
    }
  }

  /** 加载用户的点赞/收藏 ID 列表，同步到缓存中的文物 */
  private async syncUserFlags(): Promise<void> {
    const http = HttpClient.getInstance();
    if (!http.isLoggedIn()) {
      this.likedIds.clear();
      this.collectedIds.clear();
      return;
    }

    try {
      // 获取点赞列表（后端返回 {artwork_ids: [...]}）
      const likesResponse = await http.get<ApiSyncIdsResponse>('/api/likes');
      this.likedIds = new Set(likesResponse.artwork_ids || []);

      // 获取收藏列表（后端返回 {artwork_ids: [...]}）
      const collResponse = await http.get<ApiSyncIdsResponse>('/api/collections');
      this.collectedIds = new Set(collResponse.artwork_ids || []);

      // 更新缓存中的标志
      for (const artwork of this.allArtworks) {
        artwork.isLiked = this.likedIds.has(artwork.id);
        artwork.isFavorited = this.collectedIds.has(artwork.id);
      }
    } catch (e) {
      // 用户可能未登录，忽略错误
      console.info('获取用户点赞/收藏状态失败（可能未登录）');
    }
  }

  // ════════════ 同步访问（从本地缓存返回） ════════════

  /** 获取文物列表（同步，从缓存返回，分页） */
  getArtworks(sortType: SortType = SortType.DEFAULT, page: number = 1): Artwork[] {
    if (!this.cacheLoaded) {
      return [];
    }
    let sorted = [...this.allArtworks];
    switch (sortType) {
      case SortType.POPULAR:
        // 热度 = 点赞 + 收藏 + 评论总数
        sorted.sort((a, b) =>
          (b.likeCount + b.favoriteCount + b.commentCount) -
          (a.likeCount + a.favoriteCount + a.commentCount));
        break;
      case SortType.DYNASTY:
        sorted.sort((a, b) => this.dynastyOrder(a.dynasty) - this.dynastyOrder(b.dynasty));
        break;
      case SortType.TYPE:
        sorted.sort((a, b) => a.type.localeCompare(b.type));
        break;
      default:
        break;
    }
    const start = (page - 1) * Constants.PAGE_SIZE;
    return sorted.slice(start, start + Constants.PAGE_SIZE);
  }

  /** 获取全量文物列表（同步，从缓存返回，不分页） */
  getAllArtworks(sortType: SortType = SortType.DEFAULT): Artwork[] {
    if (!this.cacheLoaded) {
      return [];
    }
    let sorted = [...this.allArtworks];
    switch (sortType) {
      case SortType.POPULAR:
        sorted.sort((a, b) =>
          (b.likeCount + b.favoriteCount + b.commentCount) -
          (a.likeCount + a.favoriteCount + a.commentCount));
        break;
      case SortType.DYNASTY:
        sorted.sort((a, b) => this.dynastyOrder(a.dynasty) - this.dynastyOrder(b.dynasty));
        break;
      case SortType.TYPE:
        sorted.sort((a, b) => a.type.localeCompare(b.type));
        break;
      default:
        break;
    }
    return sorted;
  }

  /** 获取单个文物（同步，从缓存返回） */
  getArtworkById(id: string): Artwork | undefined {
    return this.allArtworks.find(a => a.id === id);
  }

  /** 获取每日推荐（同步，从缓存返回） */
  getDailyRecommendation(): Artwork | null {
    if (this.allArtworks.length > 0) {
      const today = new Date();
      const index = today.getDate() % this.allArtworks.length;
      return this.allArtworks[index];
    }
    return null;
  }

  /** 批量获取（同步，从缓存返回） */
  getArtworksByIds(ids: string[]): Artwork[] {
    return ids.map(id => this.allArtworks.find(a => a.id === id))
      .filter(a => a !== undefined) as Artwork[];
  }

  /** 缓存是否已加载 */
  isCacheLoaded(): boolean {
    return this.cacheLoaded;
  }

  /** 获取总记录数 */
  getTotalCount(): number {
    return this.totalCount;
  }

  // ════════════ 点赞 ════════════

  /** 切换点赞状态（异步） */
  async toggleLike(artworkId: string): Promise<ToggleResult> {
    console.info(`toggleLike 被调用, artworkId=${artworkId}`);
    const http = HttpClient.getInstance();
    const result = new ToggleResult();

    const isCurrentlyLiked = this.likedIds.has(artworkId);
    try {
      if (isCurrentlyLiked) {
        // 取消点赞
        await http.delete<ApiLikeResult>(`/api/likes/${artworkId}`);
        this.likedIds.delete(artworkId);
        UserService.getInstance().removeLike(artworkId);
        result.isLiked = false;
      } else {
        // 点赞
        await http.post<ApiLikeResult>(`/api/likes/${artworkId}`);
        this.likedIds.add(artworkId);
        UserService.getInstance().addLike(artworkId);
        result.isLiked = true;
      }

      // 更新缓存中的计数和状态
      const artwork = this.allArtworks.find(a => a.id === artworkId);
      if (artwork) {
        artwork.isLiked = result.isLiked;
        artwork.likeCount += result.isLiked ? 1 : -1;
      }
      result.likeCount = artwork?.likeCount || 0;

      // 通知各页面刷新
      try {
        AppStorage.SetOrCreate<number>('userDataRefresh', Date.now());
      } catch (_) {
      }
    } catch (e) {
      console.error(`切换点赞失败: ${(e as Error).message}`);
      throw new Error((e as Error).message);
    }

    return result;
  }

  /** 获取点赞列表 */
  getLikedIds(): string[] {
    return Array.from(this.likedIds);
  }

  /** 检查是否已点赞 */
  isLiked(artworkId: string): boolean {
    return this.likedIds.has(artworkId);
  }

  // ════════════ 收藏 ════════════

  /** 切换收藏状态（异步） */
  async toggleFavorite(artworkId: string): Promise<FavoriteResult> {
    const http = HttpClient.getInstance();
    const result = new FavoriteResult();

    const isCurrentlyCollected = this.collectedIds.has(artworkId);
    try {
      if (isCurrentlyCollected) {
        await http.delete<ApiFavoriteResult>(`/api/collections/${artworkId}`);
        this.collectedIds.delete(artworkId);
        UserService.getInstance().removeCollection(artworkId);
        result.isFavorited = false;
      } else {
        await http.post<ApiFavoriteResult>(`/api/collections/${artworkId}`);
        this.collectedIds.add(artworkId);
        UserService.getInstance().addCollection(artworkId);
        result.isFavorited = true;
      }

      const artwork = this.allArtworks.find(a => a.id === artworkId);
      if (artwork) {
        artwork.isFavorited = result.isFavorited;
        artwork.favoriteCount += result.isFavorited ? 1 : -1;
      }
      result.favoriteCount = artwork?.favoriteCount || 0;

      // 通知各页面刷新
      try {
        AppStorage.SetOrCreate<number>('userDataRefresh', Date.now());
      } catch (_) {
      }
    } catch (e) {
      console.error(`切换收藏失败: ${(e as Error).message}`);
      throw new Error((e as Error).message);
    }

    return result;
  }

  /** 获取收藏列表 */
  getCollectedIds(): string[] {
    return Array.from(this.collectedIds);
  }

  /** 检查是否已收藏 */
  isFavorited(artworkId: string): boolean {
    return this.collectedIds.has(artworkId);
  }

  // ════════════ 评论 ════════════

  /** 获取文物评论（异步） */
  async fetchComments(artworkId: string): Promise<Comment[]> {
    const http = HttpClient.getInstance();
    try {
      const response = await http.get<ApiCommentOut[]>(`/api/comments/${artworkId}`);
      const comments = response ? response.map(mapComment) : [];

      // 更新缓存中的评论数
      const artwork = this.allArtworks.find(a => a.id === artworkId);
      if (artwork) {
        artwork.commentCount = comments.length;
      }

      return comments;
    } catch (e) {
      console.error(`获取评论失败: ${(e as Error).message}`);
      return [];
    }
  }

  /** 添加评论（异步） */
  async addComment(
    artworkId: string,
    content: string,
    parentId?: string,
  ): Promise<Comment | null> {
    const http = HttpClient.getInstance();
    try {
      const body: Record<string, Object> = {} as Record<string, Object>;
      body['artwork_id'] = artworkId;
      body['content'] = content;
      if (parentId) {
        body['parent_id'] = parentId;
      }
      const response = await http.post<ApiCommentOut>('/api/comments', body);
      const comment = mapComment(response);

      // 更新缓存中的评论数
      const artwork = this.allArtworks.find(a => a.id === artworkId);
      if (artwork) {
        artwork.commentCount += 1;
      }

      return comment;
    } catch (e) {
      console.error(`添加评论失败: ${(e as Error).message}`);
      return null;
    }
  }

  // ════════════ 评论点赞 ════════════

  /** 切换评论点赞状态 */
  async toggleCommentLike(commentId: string): Promise<CommentLikeResult | null> {
    const http = HttpClient.getInstance();
    try {
      // 先尝试 POST 点赞，如果返回 409（已点赞）则改调 DELETE 取消点赞
      try {
        const result = await http.post<ApiCommentLikeResponse>(`/api/comments/${commentId}/like`);
        const likeResult = new CommentLikeResult();
        likeResult.isLiked = result.is_liked;
        likeResult.likeCount = result.like_count;
        return likeResult;
      } catch (postErr) {
        const msg = (postErr as Error).message;
        if (msg.includes('已经点过赞了') || msg.includes('409')) {
          const result = await http.delete<ApiCommentLikeResponse>(`/api/comments/${commentId}/like`);
          const likeResult = new CommentLikeResult();
          likeResult.isLiked = result.is_liked;
          likeResult.likeCount = result.like_count;
          return likeResult;
        }
        throw new Error(msg);
      }
    } catch (e) {
      console.error(`评论点赞失败: ${(e as Error).message}`);
      return null;
    }
  }

  // ════════════ 工具方法 ════════════

  private dynastyOrder(dynasty: Dynasty): number {
    const order = [
      Dynasty.XIA, Dynasty.SHANG, Dynasty.ZHOU, Dynasty.SPRING_AUTUMN,
      Dynasty.WARRING, Dynasty.QIN, Dynasty.HAN, Dynasty.THREE_KINGDOMS,
      Dynasty.JIN, Dynasty.SOUTH_NORTH, Dynasty.SUI, Dynasty.TANG,
      Dynasty.SONG, Dynasty.LIAO, Dynasty.JIN_DYNASTY, Dynasty.YUAN,
      Dynasty.MING, Dynasty.QING, Dynasty.MODERN
    ];
    return order.indexOf(dynasty);
  }

  getDynasties(): Dynasty[] {
    const dynasties = new Set<Dynasty>();
    this.allArtworks.forEach(a => dynasties.add(a.dynasty));
    return Array.from(dynasties).sort((a, b) => this.dynastyOrder(a) - this.dynastyOrder(b));
  }

  getTypes(): string[] {
    const types = new Set<string>();
    this.allArtworks.forEach(a => types.add(a.type));
    return Array.from(types);
  }
}
