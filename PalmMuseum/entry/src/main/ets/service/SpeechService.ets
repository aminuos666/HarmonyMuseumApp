/**
 * 语音服务 - 基于 HarmonyOS Core Speech Kit
 *
 * TTS：@kit.CoreSpeechKit textToSpeech
 * ASR：@kit.CoreSpeechKit speechRecognizer
 */
import { textToSpeech } from '@kit.CoreSpeechKit';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class SpeechService {
  private static instance: SpeechService;
  private ttsEngine?: textToSpeech.TextToSpeechEngine;
  private asrEngine?: speechRecognizer.SpeechRecognitionEngine;
  private isSpeaking: boolean = false;
  private playbackSpeed: number = 1.0;
  private engineReady: boolean = false;
  private speakResolve?: () => void;

  // ASR 状态
  private isListening: boolean = false;
  private asrSessionId: string = '';
  private asrRecognizedText: string = '';
  private asrResolve?: (text: string) => void;
  private asrReject?: (err: Error) => void;
  private asrTimeoutId?: number;

  private constructor() {}

  static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  // =====================================================
  //  TTS：文本转语音
  // =====================================================

  private async ensureTtsEngine(): Promise<textToSpeech.TextToSpeechEngine> {
    if (this.ttsEngine && this.engineReady) {
      return this.ttsEngine;
    }
    const initParams: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: { "style": 'interaction-broadcast', "locate": 'CN', "name": 'PalmMuseum' } as Record<string, Object>
    };
    return new Promise((resolve, reject) => {
      textToSpeech.createEngine(initParams, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
        if (err) {
          reject(new Error(err.message || String(err)));
          return;
        }
        this.ttsEngine = engine;
        this.engineReady = true;
        engine.setListener({
          onStart: (_id: string) => {},
          onComplete: (_id: string) => {
            this.isSpeaking = false;
            if (this.speakResolve) { this.speakResolve(); this.speakResolve = undefined; }
          },
          onStop: (_id: string) => {
            this.isSpeaking = false;
            if (this.speakResolve) { this.speakResolve(); this.speakResolve = undefined; }
          },
          onError: (_id: string, _code: number, _msg: string) => {
            this.isSpeaking = false;
            if (this.speakResolve) { this.speakResolve(); this.speakResolve = undefined; }
          },
        } as textToSpeech.SpeakListener);
        resolve(engine);
      });
    });
  }

  /**
   * 播放文本语音
   */
  async speak(text: string, speed: number = 1.0): Promise<void> {
    if (this.isSpeaking) {
      await this.stopSpeaking();
    }
    if (!text || text.trim().length === 0) {
      return;
    }
    this.isSpeaking = true;
    this.playbackSpeed = speed;

    const engine = await this.ensureTtsEngine();
    const extraParam: Record<string, Object> = {
      "speed": speed, "volume": 2, "pitch": 1, "languageContext": 'zh-CN', "audioType": "pcm"
    };
    const speakParams: textToSpeech.SpeakParams = {
      requestId: `tts_${Date.now()}`,
      extraParams: extraParam
    };
    engine.speak(text, speakParams);

    return new Promise<void>((resolve) => {
      this.speakResolve = resolve;
    });
  }

  /**
   * 停止播放
   */
  async stopSpeaking(): Promise<void> {
    if (this.isSpeaking && this.ttsEngine) {
      this.ttsEngine.stop();
    }
    this.isSpeaking = false;
    this.speakResolve = undefined;
  }

  get isCurrentlySpeaking(): boolean {
    return this.isSpeaking;
  }

  setSpeed(speed: number): void {
    this.playbackSpeed = Math.max(0.5, Math.min(2.0, speed));
  }

  get currentSpeed(): number {
    return this.playbackSpeed;
  }

  // =====================================================
  //  ASR：语音识别
  //  - 第一次点击 🎤：开始识别
  //  - 第二次点击（🔴）：结束识别，返回已收集的文字
  // =====================================================

  private async ensureAsrEngine(): Promise<speechRecognizer.SpeechRecognitionEngine> {
    if (this.asrEngine) {
      return this.asrEngine;
    }
    const initParams: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: 1,
      extraParams: { "locate": "CN", "recognizerMode": "short" } as Record<string, Object>
    };
    return new Promise((resolve, reject) => {
      speechRecognizer.createEngine(initParams, (err: BusinessError, engine: speechRecognizer.SpeechRecognitionEngine) => {
        if (err) {
          reject(new Error(err.message || String(err)));
          return;
        }
        this.asrEngine = engine;
        engine.setListener({
          onStart: (_sid: string, _msg: string) => {},
          onEvent: (_sid: string, _code: number, _msg: string) => {},
          onResult: (_sid: string, result: speechRecognizer.SpeechRecognitionResult) => {
            if (result.result) {
              this.asrRecognizedText = result.result;
            }
          },
          onComplete: (_sid: string, _msg: string) => {
            this.finishListening();
          },
          onError: (_sid: string, _code: number, _msg: string) => {
            this.finishListening();
          },
        } as speechRecognizer.RecognitionListener);
        resolve(engine);
      });
    });
  }

  /**
   * 开始语音识别，返回 Promise
   * 结果在 onComplete 或用户手动结束时 resolve
   */
  async startListening(): Promise<string> {
    if (this.isListening) {
      throw new Error('Already listening');
    }
    this.isListening = true;
    this.asrRecognizedText = '';

    try {
      const engine = await this.ensureAsrEngine();
      this.asrSessionId = `asr_${Date.now()}`;
      engine.startListening({
        sessionId: this.asrSessionId,
        audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 }
      } as speechRecognizer.StartParams);

      return new Promise<string>((resolve, reject) => {
        this.asrResolve = resolve;
        this.asrReject = reject;
        // 15 秒超时自动结束
        this.asrTimeoutId = setTimeout(() => {
          this.cancelListening();
        }, 15000);
      });
    } catch (err) {
      this.isListening = false;
      throw new Error(String(err));
    }
  }

  /**
   * 手动结束识别（第二次点击）
   * 调用引擎 finish → 触发 onComplete → resolve 已收集的文字
   */
  cancelListening(): void {
    if (this.asrTimeoutId) {
      clearTimeout(this.asrTimeoutId);
      this.asrTimeoutId = undefined;
    }
    if (this.asrEngine && this.asrSessionId) {
      try {
        this.asrEngine.finish(this.asrSessionId);
      } catch (_) {
        this.finishListening();
      }
    } else {
      this.finishListening();
    }
  }

  private finishListening(): void {
    if (this.asrTimeoutId) {
      clearTimeout(this.asrTimeoutId);
      this.asrTimeoutId = undefined;
    }
    this.isListening = false;
    this.asrSessionId = '';
    if (this.asrResolve) {
      this.asrResolve(this.asrRecognizedText);
      this.asrResolve = undefined;
    }
    this.asrReject = undefined;
  }

  get isCurrentlyListening(): boolean {
    return this.isListening;
  }

  // =====================================================
  //  语音问答
  // =====================================================

  async askQuestion(question: string): Promise<string> {
    const answers: Record<string, string> = {
      '什么年代': '这件文物的年代在文物详情页中有详细记载。',
      '哪里出土': '这件文物的出土地点信息在详情页的基本信息栏目中。',
      '价值': '文物不仅具有经济价值，更重要的是其历史文化价值和艺术价值。',
      '工艺': '这件文物采用了传统工艺制作。',
      '收藏': '这件文物目前收藏于博物馆中，欢迎前往参观。',
      '青花': '青花瓷是中国陶瓷的代表品种，使用钴料在釉下绘制纹饰。',
      '汝窑': '汝窑为宋代五大名窑之首，以天青釉色闻名于世。',
      '唐三彩': '唐三彩是唐代低温铅釉陶器，以黄绿白三色为主。',
    };
    let answer = '感谢您的提问。建议浏览文物详情页面获取更详细的介绍。';
    for (const key of Object.keys(answers)) {
      if (question.includes(key)) { answer = answers[key]; break; }
    }
    return answer;
  }

  // =====================================================
  //  资源管理
  // =====================================================

  shutdown(): void {
    this.cancelListening();
    if (this.isSpeaking && this.ttsEngine) {
      this.ttsEngine.stop();
    }
    if (this.ttsEngine) {
      this.ttsEngine.shutdown();
      this.ttsEngine = undefined;
      this.engineReady = false;
    }
    this.asrEngine = undefined;
    this.isSpeaking = false;
    this.isListening = false;
  }
}
