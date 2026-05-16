/**
 * 语音服务 - 负责语音合成（TTS）和语音识别（ASR）
 *
 * HarmonyOS 语音能力使用：
 * - @ohos.multimedia.voice: 语音识别服务
 * - @ohos.multimedia.tts: 文本转语音服务
 * - 也可使用系统提供的语音播报API
 *
 * 当前实现为模拟服务，在实际部署时需要：
 * 1. 配置HarmonyOS语音服务权限
 * 2. 初始化语音引擎
 * 3. 实现语音识别回调处理
 */
export class SpeechService {
  private static instance: SpeechService;
  private isSpeaking: boolean = false;
  private isListening: boolean = false;
  private playbackSpeed: number = 1.0;

  private constructor() {}

  static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  /**
   * 播放文物语音讲解
   *
   * @param text 讲解文本
   * @param speed 播放速度（0.5~2.0）
   */
  async playGuide(text: string, speed: number = 1.0): Promise<void> {
    if (this.isSpeaking) {
      await this.stopSpeaking();
    }

    this.isSpeaking = true;
    this.playbackSpeed = speed;

    console.info(`SpeechService: Playing guide (speed: ${speed}x)`);
    console.info(`Guide text length: ${text.length} characters`);

    // 真实实现：
    // const tts = await import('@ohos.multimedia.tts');
    // const ttsClient = tts.createTtsClient();
    // ttsClient.speak(text, { speed: speed, pitch: 1.0, volume: 1.0 });

    // 模拟播放过程
    const playDuration = Math.min(30000, text.length * 50 / speed);
    await this.simulatePlayback(playDuration);

    this.isSpeaking = false;
    console.info('SpeechService: Guide playback completed');
  }

  /**
   * 停止播放
   */
  async stopSpeaking(): Promise<void> {
    if (this.isSpeaking) {
      console.info('SpeechService: Stopping playback');
      this.isSpeaking = false;
    }
  }

  /**
   * 开始语音识别（语音搜索）
   *
   * @returns 识别后的文本
   */
  async startListening(): Promise<string> {
    if (this.isListening) {
      throw new Error('Already listening');
    }

    this.isListening = true;
    console.info('SpeechService: Started listening');

    // 真实实现：
    // const voice = await import('@ohos.multimedia.voice');
    // const voiceRecognizer = voice.createVoiceRecognizer();
    // return await voiceRecognizer.startListening();

    // 模拟语音识别过程
    await this.simulatePlayback(3000);
    this.isListening = false;

    // 模拟识别结果（随机选择一个文物名称）
    const mockResults = [
      '元青花缠枝牡丹纹梅瓶',
      '宋代汝窑瓷器',
      '唐三彩',
      '青花瓷',
      '粉彩百鹿图',
      '乾隆时期的瓷器',
      '景德镇瓷器'
    ];
    const result = mockResults[Math.floor(Math.random() * mockResults.length)];
    console.info(`SpeechService: Recognized: "${result}"`);
    return result;
  }

  /**
   * 停止语音识别
   */
  stopListening(): void {
    if (this.isListening) {
      console.info('SpeechService: Stopped listening');
      this.isListening = false;
    }
  }

  /**
   * 语音问答 - 用户提问后返回语音答案
   *
   * @param question 用户语音识别后的问題文本
   * @returns 答案语音文本
   */
  async askQuestion(question: string): Promise<string> {
    console.info(`SpeechService: Question: "${question}"`);

    // 模拟问答处理
    await this.simulatePlayback(1500);

    // 基于关键词的简单问答
    const answers: Record<string, string> = {
      '什么年代': '这件文物的年代在文物详情页中有详细记载，您可以查看相关信息。',
      '哪里出土': '这件文物的出土地点信息在详情页的"基本信息"栏目中。',
      '价值': '文物的价值不仅体现在经济价值上，更重要的是其历史文化价值和艺术价值。',
      '工艺': '这件文物采用了传统工艺制作，具体工艺特点可查看详情页的"工艺技法"部分。',
      '收藏': '这件文物目前收藏于博物馆中，欢迎您前往参观。',
      '青花': '青花瓷是中国陶瓷的代表品种，使用钴料在釉下绘制纹饰，经高温烧制而成。',
      '汝窑': '汝窑为宋代五大名窑之首，以天青釉色闻名于世，传世品极为稀少。',
      '唐三彩': '唐三彩是唐代低温铅釉陶器，以黄、绿、白三色为主，是盛唐气象的生动体现。',
    };

    let answer = '感谢您的提问。这件文物蕴含丰富的历史文化信息，建议您浏览文物详情页面获取更详细的介绍。';
    const answerKeys = Object.keys(answers);
    for (let i = 0; i < answerKeys.length; i++) {
      const key = answerKeys[i];
      if (question.includes(key)) {
        answer = answers[key];
        break;
      }
    }

    console.info(`SpeechService: Answer: "${answer}"`);
    return answer;
  }

  get isCurrentlySpeaking(): boolean {
    return this.isSpeaking;
  }

  get isCurrentlyListening(): boolean {
    return this.isListening;
  }

  setSpeed(speed: number): void {
    this.playbackSpeed = Math.max(0.5, Math.min(2.0, speed));
  }

  get currentSpeed(): number {
    return this.playbackSpeed;
  }

  /**
   * 模拟播放延迟
   */
  private simulatePlayback(ms: number): Promise<void> {
    return new Promise<void>(resolve => {
      const interval = 100;
      const checkId = setInterval(() => {
        if (!this.isSpeaking && ms > 1000) {
          clearInterval(checkId);
          resolve();
          return;
        }
      }, interval);

      setTimeout(() => {
        clearInterval(checkId);
        resolve();
      }, ms);
    });
  }
}
