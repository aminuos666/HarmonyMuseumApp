import { ReviewStatus } from '../utils/Constants';

/**
 * 内容审核服务
 *
 * 在HarmonyOS应用中，内容审核可以通过以下方式实现：
 * 1. 使用华为云的内容审核API（文本审核、图片审核）
 * 2. 本地敏感词过滤（简单场景）
 * 3. 人工审核队列（社区驱动）
 *
 * 当前实现：自动通过审核并模拟延迟（简化版）
 * 完整实现应接入华为云Moderation服务：
 * - 文本审核：检测政治敏感、色情、暴力等内容
 * - 图片审核：检测违规图片内容
 * - 音频审核：检测音频中的违规内容
 */
export class ReviewService {
  private static instance: ReviewService;

  private sensitiveWords: string[] = [
    '违法', '违规', '敏感', '政治', '色情', '暴力',
  ];

  private constructor() {}

  static getInstance(): ReviewService {
    if (!ReviewService.instance) {
      ReviewService.instance = new ReviewService();
    }
    return ReviewService.instance;
  }

  /**
   * 审核文本内容
   *
   * @param text 待审核文本
   * @returns 审核结果
   */
  async reviewText(text: string): Promise<ReviewResult> {
    console.info(`ReviewService: Reviewing text (${text.length} chars)`);

    // 模拟审核处理延迟
    await this.simulateDelay(500);

    // 敏感词检查
    for (const word of this.sensitiveWords) {
      if (text.includes(word)) {
        const result = new ReviewResult();
        result.status = ReviewStatus.REJECTED;
        result.reason = '内容包含敏感词汇，请修改后重新提交';
        result.reviewedBy = 'AI自动审核';
        return result;
      }
    }

    // 长度检查
    if (text.length < 2) {
      const result = new ReviewResult();
      result.status = ReviewStatus.REJECTED;
      result.reason = '内容太短';
      result.reviewedBy = 'AI自动审核';
      return result;
    }

    // 模拟自动审核通过（80%概率自动通过，20%需要人工审核）
    if (Math.random() < 0.8) {
      const result = new ReviewResult();
      result.status = ReviewStatus.APPROVED;
      result.reason = 'AI审核通过';
      result.reviewedBy = 'AI自动审核';
      return result;
    } else {
      const result = new ReviewResult();
      result.status = ReviewStatus.PENDING;
      result.reason = '转人工审核';
      result.reviewedBy = 'AI自动审核';
      return result;
    }
  }

  /**
   * 审核图片内容
   */
  async reviewImage(imageUrl: string): Promise<ReviewResult> {
    console.info(`ReviewService: Reviewing image: ${imageUrl}`);
    await this.simulateDelay(1000);

    // 模拟图片审核（真实应用需调用视觉审核API）
    const result = new ReviewResult();
    result.status = ReviewStatus.APPROVED;
    result.reason = '图片内容合规';
    result.reviewedBy = 'AI自动审核';
    return result;
  }

  /**
   * 审核音频内容
   */
  async reviewAudio(audioUrl: string): Promise<ReviewResult> {
    console.info(`ReviewService: Reviewing audio: ${audioUrl}`);
    await this.simulateDelay(1200);

    const result = new ReviewResult();
    result.status = ReviewStatus.PENDING;
    result.reason = '音频内容需人工审核';
    result.reviewedBy = 'AI自动审核';
    return result;
  }

  /**
   * 审核视频内容
   */
  async reviewVideo(videoUrl: string): Promise<ReviewResult> {
    console.info(`ReviewService: Reviewing video: ${videoUrl}`);
    await this.simulateDelay(1500);

    const result = new ReviewResult();
    result.status = ReviewStatus.PENDING;
    result.reason = '视频内容需人工审核';
    result.reviewedBy = 'AI自动审核';
    return result;
  }

  private simulateDelay(ms: number): Promise<void> {
    return new Promise<void>(resolve => setTimeout(resolve, ms));
  }
}

export class ReviewResult {
  status: ReviewStatus = ReviewStatus.PENDING;
  reason: string = '';
  reviewedBy: string = '';
}
