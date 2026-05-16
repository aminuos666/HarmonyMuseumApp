import { User, PrivacyLevel, UserCollection, UserLike, BrowseHistory, UserUpload,
  UploadType, UserDynamic, UserFollow } from '../model/User';
import { ReviewStatus } from '../utils/Constants';

export class MockUsers {

  static getCurrentUser(): User {
    const user = new User();
    user.id = 'user_001';
    user.username = 'wenwu_aihao';
    user.nickname = '文物爱好者';
    user.avatar = 'https://example.com/avatar/user001.jpg';
    user.phone = '138****8888';
    user.email = 'wenwu@example.com';
    user.bio = '热爱中国传统文化，喜欢逛博物馆，记录每一件文物背后的故事。';
    user.followerCount = 128;
    user.followingCount = 56;
    user.isFollowing = false;
    user.privacyLevel = PrivacyLevel.PUBLIC;
    user.registerTime = Date.now() - 365 * 24 * 3600 * 1000;
    user.isVip = false;
    return user;
  }

  static getOtherUsers(): User[] {
    return [
      MockUsers.createUser('user_002', '古瓷鉴赏家', 'goci_001', 256, 89, true),
      MockUsers.createUser('user_003', '博物馆控', 'museum_fan', 1024, 203, false),
      MockUsers.createUser('user_004', '历史影像记录', 'history_lens', 512, 167, true),
      MockUsers.createUser('user_005', '考古爱好者', 'archaeo_fan', 64, 34, false),
      MockUsers.createUser('user_006', '文化传承者', 'culture_keep', 189, 72, true),
    ];
  }

  private static createUser(id: string, nickname: string, username: string,
    followers: number, following: number, isFollowing: boolean): User {
    const user = new User();
    user.id = id;
    user.username = username;
    user.nickname = nickname;
    user.avatar = `https://example.com/avatar/${id}.jpg`;
    user.bio = `大家好，我是一名${nickname}，喜欢分享文物知识。`;
    user.followerCount = followers;
    user.followingCount = following;
    user.isFollowing = isFollowing;
    user.privacyLevel = PrivacyLevel.PUBLIC;
    user.registerTime = Date.now() - Math.floor(Math.random() * 730) * 24 * 3600 * 1000;
    return user;
  }

  static getCollections(userId: string): UserCollection[] {
    const artworkIds = ['por_001', 'por_003', 'por_004', 'por_009', 'por_013', 'por_015', 'por_024'];
    const groups = ['默认分组', '最爱', '想去参观', '已参观'];
    return artworkIds.map((artworkId, index) => {
      const c = new UserCollection();
      c.id = `coll_${index}`;
      c.userId = userId;
      c.artworkId = artworkId;
      c.groupName = groups[index % groups.length];
      c.createTime = Date.now() - index * 7 * 24 * 3600 * 1000;
      return c;
    });
  }

  static getLikes(userId: string): UserLike[] {
    const artworkIds = ['por_001', 'por_002', 'por_004', 'por_009', 'por_020', 'por_024', 'por_025'];
    return artworkIds.map((artworkId, index) => {
      const l = new UserLike();
      l.id = `like_${index}`;
      l.userId = userId;
      l.artworkId = artworkId;
      l.createTime = Date.now() - index * 3 * 24 * 3600 * 1000;
      return l;
    });
  }

  static getBrowseHistory(userId: string): BrowseHistory[] {
    const artworkIds = ['por_001', 'por_003', 'por_004', 'por_009', 'por_010', 'por_015',
      'por_020', 'por_024', 'por_025'];
    return artworkIds.map((artworkId, index) => {
      const h = new BrowseHistory();
      h.id = `hist_${index}`;
      h.userId = userId;
      h.artworkId = artworkId;
      h.browseTime = Date.now() - index * 2 * 24 * 3600 * 1000;
      return h;
    });
  }

