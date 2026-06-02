import router from '@ohos.router';
import { UserService } from '../service/UserService';
import { PrivacyLevel } from '../model/User';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';

class PrivacyItem {
  label: string = '';
  value: PrivacyLevel = PrivacyLevel.PUBLIC;
  desc: string = '';
}

@Entry
@Component
struct SettingsPage {
  @State private nickname: string = '';
  @State private bio: string = '';
  @State private privacyLevel: PrivacyLevel = PrivacyLevel.PUBLIC;
  @State private notificationEnabled: boolean = true;
  @State private dailyRecommendEnabled: boolean = true;

  private userService = UserService.getInstance();

  aboutToAppear(): void {
    const user = this.userService.getCurrentUser();
    if (user) {
      this.nickname = user.nickname;
      this.bio = user.bio;
      this.privacyLevel = user.privacyLevel;
    }
  }

  build() {
    Column() {
      // 导航
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.search_bar_background'))
        .borderRadius(20)
        .onClick(() => { router.back(); })

        Blank()
        Text('设置')
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('保存')
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .onClick(async () => {
            await this.userService.updateProfile(this.nickname, this.bio);
            this.userService.updatePrivacy(this.privacyLevel);
            router.back();
          })
      }
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })

      Scroll() {
        Column({ space: 24 }) {
          // 头像设置
          Column({ space: 8 }) {
            this.buildSectionHeader('头像')
            Column({ space: 0 }) {
              Row() {
                Stack() {
                  Image(this.userService.getCurrentUser()?.avatar || '')
                    .width(72).height(72)
                    .objectFit(ImageFit.Cover).borderRadius(36)
                    .backgroundColor($r('app.color.shimmer_base'))
                    .border({ width: 2, color: $r('app.color.primary') })

                  Text('📷').fontSize(16).opacity(0.8)
                    .position({ bottom: 0, right: 0 })
                }

                Column({ space: 4 }) {
                  Text('点击更换头像')
                    .fontSize(14).fontColor($r('app.color.text_primary'))
                  Text('支持 JPG / PNG 格式')
                    .fontSize(11).fontColor($r('app.color.text_hint'))
                }
                .margin({ left: 16 })
                .alignItems(HorizontalAlign.Start)
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .width('100%')
              .onClick(async () => {
                try {
                  const options = new photoAccessHelper.PhotoSelectOptions();
                  options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
                  options.maxSelectNumber = 1;
                  const picker = new photoAccessHelper.PhotoViewPicker();
                  const result = await picker.select(options);
                  if (result?.photoUris?.[0]) {
                    const ctx = getContext(this) as common.UIAbilityContext;
                    const cachePath = `${ctx.cacheDir}/avatar_${Date.now()}.jpg`;
                    try {
                      const srcFile = fileIo.openSync(result.photoUris[0], fileIo.OpenMode.READ_ONLY);
                      fileIo.copyFileSync(srcFile.fd, cachePath);
                      fileIo.closeSync(srcFile);
                    } catch (_) {}
                    await this.userService.updateAvatar(cachePath);
                    promptAction.showToast({ message: '头像更新成功', duration: 1500 });
                  }
                } catch (e) {
                  promptAction.showToast({ message: '头像更新失败', duration: 1500 });
                }
              })
            }
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)
            .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
          }

          // 个人信息
          Column({ space: 8 }) {
            this.buildSectionHeader('个人信息')
            Column({ space: 0 }) {
              this.buildSettingInput('昵称', this.nickname, (v) => { this.nickname = v; })
              Divider().color($r('app.color.divider_light')).margin({ left: 16 })
              this.buildSettingTextArea('个人简介', this.bio, (v) => { this.bio = v; })
            }
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)
            .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
          }

          // 隐私设置
          Column({ space: 8 }) {
            this.buildSectionHeader('隐私设置')
            Column({ space: 0 }) {
              ForEach([
                { label: '公开', value: PrivacyLevel.PUBLIC, desc: '所有人可见' },
                { label: '仅关注者', value: PrivacyLevel.FOLLOWERS_ONLY, desc: '仅关注你的人可见' },
                { label: '私密', value: PrivacyLevel.PRIVATE, desc: '仅自己可见' }
              ] as PrivacyItem[], (item: PrivacyItem) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(item.label)
                      .fontSize(14)
                      .fontColor($r('app.color.text_primary'))
                    Text(item.desc)
                      .fontSize(11)
                      .fontColor($r('app.color.text_hint'))
                  }
                  Blank()
                  Radio({ value: item.value, group: 'privacy' })
                    .checked(this.privacyLevel === item.value)
                    .onChange(() => { this.privacyLevel = item.value; })
                }
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .width('100%')
                Divider().color($r('app.color.divider_light')).margin({ left: 16 })
              })
            }
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)
            .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
          }

          // 通知设置
          Column({ space: 8 }) {
            this.buildSectionHeader('通知设置')
            Column({ space: 0 }) {
              this.buildToggle('消息通知', this.notificationEnabled, (v) => {
                this.notificationEnabled = v;
              })
              Divider().color($r('app.color.divider_light')).margin({ left: 16 })
              this.buildToggle('每日文物推荐', this.dailyRecommendEnabled, (v) => {
                this.dailyRecommendEnabled = v;
              })
            }
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)
            .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
          }

          // 关于
          Column({ space: 8 }) {
            this.buildSectionHeader('关于')
            Column({ space: 0 }) {
              this.buildInfoRow('版本号', '1.0.0')
              Divider().color($r('app.color.divider_light')).margin({ left: 16 })
              this.buildInfoRow('用户协议', '')
              Divider().color($r('app.color.divider_light')).margin({ left: 16 })
              this.buildInfoRow('隐私政策', '')
            }
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)
            .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
          }

          // 退出登录
          Button() {
            Text('退出登录')
              .fontSize(16)
              .fontColor($r('app.color.error'))
          }
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(12)
          .onClick(() => {
            this.userService.logout();
            router.clear();
            router.clear();
            router.pushUrl({ url: 'pages/MainPage' });
          })
        }
        .padding({ left: 16, right: 16, bottom: 40 })
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildSectionHeader(title: string): void {
    Text(title)
      .fontSize(14)
      .fontColor($r('app.color.text_secondary'))
      .padding({ left: 4 })
  }

  @Builder
  buildSettingInput(label: string, value: string, onChange: (v: string) => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .width(80)
      TextInput({ text: value })
        .layoutWeight(1)
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .onChange((v) => { onChange(v); })
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .width('100%')
  }

  @Builder
  buildSettingTextArea(label: string, value: string, onChange: (v: string) => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .width(80)
      TextArea({ text: value })
        .layoutWeight(1)
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .height(60)
        .onChange((v) => { onChange(v); })
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .width('100%')
  }

  @Builder
  buildToggle(label: string, checked: boolean, onChange: (v: boolean) => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: checked })
        .onChange((v) => { onChange(v); })
    }
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .width('100%')
  }

  @Builder
  buildInfoRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
      Blank()
      if (value.length > 0) {
        Text(value)
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
      }
      Text('>')
        .fontSize(14)
        .fontColor($r('app.color.text_hint'))
        .opacity(0.3)
        .margin({ left: 4 })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .width('100%')
    .onClick(() => {})
  }
}
