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

import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Settings } from '../model/Settings';
import { Torch, TorchState } from '../model/Torch';

const DOMAIN = 0x0F1A;
const TAG = 'Flashlight';

const MODE_TORCH = 0;
const MODE_SCREEN = 1;

const KEY_MODE = 'mode';
const KEY_SCREEN_BRIGHTNESS = 'screenBrightness';
const KEY_COLOR = 'color';
const KEY_TORCH_LEVEL = 'torchLevel';

const MIN_SCREEN_BRIGHTNESS = 5;

// The icon's palette: night blue and lamp yellow.
const NIGHT_TOP = '#1E2A5A';
const NIGHT_BOTTOM = '#0A0F24';
const NIGHT_RAISED = '#2A3670';
const LAMP = '#FFD54F';
const ON_LAMP = '#14193A';
const TEXT = '#F2F3FA';
const TEXT_DIM = '#AEB4D6';

interface LightColor {
  value: string;
  label: Resource;
}

const LIGHT_COLORS: LightColor[] = [
  { value: '#FFFFFF', label: $r('app.string.color_white') },
  { value: '#FFE4BA', label: $r('app.string.color_warm') },
  { value: '#FFB300', label: $r('app.string.color_amber') },
  { value: '#FF3B30', label: $r('app.string.color_red') },
  { value: '#BBD7FF', label: $r('app.string.color_blue') }
];

/*
 * Two lights in one page: the camera flash LED ("Torch") and the panel itself
 * ("Screen"), for devices without a flash or when a softer light is wanted.
 *
 * The torch belongs to the camera service and stays on after the app closes.
 * The screen light is this window at the chosen colour and window brightness,
 * kept awake; both end when the window goes away, and the system brightness
 * is never touched.
 */
@Entry
@Component
struct Index {
  @State mode: number = MODE_TORCH;
  @State torchOn: boolean = false;
  @State torchAvailable: boolean = true;
  @State torchLevel: number = 100;
  @State screenBrightness: number = 100;
  @State colorIndex: number = 0;
  @State controlsVisible: boolean = true;
  @StorageProp('topInset') topInset: number = 0;
  @StorageProp('bottomInset') bottomInset: number = 0;
  private torch: Torch | undefined = undefined;
  private settings: Settings | undefined = undefined;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    this.settings = new Settings(context);
    this.torch = new Torch(context);
    this.torchOn = this.torch.isOn();
    this.torch.subscribe((state: TorchState) => {
      this.torchOn = state.on;
      this.torchAvailable = state.available;
    });