  static getUploads(userId: string): UserUpload[] {
    const uploads = [
      MockUsers.createUpload('up_001', userId, 'por_001', UploadType.PHOTO,
        '参观国家博物馆时拍摄的元青花梅瓶', ReviewStatus.APPROVED, '中国国家博物馆'),
      MockUsers.createUpload('up_002', userId, 'por_004', UploadType.PHOTO,
        '故宫陶瓷馆展出的鸡缸杯', ReviewStatus.APPROVED, '北京故宫博物院'),
      MockUsers.createUpload('up_003', userId, 'por_003', UploadType.PHOTO,
        '汝窑天青釉的温润质感', ReviewStatus.PENDING),
      MockUsers.createUpload('up_004', userId, 'por_010', UploadType.AUDIO,
        '我录制的汝窑三足奁讲解', ReviewStatus.APPROVED),
    ];
    return uploads;
  }

  private static createUpload(id: string, userId: string, artworkId: string,
    type: UploadType, caption: string, status: ReviewStatus, location?: string): UserUpload {
    const u = new UserUpload();
    u.id = id;
    u.userId = userId;
    u.artworkId = artworkId;
    u.uploadType = type;
    u.mediaUrl = `https://example.com/uploads/${id}.${type === UploadType.PHOTO ? 'jpg' : 'mp3'}`;
    u.thumbnailUrl = `https://example.com/uploads/${id}_thumb.jpg`;
    u.location = location || '';
    u.caption = caption;
    u.reviewStatus = status;
    u.uploadTime = Date.now() - Math.floor(Math.random() * 90) * 24 * 3600 * 1000;
    u.likeCount = Math.floor(Math.random() * 50);
    return u;
  }

  static getDynamics(userId: string): UserDynamic[] {
    return [
      MockUsers.createDynamic('dyn_001', userId, '今天去了国家博物馆，看到了心心念念的元青花梅瓶！实物比图片震撼太多了，釉色浓艳欲滴，纹饰繁复精美，不愧是元青花的巅峰之作。', ['https://example.com/dynamic/dyn_001_1.jpg', 'https://example.com/dynamic/dyn_001_2.jpg'], 'por_001', '元青花缠枝牡丹纹梅瓶'),
      MockUsers.createDynamic('dyn_002', userId, '终于见到了汝窑天青釉弦纹樽！\n\"雨过天青云破处，这般颜色作将来\"——古人的审美真的无可挑剔。\n那种温润如玉的质感，照片完全拍不出来。', [], 'por_003', '宋汝窑天青釉弦纹樽'),
      MockUsers.createDynamic('dyn_003', userId, '分享一组德化窑白釉观音像的细节照片。\n明代何朝宗大师的瓷塑技艺真的登峰造极，衣纹的飘逸感、面部的慈悲神态，在陶瓷材质上完美呈现，不愧是\"中国白\"！', ['https://example.com/dynamic/dyn_003_1.jpg'], 'por_016', '明德化窑白釉观音坐像'),
    ];
  }

  private static createDynamic(id: string, userId: string, content: string,
    images: string[], artworkId: string, artworkName: string): UserDynamic {
    const d = new UserDynamic();
    d.id = id;
    d.userId = userId;
    d.content = content;
    d.images = images;
    d.relatedArtworkId = artworkId;
    d.relatedArtworkName = artworkName;
    d.likeCount = Math.floor(Math.random() * 200) + 10;
    d.commentCount = Math.floor(Math.random() * 30);
    d.isLiked = Math.random() > 0.5;
    d.reviewStatus = ReviewStatus.APPROVED;
    d.createTime = Date.now() - Math.floor(Math.random() * 30) * 24 * 3600 * 1000;
    return d;
  }

  static getFollows(userId: string): UserFollow[] {
    return MockUsers.getOtherUsers().map((u, index) => {
      const f = new UserFollow();
      f.id = `follow_${index}`;
      f.followerId = userId;
      f.followingId = u.id;
      f.createTime = Date.now() - index * 10 * 24 * 3600 * 1000;
      return f;
    });
  }
}
