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

import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0F1A;
const TAG = 'Torch';

export interface TorchState {
  on: boolean;
  available: boolean;
}

export type TorchListener = (state: TorchState) => void;

/*
 * The camera flash LED, through the camera service's torch API, which needs
 * no permission. The service owns the state: it reports changes made from
 * anywhere (another app, the Control Center) and turns the torch off when an
 * app opens the camera that carries the LED, so callers follow the listener
 * instead of assuming their own last request.
 */
export class Torch {
  readonly supported: boolean;
  private manager: camera.CameraManager | undefined = undefined;
  private listener: TorchListener | undefined = undefined;
  private onStatus = (err: BusinessError, info: camera.TorchStatusInfo): void => {
    if (err !== undefined && err !== null && err.code !== 0) {
      hilog.error(DOMAIN, TAG, 'torchStatusChange error %{public}d', err.code);
      return;
    }
    this.listener?.({ on: info.isTorchActive, available: info.isTorchAvailable });
  };

  constructor(context: common.Context) {
    let supported = false;
    try {
      this.manager = camera.getCameraManager(context);
      supported = this.manager.isTorchSupported() &&
        this.manager.isTorchModeSupported(camera.TorchMode.ON);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, 'camera manager unavailable: %{public}d %{public}s', err.code, err.message);
    }
    this.supported = supported;
  }

  isOn(): boolean {
    try {
      return this.supported && this.manager !== undefined &&
        this.manager.getTorchMode() === camera.TorchMode.ON;
    } catch (e) {
      return false;
    }
  }

  subscribe(listener: TorchListener): void {
    this.listener = listener;
    try {
      this.manager?.on('torchStatusChange', this.onStatus);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'on(torchStatusChange) failed');
    }
  }

  unsubscribe(): void {
    this.listener = undefined;
    try {
      this.manager?.off('torchStatusChange', this.onStatus);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'off(torchStatusChange) failed');
    }
  }

  /*
   * Switches the torch. Returns false when the service refused, which in
   * practice means the camera that owns the LED is in use.
   */
  set(on: boolean): boolean {
    if (this.manager === undefined || !this.supported) {
      return false;
    }
    try {
      this.manager.setTorchMode(on ? camera.TorchMode.ON : camera.TorchMode.OFF);
      return true;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, 'set(%{public}d) failed: %{public}d %{public}s', on ? 1 : 0, err.code, err.message);
      return false;
    }
  }
}
