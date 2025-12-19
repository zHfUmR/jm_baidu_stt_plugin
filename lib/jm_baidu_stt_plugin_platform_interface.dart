import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'jm_baidu_stt_plugin_method_channel.dart';
import 'models/baidu_speech_types.dart';

abstract class JmBaiduSttPluginPlatform extends PlatformInterface {
  /// Constructs a JmBaiduSttPluginPlatform.
  JmBaiduSttPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static JmBaiduSttPluginPlatform _instance = MethodChannelJmBaiduSttPlugin();

  /// The default instance of [JmBaiduSttPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelJmBaiduSttPlugin].
  static JmBaiduSttPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JmBaiduSttPluginPlatform] when
  /// they register themselves.
  static set instance(JmBaiduSttPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Stream<dynamic>? onChange() {
    throw UnimplementedError('onChange() has not been implemented.');
  }

  Future<void> create({
    required BaiduSpeechBuildType type,
    required String appId,
    required String appKey,
    required String appSecret,
  }) {
    throw UnimplementedError('create() has not been implemented.');
  }

  Future<void> startRecognition({String? wakeUpWord}) {
    throw UnimplementedError('startRecognition() has not been implemented.');
  }

  Future<void> stopRecognition() {
    throw UnimplementedError('stopRecognition() has not been implemented.');
  }

  Future<void> startMonitorWakeUp() {
    throw UnimplementedError('startMonitorWakeUp() has not been implemented.');
  }

  Future<void> stopMonitorWakeUp() {
    throw UnimplementedError('stopMonitorWakeUp() has not been implemented.');
  }
}
