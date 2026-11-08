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

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0F1A;
const TAG = 'Settings';

/* The user's last choices, kept across launches. Failures only log. */
export class Settings {
  private prefs: preferences.Preferences | undefined = undefined;

  constructor(context: common.Context) {
    try {
      this.prefs = preferences.getPreferencesSync(context, { name: 'settings' });
    } catch (e) {
      const err = e as BusinessError;
      hilog.warn(DOMAIN, TAG, 'preferences unavailable: %{public}d', err.code);
    }
  }

  getNumber(key: string, fallback: number): number {
    try {
      const v = this.prefs?.getSync(key, fallback);
      return typeof v === 'number' ? v : fallback;
    } catch (e) {
      return fallback;
    }
  }

  putNumber(key: string, value: number): void {
    try {
      this.prefs?.putSync(key, value);
      this.prefs?.flush().catch((err: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'flush failed: %{public}d', err.code);
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'put %{public}s failed', key);
    }
  }
}
