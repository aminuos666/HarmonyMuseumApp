import { ReviewStatus } from '../utils/Constants';

export class Comment {
  id: string;
  artworkId: string;
  userId: string;
  username: string;
  userAvatar: string;
  content: string;
  likeCount: number;
  replyCount: number;
  isLiked: boolean;
  parentId: string;
  reviewStatus: ReviewStatus;
  createTime: number;
  replies: ReplyComment[];

  constructor() {
    this.id = '';
    this.artworkId = '';
    this.userId = '';
    this.username = '';
    this.userAvatar = '';
    this.content = '';
    this.likeCount = 0;
    this.replyCount = 0;
    this.isLiked = false;
    this.parentId = '';
    this.reviewStatus = ReviewStatus.PENDING;
    this.createTime = Date.now();
    this.replies = [];
  }
}

export class ReplyComment {
  id: string;
  commentId: string;
  userId: string;
  username: string;
  userAvatar: string;
  content: string;
  replyToUserId: string;
  replyToUsername: string;
  likeCount: number;
  isLiked: boolean;
  reviewStatus: ReviewStatus;
  createTime: number;

  constructor() {
    this.id = '';
    this.commentId = '';
    this.userId = '';
    this.username = '';
    this.userAvatar = '';
    this.content = '';
    this.replyToUserId = '';
    this.replyToUsername = '';
    this.likeCount = 0;
    this.isLiked = false;
    this.reviewStatus = ReviewStatus.PENDING;
    this.createTime = Date.now();
  }
}
