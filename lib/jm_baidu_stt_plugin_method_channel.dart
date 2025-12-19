import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jm_baidu_stt_plugin_platform_interface.dart';
import 'models/baidu_speech_types.dart';

/// An implementation of [JmBaiduSttPluginPlatform] that uses method channels.
class MethodChannelJmBaiduSttPlugin extends JmBaiduSttPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('jm_baidu_stt_plugin');
  final EventChannel _eventChannel = const EventChannel('jm_baidu_stt_plugin/event');
  Stream<dynamic>? _listener;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<dynamic>? onChange() {
    _listener ??= _eventChannel.receiveBroadcastStream();
    return _listener;
  }

  @override
  Future<void> create({
    required BaiduSpeechBuildType type,
    required String appId,
    required String appKey,
    required String appSecret,
  }) {
    return methodChannel.invokeMethod(
      'create',
      {
        'type': type.index,
        'appId': appId,
        'appKey': appKey,
        'appSecret': appSecret,
      },
    );
  }

  @override
  Future<void> startRecognition({String? wakeUpWord}) {
    return methodChannel.invokeMethod('startRecognition', wakeUpWord);
  }

  @override
  Future<void> stopRecognition() {
    return methodChannel.invokeMethod('stopRecognition');
  }

  @override
  Future<void> startMonitorWakeUp() {
    return methodChannel.invokeMethod('startMonitorWakeUp');
  }

  @override
  Future<void> stopMonitorWakeUp() {
    return methodChannel.invokeMethod('stopMonitorWakeUp');
  }
}
