/**
 * 以图搜图服务
 *
 * 上传图片到后端 /api/image-search，后端提取图像特征后
 * 与数据库中预存的特征向量计算余弦相似度，返回匹配结果。
 *
 * ─── 回退策略 ───
 * 后端不可用时，自动降级到本地模拟结果。
 */
import { Artwork, ArtworkImage, AudioGuide, ImageSearchResult } from '../model/Artwork';
import { Dynasty } from '../utils/Constants';
import { MockArtworks } from '../data/MockArtworks';
import { HttpClient } from './HttpClient';
import { ArtworkService } from './ArtworkService';
import { BusinessError, request } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// ──────── API 响应类型 ────────

interface ApiImageSearchResultItem {
  artwork: Record<string, Object>;
  similarity_score: number;
}

interface ApiImageSearchResponse {
  results: ApiImageSearchResultItem[];
}

class ServiceStatus {
  isReady: boolean = false;
  featureCount: number = 0;
}

export class ImageSearchService {
  private static instance: ImageSearchService;
  private allArtworks: Artwork[];

  private constructor() {
    this.allArtworks = MockArtworks.getArtworks();
  }

  static getInstance(): ImageSearchService {
    if (!ImageSearchService.instance) {
      ImageSearchService.instance = new ImageSearchService();
    }
    return ImageSearchService.instance;
  }

  initialize(): void {
    console.info('ImageSearchService initialized');
  }

  /**
   * 从图片 URI 搜索相似文物（使用 HttpClient）
   */
  async searchByImageUri(imageUri: string): Promise<ImageSearchResult[]> {
    console.info(`ImageSearch: searching by image URI: ${imageUri}`);

    const http = HttpClient.getInstance();
    try {
      const response = await http.uploadFile<ApiImageSearchResponse>(
        '/api/image-search',
        imageUri
      );

      if (response.results && response.results.length > 0) {
        console.info(`ImageSearch: 【成功】API 返回 ${response.results.length} 条结果`);
        return this.mapApiResults(response.results);
      } else {
        console.error(`ImageSearch: 【失败】API 返回空结果`);
      }
    } catch (e) {
      console.error(`ImageSearch: 【异常】上传失败: ${(e as Error).message}`);
    }

    console.error(`ImageSearch: 【降级】使用 Mock 数据代替`);
    return this.searchMock();
  }

  /**
   * 从相机拍照搜索（使用 URI 方式）
   */
  async searchByCamera(imageUri: string): Promise<ImageSearchResult[]> {
    console.info(`ImageSearch: camera capture URI: ${imageUri}`);
    return this.searchByImageUri(imageUri);
  }

  /**
   * 从图片 URI 搜索相似文物（使用 HarmonyOS 原生上传 API）
   * 专用于 file://media/ 这类系统内容 URI
   */
  async searchByImageUriNative(imageUri: string, context: common.UIAbilityContext): Promise<ImageSearchResult[]> {
    console.info(`ImageSearch: 【原生上传】URI=${imageUri}`);

    const http = HttpClient.getInstance();
    const url = `${http.getBaseUrl()}/api/image-search`;

    try {
      const result = await new Promise<ApiImageSearchResponse>((resolve, reject) => {
        const uploadConfig: request.UploadConfig = {
          url: url,
          header: { 'Authorization': `Bearer ${http.getToken()}` },
          method: 'POST',
          files: [{ filename: 'photo.jpg', name: 'file', uri: imageUri, type: 'image/jpeg' }],
          data: [],
        };

        request.uploadFile(context, uploadConfig).then((task: request.UploadTask) => {
          let responseBody = '';

          task.on('headerReceive', (header: object) => {
            const headerStr = JSON.stringify(header);
            const headerMap = JSON.parse(headerStr) as Record<string, string>;
            responseBody = headerMap['body'] || headerMap['data'] || '';
          });

          task.on('complete', () => {
            console.info(`ImageSearch: 【原生上传】完成`);
            if (responseBody) {
              try {
                const parsed = JSON.parse(responseBody) as ApiImageSearchResponse;
                resolve(parsed);
              } catch (e) {
                reject(new Error(`JSON解析失败: ${(e as Error).message}`));
              }
            } else {
              reject(new Error('响应体为空'));
            }
          });

          task.on('fail', (taskStates: Array<request.TaskState>) => {
            const errMsg = '上传失败';
            console.error(`ImageSearch: 【原生上传】失败`);
            reject(new Error(errMsg));
          });
        }).catch((err: BusinessError) => {
          console.error(`ImageSearch: 【原生上传】启动失败: ${err.message}`);
          reject(new Error(err.message));
        });
      });

      if (result.results && result.results.length > 0) {
        console.info(`ImageSearch: 【成功】原生上传返回 ${result.results.length} 条结果`);
        return this.mapApiResults(result.results);
      }
    } catch (e) {
      console.error(`ImageSearch: 【原生上传】异常: ${(e as Error).message}`);
    }

    console.error(`ImageSearch: 【降级】使用 Mock 数据代替`);
    return this.searchMock();
  }

