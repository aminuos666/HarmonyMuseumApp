import { Dynasty, ReviewStatus } from '../utils/Constants';

export class Artwork {
  id: string;
  name: string;
  dynasty: Dynasty;
  type: string;
  material: string;
  description: string;
  detailDescription: string;
  images: ArtworkImage[];
  coverImage: string;
  audioGuide?: AudioGuide;
  videoGuide?: VideoGuide;
  popularity: number;
  likeCount: number;
  favoriteCount: number;
  commentCount: number;
  isLiked: boolean;
  isFavorited: boolean;
  yearRange: string;
  origin: string;
  dimensions: string;
  weight: string;
  collectionPlace: string;
  tags: string[];
  historicalBackground: string;
  culturalSignificance: string;
  imageFeature?: number[]; // 图像特征向量（以图搜图用）
  createTime: number;

  constructor() {
    this.id = '';
    this.name = '';
    this.dynasty = Dynasty.ALL;
    this.type = '';
    this.material = '';
    this.description = '';
    this.detailDescription = '';
    this.images = [];
    this.coverImage = '';
    this.popularity = 0;
    this.likeCount = 0;
    this.favoriteCount = 0;
    this.commentCount = 0;
    this.isLiked = false;
    this.isFavorited = false;
    this.yearRange = '';
    this.origin = '';
    this.dimensions = '';
    this.weight = '';
    this.collectionPlace = '';
    this.tags = [];
    this.historicalBackground = '';
    this.culturalSignificance = '';
    this.createTime = Date.now();
  }
}

export class ArtworkImage {
  id: string;
  url: string;
  thumbnailUrl: string;
  title: string;
  description: string;
  width: number;
  height: number;

  constructor() {
    this.id = '';
    this.url = '';
    this.thumbnailUrl = '';
    this.title = '';
    this.description = '';
    this.width = 0;
    this.height = 0;
  }
}

export class AudioGuide {
  id: string;
  url: string;
  duration: number; // 秒
  narrator: string;
  textScript: string;

  constructor() {
    this.id = '';
    this.url = '';
    this.duration = 0;
    this.narrator = '';
    this.textScript = '';
  }
}

export class VideoGuide {
  id: string;
  url: string;
  coverUrl: string;
  duration: number;
  title: string;
  description: string;

  constructor() {
    this.id = '';
    this.url = '';
    this.coverUrl = '';
    this.duration = 0;
    this.title = '';
    this.description = '';
  }
}

export class ArtworkSearchResult {
  artworks: Artwork[];
  totalCount: number;
  searchTime: number;
  relatedTags: string[];

  constructor() {
    this.artworks = [];
    this.totalCount = 0;
    this.searchTime = 0;
    this.relatedTags = [];
  }
}

export class ImageSearchResult {
  artwork: Artwork;
  similarityScore: number;

  constructor(artwork: Artwork, similarityScore: number) {
    this.artwork = artwork;
    this.similarityScore = similarityScore;
  }
}
