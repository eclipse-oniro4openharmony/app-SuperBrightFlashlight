import { getCameraManager, isTorchSupported, isTorchModeSupported, getTorchMode, setTorchMode } from '../Utils/flashUtils'
import camera from '@ohos.multimedia.camera';
import { BusinessError } from '@ohos.base';
@Entry
@Component
struct lightPage {
  @State lightLevel: number = 0
  @State isOn: boolean = false
  private cameraManager: camera.CameraManager = getCameraManager(getContext(this)) as camera.CameraManager
  private torchMode: camera.TorchMode = getTorchMode(this.cameraManager) as camera.TorchMode

  @Builder
  DividerComponent() {
    Column() {
      Divider()
        .dividerStyle('30%')
      Divider()
        .dividerStyle('11%')
      Divider()
        .dividerStyle('10%')
      Divider()
        .dividerStyle('11%')
      Divider()
        .dividerStyle('10.5%')
    }
    .alignItems(HorizontalAlign.End)
    .width('100%')
    .height('100%')
    .zIndex(0)
  }

  build() {
    Stack() {

      if (this.lightLevel <= 20 && this.lightLevel > 0) {
        Image($r('app.media.lv1'))
          .imageStyle()
      } else if (this.lightLevel <= 40 && this.lightLevel > 20) {
        Image($r('app.media.lv2'))
          .imageStyle()
      } else if (this.lightLevel <= 60 && this.lightLevel > 40) {
        Image($r('app.media.lv3'))
          .imageStyle()
      } else if (this.lightLevel <= 80 && this.lightLevel > 60) {
        Image($r('app.media.lv4'))
          .imageStyle()
      } else if (this.lightLevel <= 100 && this.lightLevel > 80) {
        Image($r('app.media.lv5'))
          .imageStyle()
      }

      Slider({
        value: this.lightLevel,
        // step: 20,
        style: SliderStyle.InSet,
        direction: Axis.Vertical,
        reverse: true,
      })
        .showSteps(false)
        .onChange((value: number, mode: SliderChangeMode) => {
          this.lightLevel = value
          //console.info('value:' + value + 'mode:' + mode.toString())
          if (value == 0) {
            this.isOn = false
            setTorchMode(this.cameraManager, camera.TorchMode.OFF)
          } else {
            if (isTorchSupported(this.cameraManager)) {
              console.info('flashLight can be used!')
            }
            else {
              console.info('current device not support flashLight!')
            }
            if (isTorchModeSupported(this.cameraManager, this.torchMode)) {
              console.info('torch mode can be used!')

              setTorchMode(this.cameraManager, camera.TorchMode.ON)
            }
            else {
              console.info('current device not support torch mode!')
            }
            this.isOn = true
          }
        })
        .height('80%')
        .position({
          x: '72%',
          y: '10%'
        })
        .margin({
          left: 10,
        })
        .stepSize(20)// .stepColor('#bc646363')
        .trackThickness(80)
        .trackBorderRadius(10)
        .trackColor('#2d1b2124')
        .selectedColor('#ffffffff')
        .blockColor('#79e7dede')
        .zIndex(1)
      //this.DividerComponent()
      if (this.isOn == true) {
        Button('OFF')
          .position({
            x: '77%',
            y: '83%'
          })
          .onClick(() => {
            this.lightLevel = 0
            this.isOn = false
          })
          .buttonStyle(ButtonStyleMode.NORMAL)
          .type(ButtonType.Normal)
          .fontColor(Color.Red)
          .borderRadius(10)
          .zIndex(2)
      }
    }
    //.alignItems(HorizontalAlign.End)
    .height('100%')
    .backgroundColor(!this.isOn ? '#ff4e4a4a' :
      (this.lightLevel >= 20 && this.lightLevel < 40 ? '#d2b8a7a7' :
        (
          this.lightLevel >= 40 && this.lightLevel < 60 ? '#d2ddcccc' :
            (
              this.lightLevel >= 60 && this.lightLevel < 80 ? '#bed2d0d0' :
                (
                  this.lightLevel >= 80 && this.lightLevel <= 100 ? '#d5faf4f4' : '#97050505'
                )
            )
        )
      )
    )
    .width('100%')
    .backgroundImage(this.isOn == false ? $r('app.media.light_off') : $r('app.media.light_on'))
    .backgroundImageSize({
      width:50,
    })
    .backgroundImagePosition({
      x: '43%',
      y: '80%'
    })
    .alignContent(Alignment.Top)
  }
}

@Extend(Text)
function tabTitleStyle(color: ResourceColor) {
  .fontSize(10)
  .fontWeight(FontWeight.Medium)
  .margin({ bottom: 2 })
  .fontColor(color)
}

@Extend(Button)
function myButtonStyle(color: ResourceColor) {
  .backgroundColor(color)
}

@Extend(Divider)
function dividerStyle(length?: Length) {
  .strokeWidth(2)
  .margin({
    bottom: '20%',
    right: '6.2%',
    top: length,
  })
  .color('#6b6b6b')
  .width('13.9%')
}

@Extend(Image)
function imageStyle() {
  .width('90%')
  .height('70%')
  .margin({
    left: '5%'
  })
}