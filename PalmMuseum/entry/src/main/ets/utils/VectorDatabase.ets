import { Artwork, ImageSearchResult } from '../model/Artwork';
import { ImageFeatureExtractor } from './ImageFeatureExtractor';
import { Constants } from './Constants';

class SearchResultItem {
  artworkId: string = '';
  score: number = 0;
}

/**
 * 向量数据库 - 以图搜图核心组件
 *
 * 真实实现推荐方案：
 * - 内存方案：FAISS (Facebook AI Similarity Search) for轻量级场景
 * - 持久化方案：Milvus或Qdrant向量数据库
 * - HarmonyOS方案：使用系统SQLite存储特征向量的二进制序列化数据
 *
 * 当前实现：基于内存的暴力搜索（适用于万级以下数据量）
 * 优化方案：当数据量超过10000条时，应切换为IVF（倒排文件索引）
 * 或HNSW（分层可导航小世界图）索引
 */
export class VectorDatabase {
  private static instance: VectorDatabase;
  private featureStore: Map<string, number[]> = new Map();
  private isInitialized: boolean = false;

  private constructor() {}

  static getInstance(): VectorDatabase {
    if (!VectorDatabase.instance) {
      VectorDatabase.instance = new VectorDatabase();
    }
    return VectorDatabase.instance;
  }

  /**
   * 初始化向量数据库，加载所有文物的特征向量
   */
  initialize(artworks: Artwork[]): void {
    if (this.isInitialized) return;

    artworks.forEach(artwork => {
      if (artwork.imageFeature && artwork.imageFeature.length > 0) {
        this.featureStore.set(artwork.id, artwork.imageFeature);
      }
    });

    console.info(`VectorDatabase initialized with ${this.featureStore.size} features`);
    this.isInitialized = true;
  }

  /**
   * 搜索相似文物
   *
   * @param queryFeature 查询图像的特征向量
   * @param topK 返回前K个结果
   * @param artworks 文物数据列表（用于构建结果对象）
   * @returns 按相似度降序排列的结果列表
   */
  search(queryFeature: number[], topK: number,
    artworks: Artwork[]): ImageSearchResult[] {

    if (!this.isInitialized) {
      console.warn('VectorDatabase not initialized');
      return [];
    }

    const artworkMap = new Map<string, Artwork>();
    artworks.forEach(a => artworkMap.set(a.id, a));

    const results: SearchResultItem[] = [];

    // 计算查询向量与所有存储向量的余弦相似度
    this.featureStore.forEach((feature, artworkId) => {
      const similarity = ImageFeatureExtractor.cosineSimilarity(queryFeature, feature);
      const item = new SearchResultItem();
      item.artworkId = artworkId;
      item.score = similarity;
      results.push(item);
    });

    // 按相似度降序排列
    results.sort((a, b) => b.score - a.score);

    // 过滤低于阈值的结果，取前topK个
    const filtered = results
      .filter(r => r.score >= Constants.IMAGE_SIMILARITY_THRESHOLD)
      .slice(0, topK);

    return filtered.map(r => {
      const artwork = artworkMap.get(r.artworkId);
      return new ImageSearchResult(
        artwork || new Artwork(),
        Math.round(r.score * 10000) / 100 // 转换为百分比，保留两位小数
      );
    });
  }

  /**
   * 添加新的特征向量到数据库
   */
  addFeature(artworkId: string, feature: number[]): void {
    this.featureStore.set(artworkId, feature);
  }

  /**
   * 从数据库移除特征向量
   */
  removeFeature(artworkId: string): void {
    this.featureStore.delete(artworkId);
  }

  /**
   * 获取数据库中的特征数量
   */
  get size(): number {
    return this.featureStore.size;
  }

  /**
   * 清除所有特征
   */
  clear(): void {
    this.featureStore.clear();
    this.isInitialized = false;
  }
}
