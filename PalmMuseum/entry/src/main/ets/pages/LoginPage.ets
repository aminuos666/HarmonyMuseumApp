import router from '@ohos.router';
import { UserService } from '../service/UserService';

class LoginModeItem {
  label: string = '';
  value: LoginMode = LoginMode.PHONE;
}

@Entry
@Component
struct LoginPage {
  @State private loginMode: LoginMode = LoginMode.PHONE;
  @State private account: string = '';
  @State private password: string = '';
  @State private confirmPassword: string = '';
  @State private nickname: string = '';
  @State private isRegister: boolean = false;
  @State private isLogging: boolean = false;
  @State private errorMsg: string = '';

  private userService = UserService.getInstance();

  build() {
    Column() {
      Scroll() {
        Column({ space: 24 }) {
          // Logo区域
          Column({ space: 12 }) {
            Image($r('app.media.icon'))
              .width(72)
              .height(72)
              .objectFit(ImageFit.Contain)
            Text('掌上博物馆')
              .fontSize(26)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
            Text('沉浸式文物鉴赏与互动体验')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding({ top: 60 })
          .alignItems(HorizontalAlign.Center)

          // 登录/注册切换
          if (!this.isRegister) {
            // 登录方式切换
            Row({ space: 0 }) {
              ForEach(
                [LoginMode.PHONE, LoginMode.EMAIL], (mode: LoginMode) => {
                Text(mode === LoginMode.PHONE ? '手机号登录' : '邮箱登录')
                  .fontSize(14)
                  .fontColor(this.loginMode === mode ?
                    $r('app.color.primary') : $r('app.color.text_secondary'))
                  .fontWeight(this.loginMode === mode ?
                    FontWeight.Medium : FontWeight.Regular)
                  .padding({ bottom: 8 })
                  .onClick(() => {
                    this.loginMode = mode;
                  })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .borderWidth({ bottom: 1 })
            .borderColor({ bottom: $r('app.color.divider') })
          }

          // 输入表单
          Column({ space: 16 }) {
            // 账号输入
            Row() {
              Text(this.loginMode === LoginMode.PHONE ? '+86' : '✉')
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
              TextInput({
                placeholder: this.loginMode === LoginMode.PHONE ? '请输入手机号' : '请输入邮箱地址',
                text: this.account
              })
                .layoutWeight(1)
                .fontSize(15)
                .placeholderColor($r('app.color.text_hint'))
                .backgroundColor(Color.Transparent)
                .onChange((v) => { this.account = v; })
            }
            .padding(12)
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)

            // 昵称（注册时）
            if (this.isRegister) {
              Row() {
                Text('名')
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                TextInput({
                  placeholder: '请输入昵称',
                  text: this.nickname
                })
                  .layoutWeight(1)
                  .fontSize(15)
                  .placeholderColor($r('app.color.text_hint'))
                  .backgroundColor(Color.Transparent)
                  .onChange((v) => { this.nickname = v; })
              }
              .padding(12)
              .backgroundColor($r('app.color.background_card'))
              .borderRadius(12)
            }

            // 密码输入
            Row() {
              Text('🔒')
                .fontSize(16)
              TextInput({
                placeholder: '请输入密码',
                text: this.password
              })
                .layoutWeight(1)
                .fontSize(15)
                .placeholderColor($r('app.color.text_hint'))
                .backgroundColor(Color.Transparent)
                .type(InputType.Password)
                .onChange((v) => { this.password = v; })
            }
            .padding(12)
            .backgroundColor($r('app.color.background_card'))
            .borderRadius(12)

            // 确认密码（注册时）
            if (this.isRegister) {
              Row() {
                Text('🔒')
                  .fontSize(16)
                TextInput({
                  placeholder: '请再次输入密码',
                  text: this.confirmPassword
                })
                  .layoutWeight(1)
                  .fontSize(15)
                  .placeholderColor($r('app.color.text_hint'))
                  .backgroundColor(Color.Transparent)
                  .type(InputType.Password)
                  .onChange((v) => { this.confirmPassword = v; })
              }
              .padding(12)
              .backgroundColor($r('app.color.background_card'))
              .borderRadius(12)
            }
          }

          // 错误提示
          if (this.errorMsg.length > 0) {
            Text(this.errorMsg)
              .fontSize(13)
              .fontColor($r('app.color.error'))
              .width('100%')
          }

          // 登录/注册按钮
          Button() {
            Text(this.isRegister ? '注册' : '登录')
              .fontSize(17)
              .fontColor(Color.White)
          }
          .width('100%')
          .height(50)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(25)
          .opacity(this.isLogging ? 0.6 : 1.0)
          .enabled(!this.isLogging)
          .onClick(() => {
            this.handleAuth();
          })

          // 华为登录
          if (!this.isRegister) {
            Column({ space: 16 }) {
              Row() {
                Divider().width('30%').color($r('app.color.divider'))
                Text('或')
                  .fontSize(13)
                  .fontColor($r('app.color.text_hint'))
                  .margin({ left: 12, right: 12 })
                Divider().width('30%').color($r('app.color.divider'))
              }
              .width('100%')

              Button() {
                Row({ space: 8 }) {
                  Text('🔐')
                    .fontSize(22)
                  Text('华为账号一键登录')
                    .fontSize(15)
                    .fontColor($r('app.color.text_primary'))
                }
              }
              .width('100%')
              .height(50)
              .backgroundColor(Color.White)
              .borderRadius(25)
              .borderWidth(1)
              .borderColor($r('app.color.divider'))
              .onClick(async () => {
                this.isLogging = true;
                try {
                  const success = await this.userService.loginWithHuawei();
                  this.isLogging = false;
                  if (success) {
                    router.clear();
                    router.pushUrl({ url: 'pages/MainPage' });
                  }
                } catch (e) {
                  this.isLogging = false;
                  this.errorMsg = (e as Error).message;
                }
              })
            }
          }

          // 切换登录/注册
          Row() {
            Text(this.isRegister ? '已有账号？' : '还没有账号？')
              .fontSize(14)
              .fontColor($r('app.color.text_hint'))
            Text(this.isRegister ? '去登录' : '立即注册')
              .fontSize(14)
              .fontColor($r('app.color.primary'))
              .onClick(() => {
                this.isRegister = !this.isRegister;
                this.errorMsg = '';
              })
          }

          // 用户协议
          Text('登录即表示同意《用户协议》和《隐私政策》')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ bottom: 30 })
        }
        .padding({ left: 32, right: 32 })
      }
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private async handleAuth(): Promise<void> {
    if (this.account.length === 0 || this.password.length === 0) {
      this.errorMsg = '请填写完整信息';
      return;
    }
    if (this.isRegister && this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码输入不一致';
      return;
    }
    if (this.isRegister && this.nickname.length === 0) {
      this.errorMsg = '请填写昵称';
      return;
    }

    this.isLogging = true;
    this.errorMsg = '';

    let errMsg: string | null;
    if (this.isRegister) {
      errMsg = await this.userService.register(this.account, this.password, this.nickname);
    } else {
      errMsg = await this.userService.login(this.account, this.password);
    }

    this.isLogging = false;
    if (errMsg === null) {
      try {
        router.clear();
        router.pushUrl({ url: 'pages/MainPage' });
      } catch (e) {
        console.error('导航失败: ' + (e as Error).message);
      }
    } else {
      this.errorMsg = errMsg;
    }
  }
}

enum LoginMode {
  PHONE = 'phone',
  EMAIL = 'email'
}