    this.torchLevel = this.clamp(this.settings.getNumber(KEY_TORCH_LEVEL, 100), 1, 100);
    this.screenBrightness = this.clamp(this.settings.getNumber(KEY_SCREEN_BRIGHTNESS, 100),
      MIN_SCREEN_BRIGHTNESS, 100);
    this.colorIndex = this.clamp(this.settings.getNumber(KEY_COLOR, 0), 0, LIGHT_COLORS.length - 1);
    // Without a flash the screen is the only light; otherwise the last one used.
    const saved = this.settings.getNumber(KEY_MODE, MODE_TORCH);
    this.mode = this.torchSupported() && saved !== MODE_SCREEN ? MODE_TORCH : MODE_SCREEN;
  }

  aboutToDisappear(): void {
    this.torch?.unsubscribe();
  }

  onPageShow(): void {
    // The torch may have changed while the app was in the background.
    if (this.torch !== undefined) {
      this.torchOn = this.torch.isOn();
    }
    this.controlsVisible = true;
    this.applyWindow();
  }

  private torchSupported(): boolean {
    return this.torch !== undefined && this.torch.supported;
  }

  private levelSupported(): boolean {
    return this.torch !== undefined && this.torch.levelSupported;
  }

  private clamp(v: number, lo: number, hi: number): number {
    return Math.min(hi, Math.max(lo, Math.round(v)));
  }

  private mainWindow(): window.Window | undefined {
    return AppStorage.get<window.Window>('mainWindow');
  }

  private setMode(mode: number): void {
    if (mode === this.mode) {
      return;
    }
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
      this.mode = mode;
      this.controlsVisible = true;
    });
    this.settings?.putNumber(KEY_MODE, mode);
    this.applyWindow();
  }

  /* Window brightness, keep-awake and system bars for the current mode. */
  private applyWindow(): void {
    const win = this.mainWindow();
    if (win === undefined) {
      return;
    }
    const screen = this.mode === MODE_SCREEN;
    const report = (what: string) => (e: BusinessError) => {
      hilog.warn(DOMAIN, TAG, '%{public}s failed: %{public}d', what, e.code);
    };
    // -1 hands the brightness back to the system.
    win.setWindowBrightness(screen ? this.screenBrightness / 100 : -1).catch(report('brightness'));
    win.setWindowKeepScreenOn(screen).catch(report('keepScreenOn'));
    this.applySystemBars(win);
  }

  private applySystemBars(win: window.Window): void {
    const screen = this.mode === MODE_SCREEN;
    const bars = !screen || this.controlsVisible;
    const report = (e: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'system bars failed: %{public}d', e.code);
    };
    try {
      win.setSpecificSystemBarEnabled('status', bars).catch(report);
      win.setSpecificSystemBarEnabled('navigationIndicator', bars).catch(report);
      const content = screen ? '#000000' : '#FFFFFF';
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: content,
        navigationBarContentColor: content
      }).catch(report);
    } catch (e) {
      report(e as BusinessError);
    }
  }

  private toggleTorch(): void {
    if (this.torch === undefined) {
      return;
    }
    const target = !this.torchOn;
    if (this.torch.set(target, this.torchLevel / 100)) {
      this.torchOn = target;
      this.torchAvailable = true;
    } else {
      this.torchAvailable = false;
    }
  }

  private setTorchLevel(level: number, done: boolean): void {
    this.torchLevel = this.clamp(level, 1, 100);
    if (this.torchOn) {
      this.torch?.set(true, this.torchLevel / 100);
    }
    if (done) {
      this.settings?.putNumber(KEY_TORCH_LEVEL, this.torchLevel);
    }
  }

  private setScreenBrightness(value: number, done: boolean): void {
    this.screenBrightness = this.clamp(value, MIN_SCREEN_BRIGHTNESS, 100);
    this.mainWindow()?.setWindowBrightness(this.screenBrightness / 100).catch((e: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'brightness failed: %{public}d', e.code);
    });
    if (done) {
      this.settings?.putNumber(KEY_SCREEN_BRIGHTNESS, this.screenBrightness);
    }
  }

  private setColor(index: number): void {
    this.getUIContext().animateTo({ duration: 200 }, () => {
      this.colorIndex = index;
    });
    this.settings?.putNumber(KEY_COLOR, index);
  }

  private toggleControls(): void {
    this.getUIContext().animateTo({ duration: 200 }, () => {
      this.controlsVisible = !this.controlsVisible;
    });
    const win = this.mainWindow();
    if (win !== undefined) {
      this.applySystemBars(win);
    }
  }

  private torchStatus(): Resource {
    if (!this.torchSupported()) {
      return $r('app.string.torch_unsupported');
    }
    if (!this.torchAvailable) {
      return $r('app.string.torch_busy');
    }
    return this.torchOn ? $r('app.string.torch_on') : $r('app.string.torch_off');
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.mode === MODE_SCREEN) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(LIGHT_COLORS[this.colorIndex].value)
          .onClick(() => this.toggleControls())
          .accessibilityText($r('app.string.hint_toggle_controls'))
          .id('screen_light')
      } else {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({ angle: 180, colors: [[NIGHT_TOP, 0], [NIGHT_BOTTOM, 1]] })
      }

      // Removed rather than made transparent while hidden, so that a tap
      // anywhere reaches the light and brings the controls back.
      if (this.mode === MODE_TORCH || this.controlsVisible) {
        Column() {
          this.ModeSwitch()
          if (this.mode === MODE_TORCH) {
            this.TorchPanel()
          } else {
            Blank()
              .hitTestBehavior(HitTestMode.None)
            this.ScreenPanel()
          }
        }
        .width('100%')
        .height('100%')
        .padding({ top: this.topInset + 16, bottom: this.bottomInset + 24, left: 20, right: 20 })
        .hitTestBehavior(HitTestMode.Transparent)
        .transition(TransitionEffect.OPACITY)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ModeSwitch() {
    Row() {
      this.ModeTab(MODE_TORCH, $r('sys.symbol.flashlight_on_fill'), $r('app.string.mode_torch'), 'mode_torch')
      this.ModeTab(MODE_SCREEN, $r('sys.symbol.lightbulb_max_fill'), $r('app.string.mode_screen'), 'mode_screen')
    }
    .padding(4)
    .borderRadius(26)
    .backgroundColor(this.mode === MODE_SCREEN ? '#B30A0F24' : '#33FFFFFF')
  }

  @Builder
  ModeTab(mode: number, icon: Resource, label: Resource, id: string) {
    Row({ space: 8 }) {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor([this.mode === mode ? ON_LAMP : TEXT])
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.mode === mode ? ON_LAMP : TEXT)
    }
    .height(44)
    .padding({ left: 20, right: 20 })
    .borderRadius(22)
    .backgroundColor(this.mode === mode ? LAMP : Color.Transparent)
    .onClick(() => this.setMode(mode))
    .id(id)
  }

  @Builder
  TorchPanel() {
    Column({ space: 12 }) {
      Stack() {
        // The lamp's glow behind the button.
        Column()
          .width(300)
          .height(300)
          .radialGradient({
            center: ['50%', '50%'],
            radius: 150,
            colors: [['#FFFFD54F', 0.6], ['#66FFB300', 0.72], ['#1AFFB300', 0.88], ['#00FFB300', 1]]
          })
          .opacity(this.torchOn ? 1 : 0)
          .animation({ duration: 300, curve: Curve.EaseOut })

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.torchOn ? $r('sys.symbol.flashlight_on_fill') : $r('sys.symbol.flashlight_off_fill'))
            .fontSize(84)
            .fontColor([this.torchOn ? ON_LAMP : TEXT])
        }
        .width(184)
        .height(184)
        .backgroundColor(this.torchOn ? LAMP : NIGHT_RAISED)
        .enabled(this.torchSupported())
        .opacity(this.torchSupported() ? 1 : 0.4)
        .animation({ duration: 200 })
        .onClick(() => this.toggleTorch())
        .accessibilityText(this.torchOn ? $r('app.string.a11y_torch_off') : $r('app.string.a11y_torch_on'))
        .id('torch_toggle')
      }
      .width(300)
      .height(300)

      Text(this.torchStatus())
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT)
        .textAlign(TextAlign.Center)
        .id('torch_status')

      if (this.levelSupported()) {
        BrightnessRow({
          value: this.torchLevel,
          min: 1,
          sliderId: 'torch_level',
          onValue: (v: number, done: boolean) => this.setTorchLevel(v, done)
        })
      }

      if (!this.torchSupported()) {
        Button($r('app.string.use_screen'))
          .fontSize(16)
          .fontColor(ON_LAMP)
          .backgroundColor(LAMP)
          .height(44)
          .padding({ left: 24, right: 24 })
          .onClick(() => this.setMode(MODE_SCREEN))
          .id('use_screen')
      } else if (!this.torchAvailable) {
        Text($r('app.string.torch_busy_hint'))
          .fontSize(14)
          .fontColor(TEXT_DIM)
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ScreenPanel() {
    Column({ space: 20 }) {
      BrightnessRow({
        value: this.screenBrightness,
        min: MIN_SCREEN_BRIGHTNESS,
        sliderId: 'screen_brightness',
        onValue: (v: number, done: boolean) => this.setScreenBrightness(v, done)
      })

      Row() {
        ForEach(LIGHT_COLORS, (c: LightColor, i: number) => {
          Stack() {
            Column()
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor(c.value)
          }
          .width(52)
          .height(52)
          .borderRadius(26)
          .border({ width: 3, color: i === this.colorIndex ? LAMP : Color.Transparent })
          .onClick(() => this.setColor(i))
          .accessibilityText(c.label)
          .id(`color_${i}`)
        }, (c: LightColor) => c.value)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text($r('app.string.hint_hide_controls'))
        .fontSize(13)
        .fontColor(TEXT_DIM)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 16 })
    .borderRadius(28)
    .backgroundColor('#D90A0F24')
  }
}

/* A brightness slider between a small and a large sun, with the percentage. */
@Component
struct BrightnessRow {
  @Prop value: number = 100;
  min: number = 1;
  sliderId: string = '';
  onValue: (v: number, done: boolean) => void = () => {
  };

  build() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.sun_min'))
        .fontSize(20)
        .fontColor([TEXT_DIM])
      Slider({ value: this.value, min: this.min, max: 100, step: 1, style: SliderStyle.OutSet })
        .layoutWeight(1)
        .trackThickness(6)
        .blockSize({ width: 26, height: 26 })
        .selectedColor(LAMP)
        .trackColor('#4DFFFFFF')
        .blockColor(Color.White)
        .onChange((v: number, mode: SliderChangeMode) => this.onValue(v, mode === SliderChangeMode.End))
        .accessibilityText($r('app.string.a11y_brightness'))
        .id(this.sliderId)
      SymbolGlyph($r('sys.symbol.sun_max'))
        .fontSize(24)
        .fontColor([TEXT])
      Text(`${this.value}%`)
        .width(48)
        .fontSize(15)
        .fontColor(TEXT)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }
}