  /**
   * 映射 API 结果到前端模型
   */
  private mapApiResults(apiResults: ApiImageSearchResultItem[]): ImageSearchResult[] {
    const results: ImageSearchResult[] = [];

    for (const item of apiResults) {
      const artwork = this.apiMapToArtwork(item.artwork);
      if (artwork) {
        results.push(new ImageSearchResult(artwork, item.similarity_score));
      }
    }

    return results.sort((a, b) => b.similarityScore - a.similarityScore);
  }

  /**
   * 将 API 返回的扁平对象映射为完整的 Artwork
   */
  private apiMapToArtwork(api: Record<string, Object>): Artwork | undefined {
    try {
      const id = api['id'] as string;
      if (!id) return undefined;

      const artwork = new Artwork();
      artwork.id = id;
      artwork.name = (api['name'] as string) || '';
      artwork.dynasty = (api['dynasty'] as string) as Dynasty || Dynasty.ALL;
      artwork.type = (api['type'] as string) || '';
      artwork.material = (api['material'] as string) || '';
      artwork.description = (api['description'] as string) || '';
      artwork.detailDescription = (api['detail_description'] as string) || '';
      artwork.coverImage = (api['cover_image'] as string) || '';
      artwork.popularity = (api['popularity'] as number) || 0;
      artwork.likeCount = (api['like_count'] as number) || 0;
      artwork.favoriteCount = (api['favorite_count'] as number) || 0;
      artwork.commentCount = (api['comment_count'] as number) || 0;
      artwork.yearRange = (api['year_range'] as string) || '';
      artwork.origin = (api['origin'] as string) || '';
      artwork.dimensions = (api['dimensions'] as string) || '';
      artwork.weight = (api['weight'] as string) || '';
      artwork.collectionPlace = (api['collection_place'] as string) || '';
      artwork.tags = (api['tags'] as string[]) || [];
      artwork.historicalBackground = (api['historical_background'] as string) || '';
      artwork.culturalSignificance = (api['cultural_significance'] as string) || '';

      const ct = api['create_time'] as string;
      if (ct) {
        const ts = Date.parse(ct);
        artwork.createTime = isNaN(ts) ? Date.now() : ts;
      }

      const apiImages = api['images'] as Record<string, Object>[];
      if (apiImages && Array.isArray(apiImages)) {
        artwork.images = apiImages.map(img => {
          const ai = new ArtworkImage();
          ai.id = (img['id'] as string) || '';
          ai.url = (img['url'] as string) || '';
          ai.thumbnailUrl = (img['thumbnail_url'] as string) || '';
          ai.title = (img['title'] as string) || '';
          ai.description = (img['description'] as string) || '';
          ai.width = (img['width'] as number) || 0;
          ai.height = (img['height'] as number) || 0;
          return ai;
        });
      }

      const apiAudio = api['audio_guide'] as Record<string, Object> | null;
      if (apiAudio) {
        const audio = new AudioGuide();
        audio.id = (apiAudio['id'] as string) || '';
        audio.url = (apiAudio['url'] as string) || '';
        audio.duration = (apiAudio['duration'] as number) || 0;
        audio.narrator = (apiAudio['narrator'] as string) || '';
        audio.textScript = (apiAudio['text_script'] as string) || '';
        artwork.audioGuide = audio;
      }

      const artworkService = ArtworkService.getInstance();
      artwork.isLiked = artworkService.isLiked(id);
      artwork.isFavorited = artworkService.isFavorited(id);

      return artwork;
    } catch (_) {
      return undefined;
    }
  }

  /**
   * 模拟搜索（后端不可用时降级）
   */
  async searchMock(): Promise<ImageSearchResult[]> {
    await new Promise<void>(resolve => setTimeout(resolve, 600));
    const shuffled = [...this.allArtworks].sort(() => Math.random() - 0.5);
    const count = Math.min(10, shuffled.length);
    const results: ImageSearchResult[] = [];
    for (let i = 0; i < count; i++) {
      const score = Math.max(35.0, 98.0 - i * 7.0);
      results.push(new ImageSearchResult(shuffled[i], Math.round(score * 10) / 10));
    }
    return results.sort((a, b) => b.similarityScore - a.similarityScore);
  }

  getStatus(): ServiceStatus {
    const status = new ServiceStatus();
    status.isReady = true;
    status.featureCount = -1;
    return status;
  }
}
