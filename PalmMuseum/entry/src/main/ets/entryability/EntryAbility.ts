import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    console.info('PalmMuseum EntryAbility onCreate');
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
}
