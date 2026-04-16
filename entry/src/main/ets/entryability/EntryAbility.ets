import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[Browser] EntryAbility onCreate');
  }

  onDestroy(): void {
    console.info('[Browser] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('[Browser] EntryAbility onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('[Browser] Failed to load content: ' + JSON.stringify(err));
        return;
      }
      console.info('[Browser] Succeeded in loading content');
    });
  }

  onWindowStageDestroy(): void {
    console.info('[Browser] EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('[Browser] EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('[Browser] EntryAbility onBackground');
  }
}
