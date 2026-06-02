/**
 * 语音导览播放器
 *
 * 底层：Core Speech Kit textToSpeech（纯本地，不经过后端）
 * 逻辑：仅播放/停止两种状态
 *   - ▶️ 播放 → 从头播报一遍
 *   - ⏹️ 停止 → 中止播报
 *   - 点击倍速 → 立即以该倍速开始播放，左侧按钮变为停止
 */
import { AudioGuide } from '../model/Artwork';
import { SpeechService } from '../service/SpeechService';

@Component
export struct AudioPlayer {
  audioGuide: AudioGuide = new AudioGuide();
  @State private isPlaying: boolean = false;
  @State private playbackSpeed: number = 1.0;

  private speechService = SpeechService.getInstance();

  aboutToDisappear(): void {
    this.stop();
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        // 播放/停止按钮（无背景，仅三角/双竖线图标）
        Button() {
          if (this.isPlaying) {
            Text('⏹️')
              .fontSize(26)
              .fontColor($r('app.color.primary'))
          } else {
            Text('▶')
              .fontSize(26)
              .fontColor($r('app.color.primary'))
              .offset({ x: 2 })
          }
        }
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.togglePlay(); })

        // 倍速选择
        Row() {
          Blank()
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach([0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
              Text(`${speed}x`)
                .fontSize(12)
                .fontColor(this.playbackSpeed === speed ?
                  $r('app.color.primary') : $r('app.color.text_secondary'))
                .fontWeight(this.playbackSpeed === speed ? FontWeight.Medium : FontWeight.Regular)
                .backgroundColor(this.playbackSpeed === speed ?
                  $r('app.color.accent_light') : Color.Transparent)
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .onClick(() => { this.selectSpeed(speed); })
            })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      // 状态提示
      Row({ space: 6 }) {
        Text('🎙️').fontSize(12)
        Text(this.isPlaying ? '播放中 · Core Speech Kit TTS' : '点击 ▶️ 开始语音导览')
          .fontSize(11)
          .fontColor($r('app.color.text_hint'))
      }
      .width('100%')
      .padding({ left: 16, bottom: 8 })
      .justifyContent(FlexAlign.Start)
    }
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
    .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 2 })
  }

  // ── 播放/停止切换 ──

  private togglePlay(): void {
    if (this.isPlaying) {
      this.stop();
    } else {
      this.play();
    }
  }

  private play(): void {
    const text = this.audioGuide?.textScript || '';
    if (!text.trim()) {
      return;
    }
    this.speechService.stopSpeaking();
    this.isPlaying = true;
    this.speechService.speak(text, this.playbackSpeed);
  }

  private stop(): void {
    this.speechService.stopSpeaking();
    this.isPlaying = false;
  }

  // ── 倍速：立即以该倍速开始播放 ──

  private selectSpeed(speed: number): void {
    this.playbackSpeed = speed;
    this.speechService.setSpeed(speed);

    const text = this.audioGuide?.textScript || '';
    if (!text.trim()) {
      return;
    }

    this.speechService.stopSpeaking();
    this.isPlaying = true;
    this.speechService.speak(text, speed);
  }
}
