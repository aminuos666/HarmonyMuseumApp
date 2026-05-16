import { ArtworkImage } from '../model/Artwork';

@Component
export struct ImageViewer {
  private images: ArtworkImage[] = [];
  @State private currentIndex: number = 0;
  @State private zoomScale: number = 1.0;
  @State private isFullScreen: boolean = false;
  private onClose?: () => void;

  build() {
    Column() {
      if (this.isFullScreen) {
        // 全屏查看模式
        Stack() {
          // 图片
          Image(this.images[this.currentIndex]?.url || '')
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .gesture(
              GestureGroup(GestureMode.Parallel,
                // 双击缩放
                TapGesture({ count: 2 })
                  .onAction(() => {
                    this.zoomScale = this.zoomScale > 1 ? 1 : 2.5;
                  }),
                // 捏合缩放
                PinchGesture()
                  .onActionStart(() => {
                    this.zoomScale = 1.0;
                  })
                  .onActionUpdate((event: PinchGestureEvent) => {
                    this.zoomScale = event.scale;
                    if (this.zoomScale < 0.5) this.zoomScale = 0.5;
                    if (this.zoomScale > 5) this.zoomScale = 5;
                  }),
                // 滑动切换
                SwipeGesture()
                  .onAction((event: SwipeGestureEvent) => {
                    if (event.angle > -45 && event.angle < 45) {
                      // 左滑
                      if (this.currentIndex < this.images.length - 1) {
                        this.currentIndex++;
                      }
                    } else if (event.angle > 135 || event.angle < -135) {
                      // 右滑
                      if (this.currentIndex > 0) {
                        this.currentIndex--;
                      }
                    }
                  })
              )
            )
            .scale({ x: this.zoomScale, y: this.zoomScale })

          // 顶部工具栏
          Row() {
            // 关闭按钮
            Button() {
              Text('✕')
                .fontSize(20)
                .fontColor($r('app.color.text_primary'))
            }
            .width(40)
            .height(40)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .onClick(() => {
              if (this.onClose) {
                this.onClose();
              }
            })

            Blank()

            // 图片计数器
            Text(`${this.currentIndex + 1} / ${this.images.length}`)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.overlay'))
              .borderRadius(12)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 40 })
          .position({ top: 0 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
      } else {
        // 缩略图模式
        Column({ space: 8 }) {
          // 主图
          Image(this.images[this.currentIndex]?.url || '')
            .width('100%')
            .height(320)
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
            .backgroundColor($r('app.color.shimmer_base'))
            .gesture(
              TapGesture({ count: 1 })
                .onAction(() => {
                  this.isFullScreen = true;
                })
            )

          // 缩略图导航
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.images, (image: ArtworkImage, index: number) => {
                Stack() {
                  Image(image.thumbnailUrl || image.url)
                    .width(60)
                    .height(60)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(6)
                    .onClick(() => {
                      this.currentIndex = index;
                    })
                    .borderWidth(this.currentIndex === index ? 2 : 0)
                    .borderColor(this.currentIndex === index ? $r('app.color.primary') : Color.Transparent)
                    .borderRadius(6)
                }
              }, (image: ArtworkImage) => image.id)
            }
            .padding({ left: 4, right: 4 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .height(72)

          // 图片标题
          Text(this.images[this.currentIndex]?.title || '')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
      }
    }
  }
}
