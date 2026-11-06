# Flashlight

A one-button torch toggle for OpenHarmony, written for
[Oniro](https://github.com/eclipse-oniro4openharmony) (`org.oniroproject.flashlight`).

It drives the public `CameraManager.setTorchMode` API, which needs no
permission. On Oniro's 7.0 images the prebuilt SceneBoard's Control Center
flashlight tile only mirrors the torch state (its tap never calls
`setTorchMode`), so this app is how the user switches the torch on devices
that have one, such as the Volla Phone Plinius.

* The torch stays on after the app is closed.
* The button follows `torchStatusChange`, so it also reflects changes made
  elsewhere.
* While the camera that owns the LED is open, the torch is unavailable.

## Build

API 20 (OpenHarmony 6.0+ SDK), Stage model, ArkTS.

```
ohpm install
hvigorw assembleHap --mode module -p module=entry@default -p product=default -p buildMode=release --no-daemon
```

Oniro images build and preinstall it from a pinned commit of this repository:
see `oniro-haps/oniro-haps.json` and `oniro-haps/build-oniro-haps.sh` in
[vendor_oniro](https://github.com/eclipse-oniro4openharmony/vendor_oniro).

## License

Apache-2.0, see [LICENSE](LICENSE).
