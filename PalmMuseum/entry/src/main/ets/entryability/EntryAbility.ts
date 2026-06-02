import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    console.info('PalmMuseum EntryAbility onCreate');
    // 请求麦克风权限（语音识别需要）
    this.requestMicrophonePermission();
  }

  onDestroy() {
    console.info('PalmMuseum EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    console.info('PalmMuseum EntryAbility onWindowStageCreate');
    windowStage.loadContent('pages/MainPage', (err, data) => {
      if (err.code) {
        console.error('Failed to load content, error: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in loading content, data: ' + JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    console.info('PalmMuseum EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    console.info('PalmMuseum EntryAbility onForeground');
  }

  onBackground() {
    console.info('PalmMuseum EntryAbility onBackground');
  }

  /**
   * 请求麦克风权限
   */
  private requestMicrophonePermission(): void {
    const atManager = abilityAccessCtrl.createAtManager();
    const permission: Permissions = 'ohos.permission.MICROPHONE';
    atManager.requestPermissionsFromUser(this.context, [permission])
      .then((data) => {
        if (data.authResults[0] === 0) {
          console.info('[EntryAbility] Microphone permission granted');
        } else {
          console.warn('[EntryAbility] Microphone permission denied');
        }
      })
      .catch((err: BusinessError) => {
        console.error(`[EntryAbility] Failed to request permission: ${err.message}`);
      });
  }
}
