import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      
      // 配置窗口实现沉浸式显示，保留状态栏
      try {
        const windowClass = windowStage.getMainWindowSync();
        // 设置窗口布局为全屏，延伸到系统状态栏和导航栏区域
        windowClass.setWindowLayoutFullScreen(true);
        // 启用状态栏和导航栏
        windowClass.setWindowSystemBarEnable(['status', 'navigation']);
        // 设置状态栏和导航栏为透明
        windowClass.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          statusBarContentColor: '#F6FBFF',
          navigationBarColor: '#00000000',
          navigationBarContentColor: '#F6FBFF'
        });
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting immersive mode.');
      } catch (windowErr) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set window properties. Cause: %{public}s', JSON.stringify(windowErr));
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}