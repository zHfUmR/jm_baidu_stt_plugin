import 'jm_baidu_stt_plugin_platform_interface.dart';
import 'models/baidu_speech_types.dart';
import 'models/sdk_data_cache.dart';

export 'models/baidu_speech_types.dart';

class JmBaiduSttPlugin {
  static Stream<dynamic>? _onListener;

  /// 初始化 SDK 并监听原生回调
  static void initSDK({
    required String appId,
    required String appKey,
    required String appSecret,
    required Function(dynamic) onEvent,
  }) {
    final cache = SdkDataCache();
    cache.appId = appId;
    cache.appKey = appKey;
    cache.appSecret = appSecret;
    _onListener ??= JmBaiduSttPluginPlatform.instance.onChange();
    _onListener?.listen(onEvent);
  }

  /// 主动获取事件流，便于自行处理
  static Stream<dynamic>? onChange() {
    _onListener ??= JmBaiduSttPluginPlatform.instance.onChange();
    return _onListener;
  }

  /// 创建语音识别或唤醒实例
  static Future<void> create({required BaiduSpeechBuildType type}) {
    final cache = SdkDataCache();
    return JmBaiduSttPluginPlatform.instance.create(
      type: type,
      appId: cache.appId ?? '',
      appKey: cache.appKey ?? '',
      appSecret: cache.appSecret ?? '',
    );
  }

  /// 开始语音识别
  static Future<void> startRecognition({String? wakeUpWord}) {
    return JmBaiduSttPluginPlatform.instance.startRecognition(
      wakeUpWord: wakeUpWord,
    );
  }

  /// 结束语音识别
  static Future<void> stopRecognition() {
    return JmBaiduSttPluginPlatform.instance.stopRecognition();
  }

  /// 开始语音唤醒
  static Future<void> startMonitorWakeUp() {
    return JmBaiduSttPluginPlatform.instance.startMonitorWakeUp();
  }

  /// 结束语音唤醒
  static Future<void> stopMonitorWakeUp() {
    return JmBaiduSttPluginPlatform.instance.stopMonitorWakeUp();
  }
}
