import { ReviewStatus } from '../utils/Constants';

export class User {
  id: string;
  username: string;
  nickname: string;
  avatar: string;
  phone: string;
  email: string;
  password: string;
  bio: string;
  followerCount: number;
  followingCount: number;
  isFollowing: boolean;
  privacyLevel: PrivacyLevel;
  registerTime: number;
  isVip: boolean;

  constructor() {
    this.id = '';
    this.username = '';
    this.nickname = '';
    this.avatar = '';
    this.phone = '';
    this.email = '';
    this.password = '';
    this.bio = '';
    this.followerCount = 0;
    this.followingCount = 0;
    this.isFollowing = false;
    this.privacyLevel = PrivacyLevel.PUBLIC;
    this.registerTime = Date.now();
    this.isVip = false;
  }
}

export enum PrivacyLevel {
  PUBLIC = 'public',
  FOLLOWERS_ONLY = 'followers_only',
  PRIVATE = 'private'
}

export class UserCollection {
  id: string;
  userId: string;
  artworkId: string;
  groupName: string;
  createTime: number;

  constructor() {
    this.id = '';
    this.userId = '';
    this.artworkId = '';
    this.groupName = '默认分组';
    this.createTime = Date.now();
  }
}

export class UserLike {
  id: string;
  userId: string;
  artworkId: string;
  createTime: number;

  constructor() {
    this.id = '';
    this.userId = '';
    this.artworkId = '';
    this.createTime = Date.now();
  }
}

export class BrowseHistory {
  id: string;
  userId: string;
  artworkId: string;
  browseTime: number;

  constructor() {
    this.id = '';
    this.userId = '';
    this.artworkId = '';
    this.browseTime = Date.now();
  }
}

export class UserUpload {
  id: string;
  userId: string;
  artworkId: string;
  uploadType: UploadType;
  mediaUrl: string;
  thumbnailUrl: string;
  location?: string;
  caption: string;
  reviewStatus: ReviewStatus;
  reviewComment: string;
  uploadTime: number;
  likeCount: number;

  constructor() {
    this.id = '';
    this.userId = '';
    this.artworkId = '';
    this.uploadType = UploadType.PHOTO;
    this.mediaUrl = '';
    this.thumbnailUrl = '';
    this.caption = '';
    this.reviewStatus = ReviewStatus.PENDING;
    this.reviewComment = '';
    this.uploadTime = Date.now();
    this.likeCount = 0;
  }
}

export enum UploadType {
  PHOTO = 'photo',
  AUDIO = 'audio',
  VIDEO = 'video'
}

export class UserDynamic {
  id: string;
  userId: string;
  content: string;
  images: string[];
  relatedArtworkId?: string;
  relatedArtworkName?: string;
  likeCount: number;
  commentCount: number;
  isLiked: boolean;
  reviewStatus: ReviewStatus;
  createTime: number;

  constructor() {
    this.id = '';
    this.userId = '';
    this.content = '';
    this.images = [];
    this.likeCount = 0;
    this.commentCount = 0;
    this.isLiked = false;
    this.reviewStatus = ReviewStatus.PENDING;
    this.createTime = Date.now();
  }
}

export class UserFollow {
  id: string;
  followerId: string;
  followingId: string;
  createTime: number;

  constructor() {
    this.id = '';
    this.followerId = '';
    this.followingId = '';
    this.createTime = Date.now();
  }
}
