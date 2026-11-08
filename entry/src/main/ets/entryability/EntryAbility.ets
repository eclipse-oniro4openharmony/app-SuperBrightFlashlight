/*
 * Copyright (c) 2026 Eclipse Oniro for OpenHarmony contributors.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0F1A;
const TAG = 'Flashlight';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let win: window.Window;
    try {
      win = windowStage.getMainWindowSync();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'no main window: %{public}d', (e as BusinessError).code);
      return;
    }
    AppStorage.setOrCreate<window.Window>('mainWindow', win);

    // The page draws edge to edge (the screen light fills the whole panel)
    // and pads its controls by the system bar insets itself.
    win.setWindowLayoutFullScreen(true).catch((e: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'full-screen layout not set: %{public}d', e.code);
    });
    this.updateInsets(win);
    win.on('avoidAreaChange', () => this.updateInsets(win));

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content: %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy(): void {
    const win = AppStorage.get<window.Window>('mainWindow');
    try {
      win?.off('avoidAreaChange');
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'off(avoidAreaChange) failed');
    }
  }

  private updateInsets(win: window.Window): void {
    try {
      const density = display.getDefaultDisplaySync().densityPixels;
      const sys = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const nav = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const bottomPx = Math.max(sys.bottomRect.height, nav.bottomRect.height);
      // The screen light hides the bars together with its controls; keep the
      // insets of the visible bars so the controls come back where they were.
      if (sys.topRect.height > 0) {
        AppStorage.setOrCreate<number>('topInset', sys.topRect.height / density);
      }
      if (bottomPx > 0) {
        AppStorage.setOrCreate<number>('bottomInset', bottomPx / density);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'avoid areas unavailable');
    }
  }
}
