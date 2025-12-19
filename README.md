# jm_baidu_stt_plugin

Flutter bindings for the latest Baidu Speech ASR & wake-up SDKs.

- **Android**: bdasr_V3_20250507_b610f20.jar + native libs (v3.4.5).
- **iOS**: ASR_iOS_v3.0.12.0.1285b57 static library & resources.

The plugin exposes a simple Dart API that mirrors the reference native demo so you can initialize the SDK, create recognizer/wake-up engines, and handle streaming status callbacks from Dart.

~~### Note: Because the Baidu SDK is too large, this plugin package does not include the binary libraries. Please download libBaiduSpeechSDK.a and bds_easr_input_model.dat from the GitHub Release and manually place them in the corresponding directories of your project. ###~~
~~### 注意：由于百度 SDK 体积过大，本插件包不含二进制库。请从 GitHub Release 下载 libBaiduSpeechSDK.a 和 bds_easr_input_model.dat，并手动放入项目的对应目录中。 ###~~
#### - Now you can directly use `pod install` to download the relevant files. ####
#### - 现在直接使用pod install 就可以直接下载相关文件 ####
##### export https_proxy=http://127.0.0.1:7890 #####
##### export http_proxy=http://127.0.0.1:7890 #####
##### pod install #####


## Quick start

```dart
JmBaiduSttPlugin.initSDK(
  appId: '<BAIDU_APP_ID>',
  appKey: '<BAIDU_APP_KEY>',
  appSecret: '<BAIDU_APP_SECRET>',
  onEvent: (dynamic event) {
    debugPrint('status=${event['status']} data=${event['data']}');
  },
);

await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.asr);
await JmBaiduSttPlugin.startRecognition();
await JmBaiduSttPlugin.stopRecognition();

await JmBaiduSttPlugin.create(type: BaiduSpeechBuildType.wakeUp);
await JmBaiduSttPlugin.startMonitorWakeUp();
await JmBaiduSttPlugin.stopMonitorWakeUp();
```

### Event status values

| status             | meaning                         |
|--------------------|---------------------------------|
| `flushData`        | partial recognition result      |
| `statusFinish`     | final recognition result        |
| `volumeChanged`    | audio level update (0–100)      |
| `statusError`      | recognition/wake-up failure     |
| `statusTriggered`  | wake-up keyword detected        |

`type` in the payload is `0` for ASR and `1` for wake-up.

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
