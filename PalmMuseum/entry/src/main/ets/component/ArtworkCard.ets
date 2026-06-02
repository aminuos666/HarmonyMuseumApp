import { Artwork } from '../model/Artwork';

@Component
export struct ArtworkCard {
  @Prop artwork: Artwork;
  @State private isLoaded: boolean = true;
  @State private imageFailed: boolean = false;
  onTap?: () => void;

  build() {
    Column() {
      // 图片区域
      Stack() {
        // 占位图
        if (!this.isLoaded && !this.imageFailed) {
          Column() {
            LoadingView({ loadingText: '' })
          }
          .width('100%')
          .aspectRatio(0.75)
          .backgroundColor($r('app.color.shimmer_base'))
          .borderRadius(12)
        }

        // 图片
        Image(this.artwork.coverImage)
          .width('100%')
          .aspectRatio(0.75)
          .borderRadius({
            topLeft: 12,
            topRight: 12
          })
          .objectFit(ImageFit.Cover)
          .opacity(this.isLoaded ? 1.0 : 0.0)

        // 图片加载失败占位
        if (this.imageFailed) {
          Column() {
            Text('🖼️')
              .fontSize(48)
            Text('图片加载中')
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
              .margin({ top: 8 })
          }
          .width('100%')
          .aspectRatio(0.75)
          .backgroundColor($r('app.color.shimmer_base'))
          .borderRadius({
            topLeft: 12,
            topRight: 12
          })
          .justifyContent(FlexAlign.Center)
        }

        // 朝代标签
        Text(this.artwork.dynasty)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .position({ top: 10, left: 10 })
      }

      // 文字信息
      Column({ space: 4 }) {
        Text(this.artwork.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.artwork.description)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(17)
          .width('100%')

        // 统计信息
        Row({ space: 12 }) {
          Row({ space: 4 }) {
            Text('🔥')
              .fontSize(12)
            Text(`${this.artwork.likeCount + this.artwork.favoriteCount + this.artwork.commentCount}`)
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }

          Row({ space: 4 }) {
            Text('❤️')
              .fontSize(12)
            Text(`${this.artwork.likeCount}`)
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }

          Row({ space: 4 }) {
            Text(this.artwork.type)
              .fontSize(10)
              .fontColor($r('app.color.primary'))
              .backgroundColor($r('app.color.accent_light'))
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .padding({ left: 10, right: 10, top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: $r('app.color.shadow'),
      offsetX: 0,
      offsetY: 3
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }
}

@Component
export struct LoadingView {
  loadingText: string = '加载中...';

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(32)
        .height(32)
        .color($r('app.color.primary'))
      if (this.loadingText.length > 0) {
        Text(this.loadingText)
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct EmptyView {
  icon?: Resource;
  text: string = '暂无数据';

  build() {
    Column({ space: 12 }) {
      if (this.icon) {
        Image(this.icon)
          .width(64)
          .height(64)
          .objectFit(ImageFit.Contain)
          .opacity(0.4)
      }
      Text(this.text)
        .fontSize(15)
        .fontColor($r('app.color.text_hint'))
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
