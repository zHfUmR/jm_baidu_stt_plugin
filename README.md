# jm_baidu_stt_plugin

Flutter bindings for the latest Baidu Speech ASR & wake-up SDKs.

- **Android**: bdasr_V3_20250507_b610f20.jar + native libs (v3.4.5).
- **iOS**: ASR_iOS_v3.0.12.0.1285b57 static library & resources.
- **OpenHarmony / HarmonyOS (OHOS)**: this plugin does **not** ship an OHOS native implementation yet. See [OHOS_Baidu_STT_Integration.md](OHOS_Baidu_STT_Integration.md) for a reference integration flow to bridge Baidu real-time ASR to Flutter.

The plugin exposes a simple Dart API that mirrors the reference native demo so you can initialize the SDK, create recognizer/wake-up engines, and handle streaming status callbacks from Dart.

## OpenHarmony / HarmonyOS (OHOS)

This repository currently provides native implementations for **Android** and **iOS** only.

However, **Flutter real-time Baidu ASR can be adapted to OpenHarmony/HarmonyOS** by implementing the same channel contract on the OHOS (ArkTS/Stage) side:

- `MethodChannel('jm_baidu_stt_plugin')`
- `EventChannel('jm_baidu_stt_plugin/event')`

Reference guide (step-by-step): [OHOS_Baidu_STT_Integration.md](OHOS_Baidu_STT_Integration.md)

**中文说明：本插件因Flutter版本原因暂未提供鸿蒙端（OHOS/OpenHarmony）原生实现，但可以参考 [OHOS_Baidu_STT_Integration.md](OHOS_Baidu_STT_Integration.md) 的流程在你自己的 `ohos/` Stage 工程中完成 ArkTS 侧桥接；Flutter 侧复用相同的通道名/方法协议即可，因此“Flutter + 百度实时语音识别”是可以适配鸿蒙的。**

## Install

1) Add the dependency to your `pubspec.yaml`: `jm_baidu_stt_plugin: ^0.1.1`

2) Install packages: `flutter pub get`

3) For iOS, run CocoaPods from your host app’s `ios/` folder: `pod install`

## Docs

- [OHOS_Baidu_STT_Integration.md](OHOS_Baidu_STT_Integration.md): Reference guide for integrating Baidu real-time ASR on OpenHarmony/HarmonyOS (OHOS) and bridging it to Flutter via MethodChannel/EventChannel.

## iOS SDK delivery (recommended)

Baidu iOS SDK binaries/models are large. For publishing (Git / pub.dev), it is recommended not to commit them into the repository.

This plugin uses CocoaPods `prepare_command` to download missing artifacts during `pod install`.

If you installed the plugin from pub.dev, note that the large iOS SDK artifacts are typically excluded from the published package via `.pubignore`.

- By default, this plugin will try to download the required iOS artifacts from this repo’s GitHub Releases during `pod install`.
- If your network/CI cannot access GitHub, provide your own download URLs (or vendor the files locally).

### Usage

1) Provide download URLs via environment variables.

Option A (recommended): one zip containing both files

- `JM_BAIDU_STT_IOS_SDK_ZIP_URL` (the zip must contain `libBaiduSpeechSDK.a` and `bds_easr_input_model.dat` somewhere inside)

Option B: two direct file URLs

- `JM_BAIDU_STT_IOS_LIB_URL`
- `JM_BAIDU_STT_IOS_MODEL_URL`

2) Run CocoaPods: `pod install`

If your network requires a proxy, set it before running CocoaPods:

- `export https_proxy=http://127.0.0.1:7890`
- `export http_proxy=http://127.0.0.1:7890`

### Notes

- If the files already exist in `ios/Libs/...` and `ios/Assets/...`, download is skipped (offline friendly).
- To force re-download: `export JM_BAIDU_STT_IOS_FORCE_DOWNLOAD=1`
- To disable download and fail fast if missing: `export JM_BAIDU_STT_IOS_SKIP_DOWNLOAD=1`

### Tip: set URLs in `ios/Podfile` (CI/team friendly)

If you don’t want every developer/CI to export env vars manually, you can set them in your host app’s `ios/Podfile`:

- `ENV['JM_BAIDU_STT_IOS_SDK_ZIP_URL'] ||= '<YOUR_ZIP_URL>'`

Or (two direct URLs):

- `ENV['JM_BAIDU_STT_IOS_LIB_URL'] ||= '<YOUR_LIB_URL>'`
- `ENV['JM_BAIDU_STT_IOS_MODEL_URL'] ||= '<YOUR_MODEL_URL>'`


## Quick start

1) Initialize and subscribe to events: `JmBaiduSttPlugin.initSDK(...)` and provide an `onEvent` callback.

2) Create the ASR engine: `await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.asr)`

3) Start recognition: `await JmBaiduSttPlugin.startRecognition()`

