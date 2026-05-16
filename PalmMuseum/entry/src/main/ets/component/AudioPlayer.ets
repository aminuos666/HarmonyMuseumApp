import { AudioGuide } from '../model/Artwork';

@Component
export struct AudioPlayer {
  audioGuide: AudioGuide = new AudioGuide();
  @State private isPlaying: boolean = false;
  @State private currentTime: number = 0; // 秒
  @State private playbackSpeed: number = 1.0;
  private timerId?: number;

  aboutToDisappear(): void {
    this.stopTimer();
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        // 播放/暂停按钮
        Button() {
          Text(this.isPlaying ? '⏸️' : '▶️')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(24)
        .onClick(() => {
          this.togglePlayback();
        })

        Column({ space: 4 }) {
          // 进度条
          Slider({
            value: this.currentTime,
            min: 0,
            max: this.audioGuide.duration || 300,
            step: 1,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .blockColor($r('app.color.primary'))
            .trackColor($r('app.color.progress_track'))
            .selectedColor($r('app.color.primary'))
            .onChange((value: number) => {
              this.currentTime = value;
            })

          // 时间显示和倍速控制
          Row() {
            Text(this.formatTime(this.currentTime))
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))

            Blank()

            Text(`${this.audioGuide.narrator} · 讲解`)
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))

            Blank()

            // 倍速选择
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach([0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
                Text(`${speed}x`)
                  .fontSize(11)
                  .fontColor(this.playbackSpeed === speed ?
                    $r('app.color.primary') : $r('app.color.text_secondary'))
                  .fontWeight(this.playbackSpeed === speed ? FontWeight.Medium : FontWeight.Regular)
                  .backgroundColor(this.playbackSpeed === speed ?
                    $r('app.color.accent_light') : Color.Transparent)
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .onClick(() => {
                    this.playbackSpeed = speed;
                  })
              })
            }

            Text(this.formatTime(this.audioGuide.duration))
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
          }
          .width('100%')
        }
        .layoutWeight(1)
        .padding({ left: 4 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.background_card'))
      .borderRadius(12)
      .shadow({
        radius: 4,
        color: $r('app.color.shadow'),
        offsetY: 2
      })
    }
  }

  private togglePlayback(): void {
    this.isPlaying = !this.isPlaying;
    if (this.isPlaying) {
      this.startTimer();
    } else {
      this.stopTimer();
    }
  }

  private startTimer(): void {
    this.timerId = setInterval(() => {
      if (this.currentTime >= (this.audioGuide.duration || 300)) {
        this.isPlaying = false;
        this.currentTime = 0;
        this.stopTimer();
        return;
      }
      this.currentTime += 0.25;
    }, 250);
  }

  private stopTimer(): void {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = undefined;
    }
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}
