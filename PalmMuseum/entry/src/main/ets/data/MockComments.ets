import { Comment, ReplyComment } from '../model/Comment';
import { ReviewStatus } from '../utils/Constants';

export class MockComments {

  static getComments(artworkId: string): Comment[] {
    return [
      MockComments.createComment('cmt_001', artworkId, 'user_002', '古瓷鉴赏家',
        '这件器物的釉色非常纯正，是典型的浙料发色，值得细细品味。', 25, 3,
        'cmt_001_r1', 'user_003', '博物馆控', '确实，这个时期的发色特征很明显。'),
      MockComments.createComment('cmt_002', artworkId, 'user_003', '博物馆控',
        '之前在故宫看过实物，细节比照片还要精美。推荐大家去看原件！', 18, 1,
        'cmt_002_r1', 'user_001', '文物爱好者', '同意！我上次去故宫也看到了，实物质感无与伦比。'),
      MockComments.createComment('cmt_003', artworkId, 'user_004', '历史影像记录',
        '请问这件文物现在的具体展陈位置在哪里？想去参观。', 5, 0),
      MockComments.createComment('cmt_004', artworkId, 'user_005', '考古爱好者',
        '文物的保存状态非常好，经历了数百年还能如此完整，实属罕见。', 12, 0),
      MockComments.createComment('cmt_005', artworkId, 'user_006', '文化传承者',
        '每次看到这些古代艺术品，都能感受到中华文明的博大精深。', 20, 2,
        'cmt_005_r1', 'user_002', '古瓷鉴赏家', '说得太好了，文化自信正来源于此。'),
    ].filter(() => Math.random() > 0.3); // 随机过滤一部分保持多样性
  }

  private static createComment(id: string, artworkId: string, userId: string,
    username: string, content: string, likes: number, replyCount: number,
    replyId?: string, replyUserId?: string, replyUsername?: string,
    replyContent?: string): Comment {
    const c = new Comment();
    c.id = id;
    c.artworkId = artworkId;
    c.userId = userId;
    c.username = username;
    c.userAvatar = `https://example.com/avatar/${userId}.jpg`;
    c.content = content;
    c.likeCount = likes;
    c.replyCount = replyCount;
    c.isLiked = false;
    c.reviewStatus = ReviewStatus.APPROVED;
    c.createTime = Date.now() - Math.floor(Math.random() * 30) * 24 * 3600 * 1000;

    // 添加回复
    if (replyId && replyContent && replyCount > 0) {
      for (let i = 0; i < replyCount; i++) {
        const reply = new ReplyComment();
        reply.id = `${id}_reply_${i}`;
        reply.commentId = id;
        reply.userId = replyUserId || 'user_002';
        reply.username = replyUsername || '古瓷鉴赏家';
        reply.userAvatar = `https://example.com/avatar/${replyUserId || 'user_002'}.jpg`;
        reply.content = i === 0 ? replyContent : `回复${i + 1}: 同意楼上观点，这件文物确实非常珍贵。`;
        reply.replyToUserId = userId;
        reply.replyToUsername = username;
        reply.likeCount = Math.floor(Math.random() * 15);
        reply.isLiked = false;
        reply.reviewStatus = ReviewStatus.APPROVED;
        reply.createTime = c.createTime + i * 3600000;
        c.replies.push(reply);
      }
    }
    return c;
  }
}
