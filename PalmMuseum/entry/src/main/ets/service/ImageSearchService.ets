/**
 * 以图搜图服务
 *
 * 连接后端 API 进行图像相似度搜索。
 * 上传图片到 /api/image-search 后端，返回相似文物列表。
 *
 * ─── 图片上传说明 ───
 * HarmonyOS 模拟器/真机中，图片上传使用 @ohos.net.http 的 multipart 支持。
 * 当前简化实现：通过 HttpClient 上传文件路径。
 *
 * ─── 回退策略 ───
 * 后端不可用时，自动降级到本地模拟结果。
 */
import { Artwork, ImageSearchResult } from '../model/Artwork';
import { ImageFeatureExtractor } from '../utils/ImageFeatureExtractor';
import { VectorDatabase } from '../utils/VectorDatabase';
import { MockArtworks } from '../data/MockArtworks';
import { Constants } from '../utils/Constants';
import { HttpClient } from './HttpClient';
import { ArtworkService } from './ArtworkService';

// ──────── API 响应类型 ────────

interface ApiImageSearchResult {
  artwork: Record<string, Object>;
  similarity_score: number;
}

interface ApiImageSearchResponse {
  results: ApiImageSearchResult[];
}

class ServiceStatus {
  isReady: boolean = false;
  featureCount: number = 0;
}

export class ImageSearchService {
  private static instance: ImageSearchService;
  private vectorDB: VectorDatabase;
  private allArtworks: Artwork[];
  private isReady: boolean = false;

  private constructor() {
    this.vectorDB = VectorDatabase.getInstance();
    this.allArtworks = MockArtworks.getArtworks();
  }

  static getInstance(): ImageSearchService {
    if (!ImageSearchService.instance) {
      ImageSearchService.instance = new ImageSearchService();
    }
    return ImageSearchService.instance;
  }

  initialize(): void {
    if (!this.isReady) {
      this.vectorDB.initialize(this.allArtworks);
      this.isReady = true;
      console.info('ImageSearchService initialized with vector database');
    }
  }

  /**
   * 从图片路径搜索相似文物
   * 优先调用后端 API，失败时降级到本地模拟
   */
  async searchByImage(imagePath: string): Promise<ImageSearchResult[]> {
    console.info(`ImageSearch: searching by image path: ${imagePath}`);

    const http = HttpClient.getInstance();
    try {
      // 尝试调用后端 API
      const response = await http.uploadFile<ApiImageSearchResponse>(
        '/api/image-search',
        imagePath
      );

      // 将 API 结果转换为前端模型
      const artworkService = ArtworkService.getInstance();
      const results: ImageSearchResult[] = [];

      for (const item of response.results || []) {
        const artMap = item.artwork;
        const artworkId = artMap['id'] as string;

        // 从缓存中查找文物
        let artwork = artworkService.getArtworkById(artworkId);

        // 如果缓存中没有，从 API 响应构建
        if (!artwork) {
          artwork = this.apiMapToArtwork(artMap);
        }

        if (artwork) {
          results.push(new ImageSearchResult(artwork, item.similarity_score));
        }
      }

      if (results.length > 0) {
        return results.sort((a, b) => b.similarityScore - a.similarityScore);
      }
    } catch (e) {
      console.warn(`后端图像搜索失败，降级到本地模拟: ${(e as Error).message}`);
    }

    // 降级到本地模拟搜索
    return this.searchMock();
  }

  /**
   * 从相机像素数据搜索（当前使用 mock）
   */
  async searchByCamera(pixels: ArrayBuffer, width: number,
    height: number): Promise<ImageSearchResult[]> {
    console.info(`ImageSearch: searching by camera capture: ${width}x${height}`);

    // 尝试后端 API（同上）
    // 由于相机数据无法直接上传，降级到本地模拟
    return this.searchMock();
  }

  /**
   * 模拟搜索（后端不可用时降级）
   */
  async searchMock(): Promise<ImageSearchResult[]> {
    await new Promise<void>(resolve => setTimeout(resolve, 800));

    const shuffled = [...this.allArtworks].sort(() => Math.random() - 0.5);
    const count = Math.min(10, shuffled.length);

    const results: ImageSearchResult[] = [];
    for (let i = 0; i < count; i++) {
      const score = Math.max(0.35, 0.98 - i * 0.07);
      results.push(new ImageSearchResult(shuffled[i], Math.round(score * 10000) / 100));
    }

    return results.sort((a, b) => b.similarityScore - a.similarityScore);
  }

  /** 将 API 的扁平对象映射为 Artwork 模型 */
  private apiMapToArtwork(api: Record<string, Object>): Artwork | undefined {
    try {
      const id = api['id'] as string;
      if (!id) {
        return undefined;
      }
      // 从 Mock 数据中获取
      return this.allArtworks.find(a => a.id === id) || undefined;
    } catch (_) {
      return undefined;
    }
  }

  getStatus(): ServiceStatus {
    const status = new ServiceStatus();
    status.isReady = this.isReady;
    status.featureCount = this.vectorDB.size;
    return status;
  }

  addArtworkFeature(artwork: Artwork): void {
    if (artwork.imageFeature) {
      this.vectorDB.addFeature(artwork.id, artwork.imageFeature);
      this.allArtworks.push(artwork);
    }
  }
}
