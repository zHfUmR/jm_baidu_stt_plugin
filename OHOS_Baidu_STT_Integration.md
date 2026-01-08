# 鸿蒙端百度实时语音识别（ASR）集成说明（Flutter + OpenHarmony Stage）

#### 本文总结本项目在 **OpenHarmony（Stage）** 侧接入百度语音识别 SDK（`@bdbase/speech-asr` / HAR），并通过 **Flutter MethodChannel/EventChannel** 把能力桥接到 Dart 的完整流程。

> 项目环境参考6.1

> 适用场景：本仓库使用 `flutter_ohos`（Stage 工程在 `ohos/`），Flutter 侧通过 `MethodChannel` 调用原生侧能力。

---

## 1. 总体架构

```
Flutter(Dart)
  ├─ MethodChannel:  jm_baidu_stt_plugin
  ├─ EventChannel:   jm_baidu_stt_plugin/event
  └─ BaiduSttService (Dart 封装)
            │
            ▼
OpenHarmony(ArkTS)
  ├─ EntryAbility.ets 注册 MethodChannel/EventChannel
  └─ 调用 @bdbase/speech-asr (HAR) 的 SpeechEventManager
            │
            ▼
百度语音识别 SDK（OHOS）
```

---

## 2. 鸿蒙原生侧需要添加/修改哪些内容

### 2.1 添加 HAR（百度语音 SDK）

- 文件：`ohos/entry/libspeechasr.har`
- 依赖声明：`ohos/entry/oh-package.json5`

示例（关键行）：

```json5
"dependencies": {
  "@bdbase/speech-asr": "file:libspeechasr.har"
}
```

> 说明：此工程使用本地 HAR 方式接入（`file:`）。

### 2.2 添加 rawfile 资源（SDK 运行所需）

把以下文件放到：`ohos/entry/src/main/resources/rawfile/`

- `libvad.dnn.so`
- `libglobal.cmvn.so`
- `wakeup.pkg`（如果需要“唤醒”能力，必须放真实模型；仅 ASR 可以先不启用唤醒）

> 注意：如果 `wakeup.pkg` 是占位文件，唤醒功能不可用；ASR 可正常使用。

### 2.3 增加麦克风权限

在 `ohos/entry/src/main/module.json5` 的 `requestPermissions` 增加：

