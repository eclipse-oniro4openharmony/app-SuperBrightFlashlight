import { Size } from '@ohos/hypium'

@Entry
@Component
struct SecondPage {
  @State lightLevel: number = 0
  @State isOn: boolean = false
  @State tipsValue: string = ''

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
      Slider({
        value: this.lightLevel,
        step: 20,
        style: SliderStyle.InSet,
        direction: Axis.Vertical,
        reverse: true,
      })
        .showSteps(true)
        .onChange((value: number, mode: SliderChangeMode) => {
          this.lightLevel = value
          if (value == 0) {
            this.isOn = false
          } else {
            this.isOn = true
          }
          switch (value) {
            case 0:
              this.tipsValue = 'lv. 0'
              break;
            case 20:
              this.tipsValue = 'lv. 1'
              break;
            case 40:
              this.tipsValue = 'lv. 2'
              break;
            case 60:
              this.tipsValue = 'lv. 3'
              break;
            case 80:
              this.tipsValue = 'lv. 4'
              break;
            case 100:
              this.tipsValue = 'lv. 5'
              break;
            default:
              break;
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
        .showTips(true, this.tipsValue.toString())// .blockStyle({
          //   type: SliderBlockType.SHAPE,
          //   shape: new Rect({
          //     width: 50,
          //     height: 50,
          //   })
          // })
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
    .backgroundColor(this.isOn ? '#d2ddcccc' : '#97050505')
    .width('100%')
    .backgroundImage(this.isOn == false ? $r('app.media.light_off') : $r('app.media.light_on'))
    .backgroundImageSize(ImageSize.Contain)
    .backgroundImagePosition(Alignment.Center)

    // Row() {
    //   Toggle({
    //     type: ToggleType.Switch,
    //     isOn: false
    //   })//todo: link isOn with local variable
    //     //todo: implement the concrete login after board testing
    //     .onChange((isOn: boolean) => {
    //       if (isOn) {
    //         console.info('flash is on')
    //       }
    //       else {
    //         console.info('flash is off')
    //       }
    //     })
    //     .size({
    //       width:120,
    //       height:40
    //     })
    // }
    // .margin({
    //   top: '15%'
    // })
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