Optional (some offline modes): `await JmBaiduSttPlugin.startRecognition(wakeUpWord: '...')`

4) Stop recognition: `await JmBaiduSttPlugin.stopRecognition()`

5) Wake-up:

- Create: `await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.wakeUp)`
- Start: `await JmBaiduSttPlugin.startMonitorWakeUp()`
- Stop: `await JmBaiduSttPlugin.stopMonitorWakeUp()`

### Event status values

| status             | meaning                         |
|--------------------|---------------------------------|
| `flushData`        | partial recognition result      |
| `statusFinish`     | final recognition result        |
| `volumeChanged`    | audio level update (0–100)      |
| `statusError`      | recognition/wake-up failure     |
| `statusTriggered`  | wake-up keyword detected        |

`type` in the payload is `0` for ASR and `1` for wake-up.

## iOS notes (important)

- **Simulator**: the Baidu static library in this project is `arm64` only (device slice). It usually cannot run on iOS Simulator.
- **Resource lookup**: iOS native code will try to locate `.dat` files from `mainBundle` / `bundleForClass` / common resource bundles, to be resilient under CocoaPods.

### iOS ASR defaults

The iOS implementation follows Baidu’s official sample defaults:

- Default `productId`: `1537`
- Default `language`: `EVoiceRecognitionLanguageChinese`
- Default `strategy`: `EVR_STRATEGY_ONLINE`

If you need parallel mode (online + offline), pass `strategy = EVR_STRATEGY_BOTH` and ensure the offline model/license files are available.

### ASR stability

iOS native layer includes guards for common issues:

- Rapid `stopRecognition()` → `startRecognition()` may cause `engine is busy`: the plugin will auto retry with backoff.
- STOP-induced HTTP timeout will be silently ignored when stopping.
- `NoSpeech/Short` will be treated as `statusFinish` with empty string.

### Advanced iOS parameters (optional)

The iOS implementation supports extra parameters on `create` (defaults are applied if not provided):

- `productId`: defaults to `1537`
- `language`: defaults to `EVoiceRecognitionLanguageChinese`
- `strategy`: defaults to `EVR_STRATEGY_ONLINE`
- `enableModelVAD`: defaults to `false`
- `offlineEngineType`: defaults to `EVR_OFFLINE_ENGINE_INPUT` (only used when `strategy == EVR_STRATEGY_BOTH`)
- `offlineDatPath`: defaults to bundled `bds_easr_input_model.dat` (only used when `strategy == EVR_STRATEGY_BOTH`)
- `serverUrl`: defaults to `https://vop.baidu.com/server_api`

Current Dart API does not expose these options yet; if you need them you can extend the plugin or invoke `MethodChannel('jm_baidu_stt_plugin').invokeMethod('create', ...)` yourself.

## permission_handler (microphone)

If you use `permission_handler` on iOS, make sure the microphone permission macro is enabled for the `permission_handler_apple` target in your host app’s `ios/Podfile` `post_install`.

Example lines to add (as recommended by the plugin):

- `if target.name == 'permission_handler_apple'`
- `  target.build_configurations.each do |config|`
- `    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_MICROPHONE=1']`
- `  end`
- `end`

## Android integration notes

- `minSdkVersion` is set to 24 to align with the new Baidu SDK artifacts.
- The plugin bundles the latest `bdasr_V3_20250507_b610f20.jar`, `WakeUp.bin`, and all native `.so` files (armeabi, armeabi-v7a, arm64-v8a, x86, x86_64).
- Required permissions are already declared in the embedded `AndroidManifest.xml`, but your host app must still request `RECORD_AUDIO` at runtime.
- If you shrink/obfuscate, keep the Baidu classes (e.g. add `-keep class com.baidu.speech.** { *; }` to `proguard-rules.pro`).

## iOS integration notes

- The plugin ships Baidu’s static library (`libBaiduSpeechSDK.a`), headers, wake-word models, and resource bundles from ASR_iOS_v3.0.12.0.
- Add the following to your app’s `Info.plist`:
  - `NSMicrophoneUsageDescription`
  - (Optional) `UIBackgroundModes` → `audio` if you record in background.
- Run `pod install` inside the Flutter app’s `ios/` folder after adding the plugin so CocoaPods pulls in the updated podspec.
- The plugin includes a Privacy Manifest (`Resources/PrivacyInfo.xcprivacy`). Update it if your host app has additional data uses.

## Example app

`example/lib/main.dart` contains a basic control panel showing how to:

1. Initialize the SDK with an event listener.
2. Create ASR and wake-up engines.
3. Start/stop recognition and wake-up monitoring while printing native callback payloads.

Replace the placeholder credentials before running on a device.

## License

See [LICENSE](LICENSE). The Baidu SDK binaries remain subject to Baidu’s own license terms; ensure you have permission to use them in production.
