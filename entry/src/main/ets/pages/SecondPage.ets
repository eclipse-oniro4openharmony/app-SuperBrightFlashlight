import { Size } from '@ohos/hypium'

@Entry
@Component
struct SecondPage {
  @State outSetValueOne: number = 40
  @State inSetValueOne: number = 40
  @State outSetValueTwo: number = 40
  @State inSetValueTwo: number = 40
  @State vOutSetValueOne: number = 40
  @State vInSetValueOne: number = 40
  @State vOutSetValueTwo: number = 40
  @State vInSetValueTwo: number = 0
  @State isOn: boolean = false

  build() {
    Column() {
      Slider({
        value: this.vInSetValueTwo,
        step: 20,
        style: SliderStyle.InSet,
        direction: Axis.Vertical,
        reverse: true
      })
        .showSteps(true)
        .onChange((value: number, mode: SliderChangeMode) => {
          this.vInSetValueTwo = value
          if (value == 0) {
            this.isOn = false
          }
          else {
            this.isOn = true
          }
          console.info('value:' + value + 'mode:' + mode.toString())
        })
        .height('80%')
        .position({
          x: '80%',
          y: '10%'
        })
        .trackThickness(40)
    }
    .alignItems(HorizontalAlign.End)
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Gray)
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