```json5
{
  "name": "ohos.permission.MICROPHONE",
  "reason": "$string:app_name",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

---

## 3. 鸿蒙原生侧桥接：EntryAbility.ets 做了什么

文件：`ohos/entry/src/main/ets/entryability/EntryAbility.ets`

### 3.1 注册通道

- `MethodChannel`：`jm_baidu_stt_plugin`
- `EventChannel`：`jm_baidu_stt_plugin/event`

注册位置在 `configureFlutterEngine(flutterEngine)`，与工程里既有的 `xdt_nfc` / `native_notification_channel` 一致。

对应代码关键点：

- `const BAIDU_STT_METHOD_CHANNEL_NAME = 'jm_baidu_stt_plugin'`
- `const BAIDU_STT_EVENT_CHANNEL_NAME = 'jm_baidu_stt_plugin/event'`
- `this.baiduSttMethodChannel = new MethodChannel(..., BAIDU_STT_METHOD_CHANNEL_NAME)`
- `this.baiduSttEventChannel = new EventChannel(..., BAIDU_STT_EVENT_CHANNEL_NAME)`

### 3.2 MethodChannel 协议（Dart 调用 → ArkTS 执行）

本项目沿用历史插件协议（便于复用已有 Dart 侧逻辑）：

| 方法名 | Dart 入参 | ArkTS 侧行为 |
|---|---|---|
| `create` | `Map<String, Object?>`：`{type, appId, appKey, appSecret}` | 缓存 ak/sk，调用 `SpeechEventManager.initSdk(...)` 完成初始化；本工程当前 **未使用** `appId`（保留字段，便于后续扩展） |
| `startRecognition` | `String? wakeUpWord` | 创建 `StartParamsAsr` 并调用 `SpeechEventManager.startAsr(...)`；本工程当前 **忽略** `wakeUpWord`（如需可映射到 `StartParamsAsr.wakeupWord`） |
| `stopRecognition` | 无 | `SpeechEventManager.stopAsr()` |
| `startMonitorWakeUp` | 无 | 创建 `StartParamsWakeup` 并调用 `SpeechEventManager.startWakeup(...)`（依赖真实 `wakeup.pkg`） |
| `stopMonitorWakeUp` | 无 | `SpeechEventManager.stopWakeup(null)` |

> 注：`type` 仅用于区分 asr/wakeup 的语义（0=asr, 1=wakeup），具体实现可按需扩展。

### 3.3 EventChannel 数据结构（ArkTS → Dart 回调）

EventChannel 推送一个 JSON（字符串或 Map），结构为：

```json
{ "status": "flushData|statusFinish|volumeChanged|statusError|statusTriggered", "data": "...", "type": "0|1" }
```

状态映射（示例）：

- `flushData`：中间识别结果（partial）
- `statusFinish`：最终识别结果（final）
- `volumeChanged`：音量变化（用于“是否说话”判断）
- `statusError`：识别失败
- `statusTriggered`：唤醒触发

### 3.4 调用百度 SDK（OHOS）

ArkTS 侧通过 `@bdbase/speech-asr` 的 `SpeechEventManager`：

- `SpeechEventManager.getInstance().initSdk(context, '', '')`
- `SpeechEventManager.getInstance().startAsr(startParams, listener, callback)`
- `SpeechEventManager.getInstance().stopAsr()`
- `SpeechEventManager.getInstance().startWakeup(startParams, listener, callback)`
- `SpeechEventManager.getInstance().stopWakeup(null)`

回调里根据 `SpeechAsrState.* / SpeechWakeupState.*` 转成上面的 `status/data/type` 后，通过 `EventChannel` 推送到 Dart。

当前工程的主要映射（节选）：

- `SpeechAsrState.ASR_PARTIAL` → `{status:'flushData', data: best_result, type:'0'}`
- `SpeechAsrState.ASR_FINAL` → `{status:'statusFinish', data: best_result, type:'0'}`
- `SpeechAsrState.ASR_AUDIO_VOLUME_LEVEL` → `{status:'volumeChanged', data: volumePercent, type:'0'}`
- `SpeechAsrState.ASR_ERROR` → `{status:'statusError', data: params, type:'0'}`
- `SpeechWakeupState.WAKEUP_TRIGGERED` → `{status:'statusTriggered', data: word, type:'1'}`

---

## 4. Flutter（Dart）侧需要做什么

### 4.1 Dart 侧桥接封装

文件：`lib/business/smart_bus/services/baidu_stt_service.dart`

该文件封装了：

- `MethodChannel('jm_baidu_stt_plugin')`
- `EventChannel('jm_baidu_stt_plugin/event')`

并提供：

- `BaiduSttService.create(...)`
- `BaiduSttService.startRecognition()` / `stopRecognition()`
- `BaiduSttService.startMonitorWakeUp()` / `stopMonitorWakeUp()`
- `BaiduSttService.events()`：统一监听事件流

对应的 MethodChannel 方法名（Dart → 原生）与 EntryAbility 保持一致：

- `create`
- `startRecognition`
- `stopRecognition`
- `startMonitorWakeUp`
- `stopMonitorWakeUp`

### 4.2 业务 UI 调用方式（示例）

1) 初始化（推荐在首次使用前）：

```dart
await BaiduSttService.create(
  type: 0,
  appId: 'xxx',
  appKey: 'ak',
  appSecret: 'sk',
);
```

2) 监听事件：

```dart
final sub = BaiduSttService.events().listen((e) {
  // e.status / e.data / e.type
});
```

3) 开始/停止识别：

```dart
await BaiduSttService.startRecognition();
await BaiduSttService.stopRecognition();
```

---

## 5. 本工程里“语音 UI”在哪

为了便于验证链路，本工程包含以下示例 UI：

- AI 项目风格的语音弹层：`lib/business/ai/widgets/ai_speech_assistant.dart`

---

## 6. 构建与运行（OHOS）

参考仓库 `AGENTS.md` 的 HarmonyOS build flow：

1) 生成 Flutter 产物：

```bash
flutter build ohos --debug --target=lib/main.dart
```

2) 进入 `ohos/` 构建 HAP：

```bash
npx hvigorw assembleHap -p product=default --mode debug
```

---

## 6.1 当前工程环境

以下为本工程当前使用/验证过的版本信息（以本机为准，供你在其他机器/CI 对齐环境时参考）：

### Flutter / Dart

- Flutter（OHOS 分支）：`3.27.5-ohos-1.0.1`
- Dart SDK：`3.6.2`（`dart --version`）
- `pubspec.yaml` 约束：`environment.sdk: ^3.4.0`

### OpenHarmony / DevEco / Hvigor

- DevEco SDK 路径示例：`hwsdk.dir=/Applications/DevEco-Studio.app/Contents/sdk`（来自 `ohos/local.properties`）
- 产品 target/compatible SDK：`5.0.1(13)`（来自 `ohos/build-profile.json5` 的 `products.default.*SdkVersion`）
- Node：`v25.2.1`（`node -v`）
- npm：`11.6.2`（`npm -v`）

---

## 6.2 OHOS 侧机器相关文件说明

以下文件通常包含机器路径（Flutter SDK / DevEco SDK）

- `ohos/local.properties`
- `ohos/package.json`（本工程使用本地 `flutter-hvigor-plugin` 路径，可能会是 `file:/.../flutter_tools/hvigor`）


---

## 7. 常见问题（Troubleshooting）

### 6.1 `MissingPluginException`

原因：OHOS 侧没有注册同名 `MethodChannel/EventChannel`。

检查：`EntryAbility.ets` 是否已在 `configureFlutterEngine` 注册：

- `jm_baidu_stt_plugin`
- `jm_baidu_stt_plugin/event`

### 6.2 没有识别结果 / 没有回调

常见原因：

- 未授予 `ohos.permission.MICROPHONE`
- `create(...)` 未调用（或 ak/sk 为空）
- rawfile 资源缺失导致底层初始化失败（尤其是 VAD 相关资源）

### 6.3 唤醒不可用

如果 `wakeup.pkg` 不是百度提供的真实唤醒模型文件，唤醒无法工作。

---

## 8. 文件清单（本项目涉及）

### OHOS

- `ohos/entry/libspeechasr.har`
- `ohos/entry/oh-package.json5`
- `ohos/entry/src/main/resources/rawfile/libvad.dnn.so`
- `ohos/entry/src/main/resources/rawfile/libglobal.cmvn.so`
- `ohos/entry/src/main/resources/rawfile/wakeup.pkg`
- `ohos/entry/src/main/module.json5`
- `ohos/entry/src/main/ets/entryability/EntryAbility.ets`

### Flutter / Dart

- `lib/business/smart_bus/services/baidu_stt_service.dart`

---
