## 0.0.8
* **Fix (iOS)**: 优化资源引用逻辑，解决 `Multiple commands produce` 构建错误。
    - 将 `s.resources` 由递归引用改为精确引用，避免 `.bundle` 内部资源重复拷贝。
* **Fix (iOS)**: 解决 `VAD start: start error` 问题。
    - 完善自动化下载脚本，确保本地开发环境下 `.dat` 模型文件与 `.a` 静态库能正确补全。
* **Important (Permissions)**: 强化麦克风权限配置。
    - 更新 `Info.plist` 的 `NSMicrophoneUsageDescription` 说明。
    - **注意**：使用 `permission_handler` 时，必须在 `ios/Podfile` 的 `post_install` 节点中开启 `PERMISSION_MICROPHONE=1` 宏：
      ```ruby
      if target.name == 'permission_handler_apple'
        target.build_configurations.each do |config|
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_MICROPHONE=1']
        end
      end
      ```

## 0.0.7
* **Style**: 执行 `dart format` 并同步各配置文件版本号。

## 0.0.6
* **Fix**: 同步 `.podspec` 版本号与 `pubspec.yaml` 版本号以解决 iOS 安装失败问题。

## 0.0.5
* **Chore**: 从 Git 历史中清理大型二进制文件，实现仓库轻量化。

## 0.0.4
* **Fix**: 完成二进制分发（GitHub Release 托管）的最终配置。

## 0.0.3
* **Fix**: 优化发布包结构，适配 `pub.dev` 的 100MB 上传限制。

## 0.0.2
* **Feat**: 增加语音识别初始化、开始、停止等 Dart API 接口及事件流。
* **Build**: 集成最新的原生 SDK 库与资源文件，更新 Android/iOS 构建配置。

## 0.0.1
* **Init**: 首次集成百度语音 ASR/唤醒 SDK (Android v3.4.5, iOS v3.0.12)。