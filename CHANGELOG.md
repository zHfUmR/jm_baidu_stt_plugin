## 0.1.0
- HarmonyOS (OHOS) Support: Add comprehensive integration guidance for OpenHarmony/HarmonyOS Next.
- Architectural Standardization: Define explicit MethodChannel and EventChannel contracts to enable manual ArkTS bridging in ohos/ Stage projects without modifying Flutter business logic.
- Docs: Add OHOS_Baidu_STT_Integration.md providing step-by-step instructions for implementing the Baidu ASR interface on HarmonyOS.
- Ecosystem: Position the plugin for full-scenario support (Android, iOS, and HarmonyOS) by standardizing platform communication protocols.

## 0.0.9

- iOS: Align ASR configuration with Baidu's official iOS sample (adds BDS_ASR_PRODUCT_ID and BDS_ASR_LANGUAGE, sets default strategy to online).
- iOS: Make recognition text delivery more robust (adds fallback parsing and always emits statusFinish, even when the SDK returns an empty/unknown result format).
- iOS: Reset selected per-session parameters before each start (long speech, cache audio, wakeup word) to avoid stale state.
- iOS: Improve stability for rapid start/stop (busy backoff + retry).
- iOS: Ensure PrivacyInfo.xcprivacy is included as a pod resource.

Notes:

- If you need parallel mode (online + offline), pass strategy = EVR_STRATEGY_BOTH and make sure offline model/license files are available.
- permission_handler microphone macro guidance has been moved to README.md.

## 0.0.8

- iOS: Fix CocoaPods resource packaging to avoid Xcode "Multiple commands produce" caused by flattening bundle resources.
- iOS: Improve iOS artifact download logic to prevent missing .a / .dat files in local dev.
- iOS: Update microphone usage description guidance.

## 0.0.7

- Style: Run dart format and sync versions across configuration files.

## 0.0.6

- Fix: Sync .podspec version with pubspec.yaml to avoid iOS install issues.

## 0.0.5

- Chore: Remove large binaries from Git history to keep the repository lightweight.

## 0.0.4

- Fix: Finalize binary distribution via GitHub Releases.

## 0.0.3

- Fix: Optimize package structure to meet pub.dev size limits.

## 0.0.2

- Feature: Add Dart APIs for init/start/stop and an event stream.
- Build: Bundle the latest native SDK libraries/resources and update Android/iOS build configuration.

## 0.0.1

- Initial release: Baidu Speech ASR/wake-up SDK integration (Android v3.4.5, iOS v3.0.12).