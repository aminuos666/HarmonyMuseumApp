import { Artwork, ArtworkSearchResult } from '../model/Artwork';
import { MockArtworks } from '../data/MockArtworks';
import { Dynasty, Constants } from '../utils/Constants';

export class SearchService {
  private static instance: SearchService;
  private allArtworks: Artwork[];

  private constructor() {
    this.allArtworks = MockArtworks.getArtworks();
  }

  static getInstance(): SearchService {
    if (!SearchService.instance) {
      SearchService.instance = new SearchService();
    }
    return SearchService.instance;
  }

  search(keyword: string, page: number = 1): ArtworkSearchResult {
    const query = keyword.trim().toLowerCase();
    if (!query) {
      return new ArtworkSearchResult();
    }

    const results = this.allArtworks.filter(artwork => {
      return this.matchArtwork(artwork, query);
    });

    // 按相关度排序
    results.sort((a, b) => {
      return this.relevanceScore(b, query) - this.relevanceScore(a, query);
    });

    const totalCount = results.length;
    const start = (page - 1) * Constants.SEARCH_PAGE_SIZE;
    const pageResults = results.slice(start, start + Constants.SEARCH_PAGE_SIZE);

    // 提取相关标签
    const tagCount = new Map<string, number>();
    results.forEach(a => {
      a.tags.forEach(t => {
        tagCount.set(t, (tagCount.get(t) || 0) + 1);
      });
    });
    const relatedTags = Array.from(tagCount.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(e => e[0]);

    const result = new ArtworkSearchResult();
    result.artworks = pageResults;
    result.totalCount = totalCount;
    result.relatedTags = relatedTags;
    result.searchTime = Date.now();
    return result;
  }

  private matchArtwork(artwork: Artwork, query: string): boolean {
    // 名称匹配
    if (artwork.name.toLowerCase().includes(query)) return true;

    // 朝代匹配
    if (artwork.dynasty.toLowerCase().includes(query)) return true;

    // 类型匹配
    if (artwork.type.toLowerCase().includes(query)) return true;

    // 材质匹配
    if (artwork.material.toLowerCase().includes(query)) return true;

    // 描述匹配
    if (artwork.description.toLowerCase().includes(query)) return true;
    if (artwork.detailDescription.toLowerCase().includes(query)) return true;
    if (artwork.historicalBackground.toLowerCase().includes(query)) return true;
    if (artwork.culturalSignificance.toLowerCase().includes(query)) return true;

    // 出土地点匹配
    if (artwork.origin.toLowerCase().includes(query)) return true;

    // 收藏地点匹配
    if (artwork.collectionPlace.toLowerCase().includes(query)) return true;

    // 标签匹配
    for (const tag of artwork.tags) {
      if (tag.toLowerCase().includes(query)) return true;
    }

    return false;
  }

  private relevanceScore(artwork: Artwork, query: string): number {
    let score = 0;

    // 名称精确匹配加分最多
    if (artwork.name.toLowerCase().includes(query)) {
      score += 100;
      if (artwork.name.toLowerCase() === query) score += 50;
    }

    // 朝代匹配
    if (artwork.dynasty.toLowerCase().includes(query)) score += 30;

    // 标签匹配
    artwork.tags.forEach(t => {
      if (t.toLowerCase().includes(query)) score += 20;
    });

    // 热度加分
    score += artwork.popularity / 1000;

    return score;
  }

  getSearchSuggestions(prefix: string): string[] {
    const p = prefix.trim().toLowerCase();
    if (!p) return [];

    const suggestions = new Set<string>();
    this.allArtworks.forEach(a => {
      if (a.name.includes(p)) suggestions.add(a.name);
      a.tags.forEach(t => {
        if (t.includes(p)) suggestions.add(t);
      });
      if (a.dynasty.includes(p)) suggestions.add(a.dynasty);
    });

    return Array.from(suggestions).slice(0, 8);
  }

  // 语音搜索（直接处理语音识别文本）
  voiceSearch(recognizedText: string): ArtworkSearchResult {
    console.info(`Voice search: ${recognizedText}`);
    return this.search(recognizedText);
  }
}
