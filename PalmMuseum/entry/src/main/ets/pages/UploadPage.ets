import router from '@ohos.router';
import { UploadType, UserUpload } from '../model/User';
import { UserService } from '../service/UserService';
import { ReviewService } from '../service/ReviewService';
import { NotificationService } from '../service/NotificationService';
import { ReviewStatus, NotificationType } from '../utils/Constants';

class UploadTypeItem {
  label: string = '';
  value: UploadType = UploadType.PHOTO;
}

@Entry
@Component
struct UploadPage {
  @State private uploadType: UploadType = UploadType.PHOTO;
  @State private caption: string = '';
  @State private location: string = '';
  @State private selectedArtworkId: string = '';
  @State private isUploading: boolean = false;
  @State private uploadComplete: boolean = false;

  private userService = UserService.getInstance();
  private reviewService = ReviewService.getInstance();
  private notificationService = NotificationService.getInstance();

  build() {
    Column() {
      // 导航
      Row() {
        Button() {
          Text('◀')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { router.back(); })

        Blank()
        Text('上传内容')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()

        if (!this.uploadComplete) {
          Button() {
            Text('📤 提交')
              .fontSize(15)
              .fontColor(Color.White)
          }
          .height(36)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(18)
          .onClick(() => { this.handleUpload(); })
        }
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      if (this.uploadComplete) {
        // 上传成功
        Column({ space: 16 }) {
          Blank()
          Text('✅')
            .fontSize(80)
          Text('上传成功')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
          Text('内容已提交审核，审核通过后将公开展示')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text('查看我的上传')
            .fontSize(15)
            .fontColor($r('app.color.primary'))
            .margin({ top: 16 })
          Blank()
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 20 }) {
            // 上传类型选择
            Column({ space: 8 }) {
              Text('上传类型')
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Medium)

              Row({ space: 12 }) {
                ForEach([
                  { label: '照片', value: UploadType.PHOTO },
                  { label: '语音讲解', value: UploadType.AUDIO },
                  { label: '视频', value: UploadType.VIDEO }
                ] as UploadTypeItem[], (item: UploadTypeItem) => {
                  Text(item.label)
                    .fontSize(14)
                    .fontColor(this.uploadType === item.value ?
                      $r('app.color.text_on_primary') : $r('app.color.text_secondary'))
                    .backgroundColor(this.uploadType === item.value ?
                      $r('app.color.primary') : $r('app.color.background_card'))
                    .borderRadius(8)
                    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                    .onClick(() => { this.uploadType = item.value; })
                })
              }
            }

            // 选择文件
            Column({ space: 8 }) {
              Text('选择文件')
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Medium)

              Column() {
                Text('📁')
                  .fontSize(48)
                  .opacity(0.4)
                Text('点击选择文件')
                  .fontSize(14)
                  .fontColor($r('app.color.text_hint'))
                  .margin({ top: 8 })
                Text(`支持${this.uploadType === UploadType.PHOTO ? 'JPG/PNG格式图片' :
                  this.uploadType === UploadType.AUDIO ? 'MP3/ACC格式音频' : 'MP4格式视频'}`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_hint'))
              }
              .width('100%')
              .height(160)
              .backgroundColor($r('app.color.background_card'))
              .borderRadius(12)
              .borderWidth(2)
              .borderColor($r('app.color.divider'))
              .borderStyle(BorderStyle.Dashed)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                // 真实应用：调用文件选择器
                // let photoPicker = new photoAccessHelper.PhotoPicker();
              })
            }

            // 关联文物
            Column({ space: 8 }) {
              Text('关联文物（选填）')
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Medium)

              TextInput({ placeholder: '搜索并选择关联的文物...', text: this.selectedArtworkId })
                .height(44)
                .fontSize(14)
                .placeholderColor($r('app.color.text_hint'))
                .backgroundColor($r('app.color.background_card'))
                .borderRadius(8)
                .padding({ left: 12 })
            }

            // 说明
            Column({ space: 8 }) {
              Text('说明文字')
                .fontSize(15)
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Medium)

              TextArea({ placeholder: '添加说明文字...', text: this.caption })
                .height(100)
                .fontSize(14)
                .placeholderColor($r('app.color.text_hint'))
                .backgroundColor($r('app.color.background_card'))
                .borderRadius(8)
                .padding(12)
                .onChange((v) => { this.caption = v; })
            }

            // 拍摄地点
            if (this.uploadType === UploadType.PHOTO) {
              Column({ space: 8 }) {
                Text('拍摄地点（选填）')
                  .fontSize(15)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Medium)

                Row() {
                  Text('📍')
                    .fontSize(18)
                    .opacity(0.5)
                  TextInput({
                    placeholder: '例如：北京故宫博物院陶瓷馆',
                    text: this.location
                  })
                    .layoutWeight(1)
                    .fontSize(14)
                    .placeholderColor($r('app.color.text_hint'))
                    .backgroundColor(Color.Transparent)
                    .onChange((v) => { this.location = v; })
                }
                .padding(12)
                .backgroundColor($r('app.color.background_card'))
                .borderRadius(8)
              }
            }
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private async handleUpload(): Promise<void> {
    this.isUploading = true;

    // 模拟上传
    await new Promise<void>(resolve => setTimeout(resolve, 1000));
    const upload = this.userService.addUpload(
      this.selectedArtworkId, this.uploadType, this.caption, this.location
    );

    this.notificationService.sendNotification(
      NotificationType.SYSTEM,
      '上传成功',
      '您的内容已提交，审核通过后将通知您。'
    );

    this.isUploading = false;
    this.uploadComplete = true;
  }
}
