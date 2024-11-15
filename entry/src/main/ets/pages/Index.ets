import camera from '@ohos.multimedia.camera';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import UIAbility from '@ohos.app.ability.UIAbility';


// Get camera manager instance
function getCameraManager(context: common.BaseContext): camera.CameraManager | undefined {
  let cameraManager: camera.CameraManager | undefined = undefined;
  try {
    cameraManager = camera.getCameraManager(context);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`The getCameraManager call failed. error code: ${err.code}`);
  }
  return cameraManager;
}

//Check if current device can use flashlight
function isTorchSupported(cameraManager: camera.CameraManager): boolean {
  let torchSupport: boolean = false;
  try {
    torchSupport = cameraManager.isTorchSupported();
  } catch (error) {
    let err = error as BusinessError;
    console.error('Failed to torch. errorCode = ' + err.code);
  }
  console.info('Returned with the torch support status:' + torchSupport);
  return torchSupport;
}

//Check if support device can use flashlight
function isTorchModeSupported(cameraManager: camera.CameraManager, torchMode: camera.TorchMode): boolean {
  let isTorchModeSupport: boolean = false;
  try {
    isTorchModeSupport = cameraManager.isTorchModeSupported(torchMode);
  } catch (error) {
    let err = error as BusinessError;
    console.error('Failed to set the torch mode. errorCode = ' + err.code);
  }
  return isTorchModeSupport;
}

//get current Torch mode
function getTorchMode(cameraManager: camera.CameraManager): camera.TorchMode | undefined {
  let torchMode: camera.TorchMode | undefined = undefined;
  torchMode = cameraManager.getTorchMode();
  return torchMode;
}

//设置设备手电筒模式
function setTorchMode(cameraManager: camera.CameraManager, torchMode: camera.TorchMode): void {
  try {
    cameraManager.setTorchMode(torchMode);
    console.info('The setTorchMode call working')
  } catch (error) {
    // 失败返回错误码error.code并处理
    let err = error as BusinessError;
    console.error(`The setTorchMode call failed. error code: ${err.code}`);
  }
}


@Entry
@Component
struct Index {
  //Initialize cameraManager
  private cameraManager: camera.CameraManager = getCameraManager(getContext(this)) as camera.CameraManager
  //Camera torch mode instance
  private torchMode: camera.TorchMode = getTorchMode(this.cameraManager) as camera.TorchMode
  private torchInfo: camera.TorchStatusInfo | null = null
  @State torchAvailability: boolean = false
  @State torchActive: boolean = false
  @State torchLevel: number = 0

  //手电筒状态变化回调，通过注册回调函数获取手电筒状态变化。
  // 在界面出现的时候调用函数来监听cameraManager的状态
  aboutToAppear(): void {
    this.registerTorchStatusChange
  }

  registerTorchStatusChange(cameraManager: camera.CameraManager): void {
    cameraManager.on('torchStatusChange', (err: BusinessError, torchStatusInfo: camera.TorchStatusInfo) => {
      console.info(`onTorchStatusChange, isTorchAvailable: ${torchStatusInfo.isTorchAvailable}, isTorchActive: ${torchStatusInfo.isTorchActive}, level: ${torchStatusInfo.torchLevel}`);
      this.torchAvailability = torchStatusInfo.isTorchAvailable
      this.torchActive = torchStatusInfo.isTorchActive
      this.torchLevel = torchStatusInfo.torchLevel
    });
  }

  // 设置设备手电筒亮度
  setTorchLevel(torchInfo: camera.TorchStatusInfo): void {
    try {
      this.torchLevel = torchInfo.torchLevel
      console.info('The lightness setting working')
    } catch (error) {
      // 失败返回错误码error.code并处理
      let err = error as BusinessError;
      console.error(`The set lightness call failed. error code: ${err.code}`);
    }
  }

  build() {
    Column() {
      Button('Turn on flashlight')
        .onClick(() => {
          //todo: Check if current device support flashlight
          if (isTorchSupported(this.cameraManager)) {
            console.info('flashLight can be used!')
          }
          else {
            console.info('current device not support flashLight!')
          }
          //todo: Check if current device support flashlight mode
          if (isTorchModeSupported(this.cameraManager, this.torchMode)) {
            console.info('torch mode can be used!')

            //todo: if torchmode is working, set the mode(Turn on the light)
            setTorchMode(this.cameraManager, camera.TorchMode.ON)
          }
          else {
            console.info('current device not support torch mode!')
          }
        })

      Button('Turn off flashlight')
        .onClick(() => {
          //todo: Check if current device support flashlight
          if (isTorchSupported(this.cameraManager)) {
          }
          else {
          }
          if (isTorchModeSupported(this.cameraManager, this.torchMode)) {
            // turn off the light when the torch mode is active
            setTorchMode(this.cameraManager, camera.TorchMode.OFF)
          }
          else {
          }
        })

      Text(`            FlashLight Availability: ${this.torchAvailability}
            FlashLight Active: ${this.torchActive}
            FlashLight Level: ${this.torchLevel}
`)
    }
  }
}