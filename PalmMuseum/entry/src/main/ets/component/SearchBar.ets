/**
 * 搜索栏组件
 *
 * showVoiceButton: 是否显示语音按钮（首页隐藏，搜索页显示）
 * onTap: 点击搜索栏时的回调（readOnly 模式下用于跳转搜索页）
 * onSearch: 回车提交搜索关键词
 */
import { SpeechService } from '../service/SpeechService';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';

@Component
export struct SearchBar {
  @State private searchText: string = '';
  @State private isListening: boolean = false;
  private placeholder: string = '搜索文物名称、朝代、关键字...';
  showVoiceButton: boolean = true;
  onSearch?: (keyword: string) => void;
  onTap?: () => void;

  private speechService = SpeechService.getInstance();

  build() {
    Row({ space: 8 }) {
      Text('🔍')
        .fontSize(17)
        .opacity(0.5)
        .margin({ left: 4 })

      TextInput({
        placeholder: this.isListening ? '🎙️ 正在聆听，再次点击结束...' : this.placeholder,
        text: this.searchText
      })
        .layoutWeight(1)
        .fontSize(14)
        .placeholderColor($r('app.color.text_hint'))
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .enabled(this.onTap === undefined) // 有 onTap 回调时不可编辑
        .onChange((value: string) => {
          this.searchText = value;
        })
        .onSubmit(() => {
          if (this.onSearch && this.searchText.trim().length > 0) {
            this.onSearch(this.searchText.trim());
          }
        })

      if (this.searchText.length > 0) {
        Text('✕')
          .fontSize(15)
          .fontColor($r('app.color.text_hint'))
          .width(28).height(28)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.divider_light'))
          .borderRadius(14)
          .onClick(() => { this.searchText = ''; })
      }

      // 语音按钮（可选）
      if (this.showVoiceButton) {
        Button() {
          Text(this.isListening ? '🔴' : '🎤')
            .fontSize(17)
        }
        .width(36).height(36)
        .backgroundColor(this.isListening ? $r('app.color.error') : $r('app.color.accent_light'))
        .borderRadius(18)
        .shadow({ radius: 4, color: $r('app.color.shadow'), offsetY: 1 })
        .onClick(() => { this.handleVoiceClick(); })
      }
    }
    .padding({ left: 14, right: 6, top: 1, bottom: 1 })
    .backgroundColor($r('app.color.search_bar_background'))
    .borderRadius(22)
    .height(46)
    .shadow({ radius: 3, color: $r('app.color.shadow'), offsetY: 1 })
    .onClick(() => {
      if (this.onTap) {
        this.onTap();
      }
    })
  }

  private async handleVoiceClick(): Promise<void> {
    if (this.isListening) {
      this.speechService.cancelListening();
      this.isListening = false;
      return;
    }

    const hasPermission = await this.checkMicPermission();
    if (!hasPermission) {
      promptAction.showToast({ message: '请先授予麦克风权限后再使用语音输入', duration: 2000 });
      return;
    }

    this.isListening = true;
    try {
      const result = await this.speechService.startListening();
      if (result && result.trim().length > 0) {
        this.searchText = result;
      } else {
        promptAction.showToast({ message: '未识别到语音，请重试或手动输入', duration: 2000 });
      }
    } catch (_) {
      promptAction.showToast({ message: '语音识别失败，请检查麦克风是否可用', duration: 2000 });
    }
    this.isListening = false;
  }

  private async checkMicPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;
      const permission: Permissions = 'ohos.permission.MICROPHONE';
      const grantStatus = atManager.checkAccessTokenSync(context.applicationInfo.accessTokenId, permission);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (_) {
      return false;
    }
  }
}
