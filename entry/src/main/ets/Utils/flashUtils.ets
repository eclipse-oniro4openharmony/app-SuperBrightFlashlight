import camera from '@ohos.multimedia.camera';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

// Get camera manager instance
export function getCameraManager(context: common.BaseContext): camera.CameraManager | undefined {
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
export function isTorchSupported(cameraManager: camera.CameraManager): boolean {
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
export function isTorchModeSupported(cameraManager: camera.CameraManager, torchMode: camera.TorchMode): boolean {
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
export function getTorchMode(cameraManager: camera.CameraManager): camera.TorchMode | undefined {
  let torchMode: camera.TorchMode | undefined = undefined;
  torchMode = cameraManager.getTorchMode();
  return torchMode;
}

//设置设备手电筒模式
export function setTorchMode(cameraManager: camera.CameraManager, torchMode: camera.TorchMode): void {
  try {
    cameraManager.setTorchMode(torchMode);
    console.info('The setTorchMode call working')
  } catch (error) {
    // 失败返回错误码error.code并处理
    let err = error as BusinessError;
    console.error(`The setTorchMode call failed. error code: ${err.code}`);
  }
}
